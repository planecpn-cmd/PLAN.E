import { withAdmin } from "@/lib/with-admin.server";

// Re-verify a stuck payment with the gateway. payments:act. Delegates to the
// admin-reverify-payment edge function (which holds the gateway secrets and
// calls finalize_verified_payment on a confirmed "Completed"). Read-only at the
// gateway; never moves money.
export function POST(req: Request, { params }: { params: Promise<{ id: string }> }) {
  return withAdmin(
    "payments:act",
    async (ctx) => {
      const { id } = await params;
      const secret = process.env.ADMIN_REVERIFY_SECRET;
      if (!secret) {
        return Response.json({ error: "ADMIN_REVERIFY_SECRET is not configured" }, { status: 503 });
      }

      const { data: before } = await ctx.db
        .from("payments")
        .select("status,booking_id")
        .eq("id", id)
        .maybeSingle();
      if (!before) return Response.json({ error: "not found" }, { status: 404 });

      const { data, error } = await ctx.db.functions.invoke("admin-reverify-payment", {
        body: { payment_id: id },
        headers: { "X-Admin-Secret": secret },
      });
      if (error) return Response.json({ error: error.message ?? "reverify failed" }, { status: 502 });

      const outcome = (data as { outcome?: string })?.outcome ?? "unknown";
      ctx.audit({
        action: "payment.reverify",
        entityType: "payments",
        entityId: id,
        before: { status: before.status },
        after: { outcome, result: data },
      });
      return Response.json({ outcome, result: data });
    },
    { mutating: true, action: "payment.reverify" },
  )(req);
}
