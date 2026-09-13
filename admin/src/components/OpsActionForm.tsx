"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

type Field = { name: string; label: string; type?: "text" | "number"; required?: boolean };

// Generic "named action with a mandatory reason" form — one per C3 mutation.
// Posts JSON to `endpoint`, refreshes on success, shows the server error string.
export function OpsActionForm({
  endpoint,
  label,
  fields = [],
  reasonLabel = "Reason (required)",
  confirm,
  danger,
}: {
  endpoint: string;
  label: string;
  fields?: Field[];
  reasonLabel?: string;
  confirm?: string;
  danger?: boolean;
}) {
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const [values, setValues] = useState<Record<string, string>>({});
  const [reason, setReason] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function submit() {
    if (reasonLabel && reason.trim().length < 3) {
      setError("A reason of at least 3 characters is required.");
      return;
    }
    if (confirm && !window.confirm(confirm)) return;
    setBusy(true);
    setError(null);
    const body: Record<string, unknown> = { reason: reason.trim() || undefined };
    for (const f of fields) {
      body[f.name] = f.type === "number" ? Number(values[f.name]) : values[f.name];
    }
    const res = await fetch(endpoint, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(body),
    });
    const json = await res.json().catch(() => ({}));
    setBusy(false);
    if (!res.ok) {
      setError(json.error ?? "action failed");
      return;
    }
    setOpen(false);
    setReason("");
    setValues({});
    router.refresh();
  }

  if (!open) {
    return (
      <button
        onClick={() => setOpen(true)}
        className={`rounded-md border px-3 py-1.5 text-sm font-medium ${
          danger
            ? "border-[var(--color-error)] text-[var(--color-error)]"
            : "border-[var(--color-border)]"
        }`}
      >
        {label}
      </button>
    );
  }

  return (
    <div className="mt-2 rounded-lg border border-[var(--color-border)] bg-white p-3 text-sm">
      {fields.map((f) => (
        <label key={f.name} className="mb-2 block">
          <span className="text-[var(--color-ink)]/50">{f.label}</span>
          <input
            type={f.type ?? "text"}
            value={values[f.name] ?? ""}
            onChange={(e) => setValues((v) => ({ ...v, [f.name]: e.target.value }))}
            className="mt-1 w-full rounded border border-[var(--color-border)] px-2 py-1"
          />
        </label>
      ))}
      {reasonLabel && (
        <label className="mb-2 block">
          <span className="text-[var(--color-ink)]/50">{reasonLabel}</span>
          <textarea
            rows={2}
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            className="mt-1 w-full rounded border border-[var(--color-border)] px-2 py-1"
          />
        </label>
      )}
      {error && <p className="mb-2 text-[var(--color-error)]">{error}</p>}
      <div className="flex gap-2">
        <button
          onClick={submit}
          disabled={busy}
          className="rounded-md bg-[var(--color-forest)] px-3 py-1.5 text-white disabled:opacity-50"
        >
          {busy ? "…" : label}
        </button>
        <button onClick={() => setOpen(false)} className="rounded-md border border-[var(--color-border)] px-3 py-1.5">
          Cancel
        </button>
      </div>
    </div>
  );
}
