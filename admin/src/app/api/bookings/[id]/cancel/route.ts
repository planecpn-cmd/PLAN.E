import { withAdmin } from "@/lib/with-admin.server";

// Cancel a booking. payments:act (a cancellation usually pairs with a refund
// decision; there is no separate bookings:act scope). Named action + mandatory
// reason -> admin_audit_log via withAdmin, plus a booking_cancellations row.
export function POST(req: Request, { params }: { params: Promise<{ id: string }> }) {
  return withAdmin(
    "payments:act",
    async (ctx) => {
      const { id } = await params;
      const body = (await req.json().catch(() => null)) as
        | { reason?: string; refundId?: string }
        | null;
      const reason = body?.reason?.trim();
      if (!reason || reason.length < 3) {
        return Response.json({ error: "a cancellation reason is required" }, { status: 400 });
      }

      const { data: before } = await ctx.db.from("bookings").select("status").eq("id", id).maybeSingle();
      if (!before) return Response.json({ error: "not found" }, { status: 404 });

      const { data: toStatus, error } = await ctx.db.rpc("admin_cancel_booking", {
        p_booking_id: id,
        p_actor: ctx.actorUserId,
        p_reason: reason,
        p_refund_id: body?.refundId ?? null,
      });
      if (error) return Response.json({ error: error.message }, { status: 400 });

      ctx.audit({
        action: "booking.cancel",
        entityType: "bookings",
        entityId: id,
        before: { status: before.status },
        after: { status: toStatus, refund_id: body?.refundId ?? null },
        reason,
      });
      return Response.json({ status: toStatus });
    },
    { mutating: true, action: "booking.cancel" },
  )(req);
}
