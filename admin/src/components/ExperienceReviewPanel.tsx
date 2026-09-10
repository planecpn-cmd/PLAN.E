"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import {
  RECOMMENDATIONS,
  DECISIONS,
  DIFFICULTIES,
  reasonRequired,
  type Recommendation,
  type Decision,
} from "@/lib/experience-review";

type Review = {
  id: string;
  reviewerId: string;
  decision: string;
  note: string | null;
  fromStatus: string | null;
  toStatus: string | null;
  createdAt: string;
};
type Taxon = { id: string; name: string };

const LABEL: Record<string, string> = {
  recommend_approve: "Recommend approve",
  recommend_reject: "Recommend reject",
  recommend_changes: "Recommend changes",
  under_review: "Mark under review",
  approve: "Approve & publish",
  reject: "Reject",
  request_changes: "Request changes",
};

export function ExperienceReviewPanel({
  experienceId,
  status,
  canDecide,
  photoPaths,
  currentCategoryId,
  currentRegionId,
  currentDifficulty,
  categories,
  regions,
  reviews,
}: {
  experienceId: string;
  status: string;
  canDecide: boolean;
  photoPaths: string[];
  currentCategoryId: string;
  currentRegionId: string;
  currentDifficulty: string;
  categories: Taxon[];
  regions: Taxon[];
  reviews: Review[];
}) {
  const router = useRouter();
  const [note, setNote] = useState("");
  const [categoryId, setCategoryId] = useState(currentCategoryId);
  const [regionId, setRegionId] = useState(currentRegionId);
  const [difficulty, setDifficulty] = useState(currentDifficulty || "moderate");
  const [busy, setBusy] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const lastRecommendation = reviews.find((r) => r.decision.startsWith("recommend_"));
  const decidable = status === "pending_review";

  async function openPhoto(path: string) {
    setBusy(path);
    setError(null);
    const res = await fetch(
      `/api/experiences/${experienceId}/photos/url?path=${encodeURIComponent(path)}`,
      { cache: "no-store" },
    );
    const body = await res.json();
    setBusy(null);
    if (!res.ok || !body.url) {
      setError(body.error ?? "could not open photo");
      return;
    }
    window.open(body.url, "_blank", "noreferrer");
  }

  async function act(kind: "recommendation" | "decision", decision: Recommendation | Decision) {
    if (reasonRequired(decision) && note.trim().length < 3) {
      setError("A reason of at least 3 characters is required for this action.");
      return;
    }
    if (kind === "decision" && decision === "approve" && (!categoryId || !regionId || !difficulty)) {
      setError("Pick a category, region and difficulty before approving.");
      return;
    }
    setBusy(decision);
    setError(null);
    const res = await fetch(`/api/experiences/${experienceId}/${kind}`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        decision,
        note: note.trim() || undefined,
        ...(kind === "decision" && decision === "approve"
          ? { categoryId, regionId, difficulty }
          : {}),
      }),
    });
    const body = await res.json();
    setBusy(null);
    if (!res.ok) {
      setError(body.error ?? "action failed");
      return;
    }
    setNote("");
    router.refresh();
  }

  return (
    <>
      <section className="mt-6">
        <h2 className="text-sm font-semibold uppercase text-[var(--color-ink)]/50">Photos</h2>
        <ul className="mt-2 flex flex-wrap gap-2 text-sm">
          {photoPaths.length === 0 && (
            <li className="text-[var(--color-ink)]/50">No photos submitted.</li>
          )}
          {photoPaths.map((p, i) => (
            <li key={p}>
              <button
                disabled={busy === p}
                onClick={() => openPhoto(p)}
                className="rounded border border-[var(--color-border)] bg-white px-3 py-1.5 hover:border-[var(--color-forest)] disabled:opacity-50"
              >
                {i === 0 ? "Cover" : `Photo ${i + 1}`}
              </button>
            </li>
          ))}
        </ul>
      </section>

      <section className="mt-6">
        <h2 className="text-sm font-semibold uppercase text-[var(--color-ink)]/50">
          {canDecide ? "Decision" : "Recommendation"}
        </h2>

        {!decidable && (
          <p className="mt-2 rounded-md bg-[var(--color-sage)] px-3 py-2 text-sm">
            This listing is <strong>{status.replace("_", " ")}</strong>, not pending review — no
            decision to make right now.
          </p>
        )}

        {canDecide && lastRecommendation && (
          <p className="mt-2 rounded-md bg-[var(--color-sage)] px-3 py-2 text-sm">
            Last recommendation: <strong>{LABEL[lastRecommendation.decision]}</strong>
            {lastRecommendation.note && <> — “{lastRecommendation.note}”</>} · by{" "}
            {lastRecommendation.reviewerId.slice(0, 8)}
          </p>
        )}

        {canDecide && (
          <div className="mt-3 grid gap-3 sm:grid-cols-3">
            <label className="text-sm">
              <span className="text-[var(--color-ink)]/50">Category</span>
              <select
                value={categoryId}
                onChange={(e) => setCategoryId(e.target.value)}
                className="mt-1 w-full rounded-md border border-[var(--color-border)] bg-white px-2 py-1.5"
              >
                <option value="">— pick —</option>
                {categories.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.name}
                  </option>
                ))}
              </select>
            </label>
            <label className="text-sm">
              <span className="text-[var(--color-ink)]/50">Region</span>
              <select
                value={regionId}
                onChange={(e) => setRegionId(e.target.value)}
                className="mt-1 w-full rounded-md border border-[var(--color-border)] bg-white px-2 py-1.5"
              >
                <option value="">— pick —</option>
                {regions.map((r) => (
                  <option key={r.id} value={r.id}>
                    {r.name}
                  </option>
                ))}
              </select>
            </label>
            <label className="text-sm">
              <span className="text-[var(--color-ink)]/50">Difficulty</span>
              <select
                value={difficulty}
                onChange={(e) => setDifficulty(e.target.value)}
                className="mt-1 w-full rounded-md border border-[var(--color-border)] bg-white px-2 py-1.5"
              >
                {DIFFICULTIES.map((d) => (
                  <option key={d} value={d}>
                    {d}
                  </option>
                ))}
              </select>
            </label>
          </div>
        )}

        <textarea
          className="mt-3 w-full rounded-md border border-[var(--color-border)] bg-white px-3 py-2 text-sm"
          rows={3}
          placeholder="Reason / note (required for reject and request-changes)"
          value={note}
          onChange={(e) => setNote(e.target.value)}
        />
        {error && <p className="mt-2 text-sm text-[var(--color-error)]">{error}</p>}

        <div className="mt-3 flex flex-wrap gap-2">
          {(canDecide ? DECISIONS : RECOMMENDATIONS).map((d) => (
            <button
              key={d}
              disabled={busy === d || !decidable}
              onClick={() => act(canDecide ? "decision" : "recommendation", d)}
              className="rounded-md border border-[var(--color-border)] bg-white px-3 py-1.5 text-sm font-medium disabled:opacity-50"
            >
              {busy === d ? "…" : LABEL[d]}
            </button>
          ))}
        </div>
        {!canDecide && (
          <p className="mt-2 text-xs text-[var(--color-ink)]/40">
            You can recommend. A staff member with content:decide commits the decision and
            normalises the taxonomy.
          </p>
        )}
      </section>

      <section className="mt-6">
        <h2 className="text-sm font-semibold uppercase text-[var(--color-ink)]/50">History</h2>
        <ul className="mt-2 space-y-1 text-sm">
          {reviews.length === 0 && <li className="text-[var(--color-ink)]/50">No activity yet.</li>}
          {reviews.map((r) => (
            <li
              key={r.id}
              className="rounded border border-[var(--color-border-subtle)] bg-white px-3 py-2"
            >
              <span className="font-medium">{LABEL[r.decision] ?? r.decision}</span>
              {r.fromStatus && r.toStatus && (
                <span className="text-[var(--color-ink)]/50">
                  {" "}
                  ({r.fromStatus} → {r.toStatus})
                </span>
              )}
              {r.note && <> — “{r.note}”</>}
              <span className="text-[var(--color-ink)]/40">
                {" "}
                · {new Date(r.createdAt).toLocaleString()} · {r.reviewerId.slice(0, 8)}
              </span>
            </li>
          ))}
        </ul>
      </section>
    </>
  );
}
