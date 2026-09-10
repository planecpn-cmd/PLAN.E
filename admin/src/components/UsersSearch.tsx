"use client";

import { useEffect, useState } from "react";
import { OpsActionForm } from "@/components/OpsActionForm";

type Row = {
  id: string;
  name: string | null;
  phone: string | null;
  role: string;
  suspendedAt: string | null;
  suspendedReason: string | null;
  bookingCount: number;
  totalSpentNpr: number;
};

export function UsersSearch({ canManage }: { canManage: boolean }) {
  const [q, setQ] = useState("");
  const [rows, setRows] = useState<Row[]>([]);
  const [loading, setLoading] = useState(true);

  async function load(term: string) {
    setLoading(true);
    const res = await fetch(`/api/users?q=${encodeURIComponent(term)}`, { cache: "no-store" });
    if (res.ok) setRows(((await res.json()).rows ?? []) as Row[]);
    setLoading(false);
  }

  useEffect(() => {
    let cancelled = false;
    fetch(`/api/users?q=`, { cache: "no-store" })
      .then((r) => (r.ok ? r.json() : { rows: [] }))
      .then((j) => {
        if (cancelled) return;
        setRows((j.rows ?? []) as Row[]);
        setLoading(false);
      })
      .catch(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, []);

  return (
    <>
      <form
        onSubmit={(e) => {
          e.preventDefault();
          load(q);
        }}
        className="mt-4 flex gap-2"
      >
        <input
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="name or phone"
          className="flex-1 rounded-md border border-[var(--color-border)] px-3 py-2 text-sm"
        />
        <button className="rounded-md bg-[var(--color-forest)] px-4 py-2 text-sm text-white">Search</button>
      </form>

      <div className="mt-6 space-y-3">
        {loading && <p className="text-sm text-[var(--color-ink)]/50">Loading…</p>}
        {!loading && rows.length === 0 && <p className="text-sm text-[var(--color-ink)]/50">No users.</p>}
        {rows.map((u) => (
          <div key={u.id} className="rounded-lg border border-[var(--color-border-subtle)] bg-white p-4 text-sm">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <div>
                <span className="font-medium">{u.name ?? "—"}</span> · {u.phone ?? "no phone"} · {u.role}
                {u.suspendedAt && (
                  <span className="ml-2 rounded bg-[var(--color-error)]/10 px-2 py-0.5 text-xs text-[var(--color-error)]">
                    suspended — {u.suspendedReason}
                  </span>
                )}
              </div>
              <div className="text-xs text-[var(--color-ink)]/50">
                {u.bookingCount} bookings · NPR {u.totalSpentNpr.toLocaleString()} spent · country: not collected
              </div>
            </div>
            {canManage && (
              <div className="mt-2">
                {u.suspendedAt ? (
                  <OpsActionForm
                    endpoint={`/api/users/${u.id}/reactivate`}
                    label="Reactivate"
                    reasonLabel="Note (optional)"
                  />
                ) : (
                  <OpsActionForm endpoint={`/api/users/${u.id}/suspend`} label="Suspend" danger />
                )}
              </div>
            )}
          </div>
        ))}
      </div>
    </>
  );
}
