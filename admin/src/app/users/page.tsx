import { requireScope } from "@/lib/session";
import { AdminShell } from "@/components/AdminShell";
import { UsersSearch } from "@/components/UsersSearch";

// Users search. bookings:read to open (viewing booking history). The
// suspend / reactivate forms need users:manage — passed to the client.
// profiles is founder-only RLS, so the list comes from GET /api/users
// (service-role) rather than the session client.
export default async function UsersPage() {
  const session = await requireScope("bookings:read");
  return (
    <AdminShell scopes={session.scopes} email={session.email}>
      <h1 className="text-xl font-bold text-[var(--color-forest)]">Users</h1>
      <UsersSearch canManage={session.scopes.includes("users:manage")} />
    </AdminShell>
  );
}
