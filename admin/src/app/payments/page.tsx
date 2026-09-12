import Link from "next/link";
import { requireAnyScope } from "@/lib/session";
import { createAnonServerClient } from "@/lib/supabase/server";
import { AdminShell } from "@/components/AdminShell";
import { OpsActionForm } from "@/components/OpsActionForm";

function stuckCutoffIso(): string {
  return new Date(Date.now() - 30 * 60_000).toISOString();
}

// Payments reconciliation. payments:read OR payments:act opens the page (a
// payments:act-only moderator needs to see payments to act on one; see
// 20260912090000 — payments RLS accepts both scopes too). ?stuck=1 -> the
// daily stuck-payment ritual (initiated > 30 min). The re-verify + refund
// forms below still check payments:act specifically before rendering.
export default async function PaymentsPage({
  searchParams,
}: {
  searchParams: Promise<{ stuck?: string }>;
}) {
  const session = await requireAnyScope(["payments:read", "payments:act"]);
  const { stuck } = await searchParams;
  const supabase = await createAnonServerClient();
  const canAct = session.scopes.includes("payments:act");

  let q = supabase
    .from("payments")
    .select("id,booking_id,provider,amount_paisa,status,paid_at,created_at,raw_response")
    .order("created_at", { ascending: false })
    .limit(200);
  if (stuck === "1") {
    q = q.eq("status", "initiated").lt("created_at", stuckCutoffIso());
  }
  const { data: rows } = await q;

  return (
    <AdminShell scopes={session.scopes} email={session.email}>
      <h1 className="text-xl font-bold text-[var(--color-forest)]">Payments</h1>
      <div className="mt-4 flex gap-2 text-sm">
        <Link
          href="/payments"
          className={`rounded-full px-3 py-1 ${!stuck ? "bg-[var(--color-forest)] text-white" : "bg-white border border-[var(--color-border)]"}`}
        >
          all
        </Link>
        <Link
          href="/payments?stuck=1"
          className={`rounded-full px-3 py-1 ${stuck === "1" ? "bg-[var(--color-forest)] text-white" : "bg-white border border-[var(--color-border)]"}`}
        >
          stuck ({">"}30 min)
        </Link>
      </div>

      <div className="mt-6 space-y-3">
        {(rows ?? []).length === 0 && (
          <p className="text-sm text-[var(--color-ink)]/50">No payments{stuck ? " stuck right now" : ""}.</p>
        )}
        {(rows ?? []).map((p) => {
          const raw = (p.raw_response ?? {}) as Record<string, unknown>;
          const gateway = (raw.status as string | undefined) ?? "—";
          return (
            <div key={p.id} className="rounded-lg border border-[var(--color-border-subtle)] bg-white p-4 text-sm">
              <div className="flex flex-wrap items-center justify-between gap-2">
                <div>
                  <span className="font-medium">{p.provider.toUpperCase()}</span> · NPR{" "}
                  {Math.round(p.amount_paisa / 100).toLocaleString()} ·{" "}
                  <Link href={`/bookings/${p.booking_id}`} className="text-[var(--color-forest)] hover:underline">
                    booking
                  </Link>
                </div>
                <div className="text-xs text-[var(--color-ink)]/50">
                  {new Date(p.created_at).toLocaleString()}
                </div>
              </div>
              <div className="mt-1 text-xs">
                we say <strong>{p.status}</strong> · gateway says <strong>{gateway}</strong>
              </div>
              {canAct && (
                <div className="mt-2 flex flex-wrap gap-2">
                  {p.status === "initiated" && (
                    <OpsActionForm
                      endpoint={`/api/payments/${p.id}/reverify`}
                      label="Re-verify with gateway"
                      reasonLabel=""
                    />
                  )}
                  {p.status === "paid" && (
                    <OpsActionForm
                      endpoint={`/api/payments/${p.id}/refund`}
                      label="Create refund"
                      fields={[{ name: "amountNpr", label: "Refund amount (NPR)", type: "number" }]}
                    />
                  )}
                </div>
              )}
            </div>
          );
        })}
      </div>

      <p className="mt-8 text-xs text-[var(--color-ink)]/40">
        Refunds record a pending row only. The live Khalti/eSewa refund call is behind the{" "}
        <code>refund_gateway_live</code> flag (currently OFF) and is exercised in sandbox first.
      </p>
    </AdminShell>
  );
}
