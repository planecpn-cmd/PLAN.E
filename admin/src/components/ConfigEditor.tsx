"use client";

import { useState } from "react";

export type Flag = {
  key: string;
  enabled: boolean;
  rollout_percent: number;
  platforms: string[];
  description: string | null;
};

export function ConfigEditor({ initialFlags }: { initialFlags: Flag[] }) {
  const [flags, setFlags] = useState<Flag[]>(initialFlags);
  const [error, setError] = useState<string | null>(null);
  const [pendingKey, setPendingKey] = useState<string | null>(null);

  async function refresh() {
    const res = await fetch("/api/config/feature_flags", { cache: "no-store" });
    const body = await res.json();
    if (res.ok) setFlags(body.rows as Flag[]);
  }

  async function toggle(flag: Flag) {
    const nextEnabled = !flag.enabled;
    const reason = window.prompt(
      `Reason for turning "${flag.key}" ${nextEnabled ? "ON" : "OFF"}:`,
    );
    if (reason == null) return;
    if (reason.trim().length < 3) {
      setError("A reason of at least 3 characters is required.");
      return;
    }
    setPendingKey(flag.key);
    setError(null);
    const res = await fetch("/api/config/feature_flags", {
      method: "PATCH",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ key: flag.key, patch: { enabled: nextEnabled }, reason: reason.trim() }),
    });
    const body = await res.json();
    setPendingKey(null);
    if (!res.ok) {
      setError(body.error ?? "update failed");
      return;
    }
    await refresh();
  }

  return (
    <div className="mt-6">
      {error && <p className="mb-3 text-sm text-[var(--color-error)]">{error}</p>}
      <table className="w-full border-collapse text-sm">
        <thead>
          <tr className="border-b border-[var(--color-border)] text-left text-xs uppercase text-[var(--color-ink)]/50">
            <th className="py-2 pr-4">Flag</th>
            <th className="py-2 pr-4">State</th>
            <th className="py-2 pr-4">Rollout</th>
            <th className="py-2 pr-4">Platforms</th>
            <th className="py-2" />
          </tr>
        </thead>
        <tbody>
          {flags.map((f) => (
            <tr key={f.key} className="border-b border-[var(--color-border-subtle)] align-top">
              <td className="py-3 pr-4">
                <div className="font-medium">{f.key}</div>
                {f.description && (
                  <div className="text-xs text-[var(--color-ink)]/50">{f.description}</div>
                )}
              </td>
              <td className="py-3 pr-4">
                <span
                  className={
                    f.enabled
                      ? "rounded-full bg-[var(--color-sage)] px-2 py-0.5 text-xs font-medium text-[var(--color-forest)]"
                      : "rounded-full bg-[var(--color-error-container)] px-2 py-0.5 text-xs font-medium text-[var(--color-error)]"
                  }
                >
                  {f.enabled ? "On" : "Off"}
                </span>
              </td>
              <td className="py-3 pr-4">{f.rollout_percent}%</td>
              <td className="py-3 pr-4 text-xs text-[var(--color-ink)]/60">
                {(f.platforms ?? []).join(", ")}
              </td>
              <td className="py-3 text-right">
                <button
                  type="button"
                  disabled={pendingKey === f.key}
                  onClick={() => toggle(f)}
                  className="rounded-md border border-[var(--color-border)] px-3 py-1 text-xs font-medium disabled:opacity-50"
                >
                  {pendingKey === f.key ? "…" : f.enabled ? "Turn off" : "Turn on"}
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
      <p className="mt-6 text-xs text-[var(--color-ink)]/40">
        app_config, remote_content and app_versions editing lands in a later pass;
        this screen exists to prove the withAdmin write path end to end.
      </p>
    </div>
  );
}
