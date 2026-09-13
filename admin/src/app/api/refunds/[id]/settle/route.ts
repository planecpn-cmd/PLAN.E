import { withAdmin } from "@/lib/with-admin.server";

const NEXT = ["processing", "succeeded", "failed", "cancelled"] as const;

// Advance a refund through its state machine. payments:act.
//   pending -> processing | cancelled
//   processing -> succeeded | failed
// The actual Khalti/eSewa refund API call is NOT wired (refund_gateway_live is
// OFF). Moving a refund to processing/succeeded/failed here reflects a decision
// or a sandbox result the founder drives manually; cancelled needs no gateway.
export function POST(req: Request, { params }: { params: Promise<{ id: string }> }) {
  return withAdmin(
    "payments:act",
    async (ctx) => {
      const { id } = await params;
      const body = (await req.json().catch(() => null)) as
        | { toStatus?: string; providerRef?: string; failureReason?: string; reason?: string }
        | null;
      const toStatus = body?.toStatus;
      if (!toStatus || !(NEXT as readonly string[]).includes(toStatus)) {
        return Response.json({ error: `toStatus must be one of ${NEXT.join(" | ")}` }, { status: 400 });
      }
      const failureReason = body?.failureReason?.trim() || null;
      if (toStatus === "failed" && !failureReason) {
        return Response.json({ error: "a failure reason is required to fail a refund" }, { status: 400 });
      }

      const { data: before } = await ctx.db.from("refunds").select("status,payment_id").eq("id", id).maybeSingle();
      if (!before) return Response.json({ error: "not found" }, { status: 404 });

      const { data: newStatus, error } = await ctx.db.rpc("admin_settle_refund", {
        p_refund_id: id,
        p_actor: ctx.actorUserId,
        p_to_status: toStatus,
        p_provider_ref: body?.providerRef ?? null,
        p_gateway_response: null,
        p_failure_reason: failureReason,
      });
      if (error) return Response.json({ error: error.message }, { status: 400 });

      ctx.audit({
        action: "refund.settle",
        entityType: "refunds",
        entityId: id,
        before: { status: before.status },
        after: { status: newStatus },
        reason: body?.reason?.trim() || failureReason || undefined,
      });
      return Response.json({ status: newStatus });
    },
    { mutating: true, action: "refund.settle" },
  )(req);
}
