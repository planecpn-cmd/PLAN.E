import { requireScope } from "@/lib/session";
import { AdminShell } from "@/components/AdminShell";
import { UsersSearch } from "@/components/UsersSearch";

// Users search. Gated on users:manage (not bookings:read) — this is a full
// directory with lifetime spend, not one booking's detail; see
// admin/src/app/api/users/route.ts. profiles is founder-only RLS, so the
// list comes from GET /api/users (service-role) rather than the session
// client.
export default async function UsersPage() {
  const session = await requireScope("users:manage");
  return (
    <AdminShell scopes={session.scopes} email={session.email}>
      <h1 className="text-xl font-bold text-[var(--color-forest)]">Users</h1>
      <UsersSearch />
    </AdminShell>
  );
}
