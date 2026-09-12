import { withAdmin } from "@/lib/with-admin.server";

// Create a refund request against a paid payment. payments:act. Records a
// pending refund row only — NO gateway call (the refund_gateway_live flag is
// OFF; the founder tests the gateway half in sandbox). Named action + mandatory
// reason -> admin_audit_log.
export function POST(req: Request, { params }: { params: Promise<{ id: string }> }) {
  return withAdmin(
    "payments:act",
    async (ctx) => {
      const { id } = await params;
      const body = (await req.json().catch(() => null)) as
        | { amountNpr?: number; reason?: string }
        | null;
      const reason = body?.reason?.trim();
      const amountNpr = Number(body?.amountNpr);
      if (!reason || reason.length < 3) {
        return Response.json({ error: "a refund reason is required" }, { status: 400 });
      }
      if (!Number.isFinite(amountNpr) || amountNpr <= 0) {
        return Response.json({ error: "a positive refund amount (NPR) is required" }, { status: 400 });
      }

      const { data: refundId, error } = await ctx.db.rpc("admin_create_refund", {
        p_payment_id: id,
        p_actor: ctx.actorUserId,
        p_amount_paisa: Math.round(amountNpr * 100),
        p_reason: reason,
      });
      if (error) return Response.json({ error: error.message }, { status: 400 });

      ctx.audit({
        action: "payment.refund_create",
        entityType: "payments",
        entityId: id,
        after: { refund_id: refundId, amount_paisa: Math.round(amountNpr * 100), status: "pending" },
        reason,
      });
      return Response.json({ refundId, status: "pending" });
    },
    { mutating: true, action: "payment.refund_create" },
  )(req);
}
