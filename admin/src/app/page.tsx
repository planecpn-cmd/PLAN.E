import { requireAdmin } from "@/lib/session";
import { AdminShell } from "@/components/AdminShell";
import { DashboardClient } from "@/components/DashboardClient";

// N6 dashboard shell. Counters only -- no revenue split, no revenue chart
// (REQUIREMENTS_DELTA C1/N6: blocked on the commission principal-vs-agent and
// direction decisions, which flip which number is "Plan E revenue" by ~3x).
// Gross booking value is the one money figure that's safe: same number
// either way. Each counter group is its own scope-gated fetch (see
// components/DashboardClient.tsx) so a single-scope moderator's browser never
// even requests data outside their scopes, not just doesn't render it.
export default async function DashboardPage() {
  const session = await requireAdmin();
  return (
    <AdminShell scopes={session.scopes} email={session.email}>
      <DashboardClient scopes={session.scopes} />
    </AdminShell>
  );
}
