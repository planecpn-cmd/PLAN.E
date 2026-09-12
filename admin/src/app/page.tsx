import { requireAdmin } from "@/lib/session";
import { AdminShell } from "@/components/AdminShell";

// Empty dashboard. No charts, no counts, no analytics (plan §4). A non-staff
// account never reaches this — requireAdmin() redirects it to /not-authorized.
export default async function DashboardPage() {
  const session = await requireAdmin();
  return (
    <AdminShell scopes={session.scopes} email={session.email}>
      <h1 className="text-xl font-bold text-[var(--color-forest)]">Dashboard</h1>
      <p className="mt-2 text-sm text-[var(--color-ink)]/70">
        Signed in as staff. Use the nav — your scopes decide what is listed.
      </p>
      <p className="mt-6 text-xs text-[var(--color-ink)]/50">
        Host review, bookings, payments and finance screens arrive in later phases.
      </p>
    </AdminShell>
  );
}
