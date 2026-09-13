import { withAdmin } from "@/lib/with-admin.server";

// Payments reconciliation list. payments:read. ?stuck=1 -> initiated older than
// 30 minutes (the daily ops ritual).
export function GET(req: Request) {
  const url = new URL(req.url);
  const stuck = url.searchParams.get("stuck") === "1";
  const status = url.searchParams.get("status");

  return withAdmin("payments:read", async (ctx) => {
    let q = ctx.db
      .from("payments")
      .select("id,booking_id,provider,provider_ref,amount_paisa,status,paid_at,created_at,raw_response")
      .order("created_at", { ascending: false })
      .limit(200);

    if (stuck) {
      const cutoff = new Date(Date.now() - 30 * 60 * 1000).toISOString();
      q = q.eq("status", "initiated").lt("created_at", cutoff);
    } else if (status) {
      q = q.eq("status", status);
    }

    const { data, error } = await q;
    if (error) return Response.json({ error: error.message }, { status: 500 });

    return Response.json({
      rows: (data ?? []).map((p) => {
        const raw = (p.raw_response ?? {}) as Record<string, unknown>;
        const gatewaySays = (raw.status as string | undefined) ?? null;
        return {
          id: p.id,
          bookingId: p.booking_id,
          provider: p.provider,
          providerRef: p.provider_ref,
          amountNpr: Math.round((p.amount_paisa ?? 0) / 100),
          status: p.status,
          gatewaySays,
          agree: gatewaySays == null ? null : gatewayAgrees(p.status as string, gatewaySays),
          paidAt: p.paid_at,
          createdAt: p.created_at,
        };
      }),
    });
  })(req);
}

function gatewayAgrees(ours: string, gateway: string): boolean {
  const g = gateway.toLowerCase();
  if (ours === "paid") return g === "completed" || g === "complete";
  if (ours === "failed") return g === "failed" || g === "expired" || g === "user_canceled";
  return true; // initiated vs anything — undecided, treat as "no conflict yet"
}
