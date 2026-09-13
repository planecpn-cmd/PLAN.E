import Link from "next/link";
import { requireScope } from "@/lib/session";
import { createAnonServerClient } from "@/lib/supabase/server";
import { AdminShell } from "@/components/AdminShell";

// Bookings list. bookings:read. RLS on bookings is has_scope('bookings:read'),
// so a scoped staff member reads with their own session client.
const STATUSES = ["pending", "confirmed", "cancellation_requested", "cancelled", "completed", "expired"] as const;

export default async function BookingsPage({
  searchParams,
}: {
  searchParams: Promise<{ status?: string }>;
}) {
  const session = await requireScope("bookings:read");
  const { status } = await searchParams;
  const supabase = await createAnonServerClient();

  let q = supabase
    .from("bookings")
    .select("id,booking_ref,status,adults,children,total_paisa,contact_name,created_at")
    .order("created_at", { ascending: false })
    .limit(200);
  if (status) q = q.eq("status", status);
  const { data: rows } = await q;

  return (
    <AdminShell scopes={session.scopes} email={session.email}>
      <h1 className="text-xl font-bold text-[var(--color-forest)]">Bookings</h1>
      <div className="mt-4 flex flex-wrap gap-2 text-sm">
        <Link
          href="/bookings"
          className={`rounded-full px-3 py-1 ${!status ? "bg-[var(--color-forest)] text-white" : "bg-white border border-[var(--color-border)]"}`}
        >
          all
        </Link>
        {STATUSES.map((s) => (
          <Link
            key={s}
            href={`/bookings?status=${s}`}
            className={`rounded-full px-3 py-1 ${status === s ? "bg-[var(--color-forest)] text-white" : "bg-white border border-[var(--color-border)]"}`}
          >
            {s.replace(/_/g, " ")}
          </Link>
        ))}
      </div>

      <table className="mt-6 w-full text-sm">
        <thead className="text-left text-[var(--color-ink)]/50">
          <tr>
            <th className="py-2">Ref</th>
            <th>Guest</th>
            <th>People</th>
            <th>Total</th>
            <th>Status</th>
            <th>Created</th>
          </tr>
        </thead>
        <tbody>
          {(rows ?? []).length === 0 && (
            <tr>
              <td colSpan={6} className="py-4 text-[var(--color-ink)]/50">
                No bookings{status ? ` in "${status}"` : ""}.
              </td>
            </tr>
          )}
          {(rows ?? []).map((b) => (
            <tr key={b.id} className="border-t border-[var(--color-border-subtle)]">
              <td className="py-2">
                <Link href={`/bookings/${b.id}`} className="text-[var(--color-forest)] hover:underline">
                  {b.booking_ref}
                </Link>
              </td>
              <td>{b.contact_name}</td>
              <td>{(b.adults ?? 0) + (b.children ?? 0)}</td>
              <td>NPR {Math.round((b.total_paisa ?? 0) / 100).toLocaleString()}</td>
              <td>{String(b.status).replace(/_/g, " ")}</td>
              <td>{new Date(b.created_at).toLocaleDateString()}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </AdminShell>
  );
}
