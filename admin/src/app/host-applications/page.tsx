import Link from "next/link";
import { requireScope } from "@/lib/session";
import { createAnonServerClient } from "@/lib/supabase/server";
import { AdminShell } from "@/components/AdminShell";

// Queue. hosts:review. host_applications RLS is has_scope('hosts:review'), so a
// scoped staff member reads the list with their own session client; writes go
// through the API routes.
const STATUSES = ["submitted", "under_review", "action_required", "approved", "rejected"] as const;

function ageDays(iso: string | null): number | null {
  if (!iso) return null;
  return Math.floor((Date.now() - new Date(iso).getTime()) / 86_400_000);
}

export default async function HostApplicationsPage({
  searchParams,
}: {
  searchParams: Promise<{ status?: string }>;
}) {
  const session = await requireScope("hosts:review");
  const { status } = await searchParams;
  const supabase = await createAnonServerClient();

  let query = supabase
    .from("host_applications")
    .select("id,status,title,location,submitted_at,application_data")
    .order("submitted_at", { ascending: true, nullsFirst: false });
  if (status) query = query.eq("status", status);
  const { data: apps } = await query;

  const ids = (apps ?? []).map((a) => a.id);
  const docCount = new Map<string, number>();
  if (ids.length) {
    const { data: docs } = await supabase
      .from("host_documents")
      .select("application_id")
      .in("application_id", ids);
    for (const d of docs ?? []) docCount.set(d.application_id, (docCount.get(d.application_id) ?? 0) + 1);
  }

  return (
    <AdminShell scopes={session.scopes} email={session.email}>
      <h1 className="text-xl font-bold text-[var(--color-forest)]">Host applications</h1>

      <div className="mt-4 flex flex-wrap gap-2 text-sm">
        <Link
          href="/host-applications"
          className={`rounded-full px-3 py-1 ${!status ? "bg-[var(--color-forest)] text-white" : "bg-white border border-[var(--color-border)]"}`}
        >
          All
        </Link>
        {STATUSES.map((s) => (
          <Link
            key={s}
            href={`/host-applications?status=${s}`}
            className={`rounded-full px-3 py-1 ${status === s ? "bg-[var(--color-forest)] text-white" : "bg-white border border-[var(--color-border)]"}`}
          >
            {s.replace("_", " ")}
          </Link>
        ))}
      </div>

      <div className="mt-6 space-y-3">
        {(apps ?? []).length === 0 && (
          <p className="text-sm text-[var(--color-ink)]/50">No applications{status ? ` in "${status}"` : ""}.</p>
        )}
        {(apps ?? []).map((a) => {
          const d = a.application_data as Record<string, unknown> | null;
          const age = ageDays(a.submitted_at);
          return (
            <Link
              key={a.id}
              href={`/host-applications/${a.id}`}
              className="block rounded-lg border border-[var(--color-border-subtle)] bg-white p-4 hover:border-[var(--color-forest)]"
            >
              <div className="flex items-start justify-between gap-3">
                <div>
                  <div className="font-medium">
                    {(d?.full_name as string) || a.title || "Untitled application"}
                  </div>
                  <div className="text-xs text-[var(--color-ink)]/60">
                    {(d?.hosting_type as string) ?? "—"} · {a.location ?? "—"} ·{" "}
                    {docCount.get(a.id) ?? 0} document{(docCount.get(a.id) ?? 0) === 1 ? "" : "s"}
                  </div>
                </div>
                <div className="shrink-0 text-right">
                  <span className="rounded-full bg-[var(--color-sage)] px-2 py-0.5 text-xs font-medium text-[var(--color-forest)]">
                    {String(a.status).replace("_", " ")}
                  </span>
                  {age != null && (
                    <div className="mt-1 text-xs text-[var(--color-ink)]/50">{age}d old</div>
                  )}
                </div>
              </div>
            </Link>
          );
        })}
      </div>
    </AdminShell>
  );
}
