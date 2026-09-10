import Link from "next/link";
import { requireScope } from "@/lib/session";
import { createAnonServerClient } from "@/lib/supabase/server";
import { AdminShell } from "@/components/AdminShell";

// Experience review queue. content:manage. experiences RLS has a
// has_scope('content:manage') read policy (20260908140000), so a scoped staff
// member reads the list with their own session client; writes go through the
// API routes.
const STATUSES = ["pending_review", "published", "draft", "paused", "archived"] as const;

function ageDays(iso: string | null): number | null {
  if (!iso) return null;
  return Math.floor((Date.now() - new Date(iso).getTime()) / 86_400_000);
}

export default async function ExperienceQueuePage({
  searchParams,
}: {
  searchParams: Promise<{ status?: string }>;
}) {
  const session = await requireScope("content:manage");
  const { status } = await searchParams;
  const active = status ?? "pending_review";
  const supabase = await createAnonServerClient();

  let query = supabase
    .from("experiences")
    .select("id,title,status,location_name,price_paisa,updated_at,created_at")
    .order("updated_at", { ascending: true });
  if (active !== "all") query = query.eq("status", active);
  const { data: rows } = await query;

  return (
    <AdminShell scopes={session.scopes} email={session.email}>
      <h1 className="text-xl font-bold text-[var(--color-forest)]">Experiences</h1>

      <div className="mt-4 flex flex-wrap gap-2 text-sm">
        {STATUSES.map((s) => (
          <Link
            key={s}
            href={`/experiences?status=${s}`}
            className={`rounded-full px-3 py-1 ${
              active === s
                ? "bg-[var(--color-forest)] text-white"
                : "bg-white border border-[var(--color-border)]"
            }`}
          >
            {s.replace("_", " ")}
          </Link>
        ))}
        <Link
          href="/experiences?status=all"
          className={`rounded-full px-3 py-1 ${
            active === "all"
              ? "bg-[var(--color-forest)] text-white"
              : "bg-white border border-[var(--color-border)]"
          }`}
        >
          all
        </Link>
      </div>

      <div className="mt-6 space-y-3">
        {(rows ?? []).length === 0 && (
          <p className="text-sm text-[var(--color-ink)]/50">No experiences in &quot;{active}&quot;.</p>
        )}
        {(rows ?? []).map((r) => {
          const age = ageDays(r.updated_at);
          return (
            <Link
              key={r.id}
              href={`/experiences/${r.id}`}
              className="block rounded-lg border border-[var(--color-border-subtle)] bg-white p-4 hover:border-[var(--color-forest)]"
            >
              <div className="flex items-start justify-between gap-3">
                <div>
                  <div className="font-medium">{r.title || "Untitled experience"}</div>
                  <div className="text-xs text-[var(--color-ink)]/60">
                    {r.location_name ?? "—"} · NPR{" "}
                    {Math.round((r.price_paisa ?? 0) / 100).toLocaleString()}
                  </div>
                </div>
                <div className="shrink-0 text-right">
                  <span className="rounded-full bg-[var(--color-sage)] px-2 py-0.5 text-xs font-medium text-[var(--color-forest)]">
                    {String(r.status).replace("_", " ")}
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
