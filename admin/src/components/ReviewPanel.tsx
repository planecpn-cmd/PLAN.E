"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import {
  RECOMMENDATIONS,
  DECISIONS,
  reasonRequired,
  type Recommendation,
  type Decision,
} from "@/lib/host-review";

type Doc = { id: string; kind: string; verifiedAt: string | null; rejectionReason: string | null };
type Review = {
  id: string;
  reviewerId: string;
  decision: string;
  note: string | null;
  fromStatus: string | null;
  toStatus: string | null;
  createdAt: string;
};

const LABEL: Record<string, string> = {
  recommend_approve: "Recommend approve",
  recommend_reject: "Recommend reject",
  recommend_changes: "Recommend changes",
  under_review: "Mark under review",
  approve: "Approve",
  reject: "Reject",
  request_changes: "Request changes",
};

export function ReviewPanel({
  applicationId,
  canDecide,
  documents,
  reviews,
}: {
  applicationId: string;
  canDecide: boolean;
  documents: Doc[];
  reviews: Review[];
}) {
  const router = useRouter();
  const [note, setNote] = useState("");
  const [busy, setBusy] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const lastRecommendation = reviews.find((r) => r.decision.startsWith("recommend_"));

  async function openDoc(docId: string) {
    setBusy(docId);
    setError(null);
    const res = await fetch(`/api/host-applications/${applicationId}/documents/${docId}/url`, {
      cache: "no-store",
    });
    const body = await res.json();
    setBusy(null);
    if (!res.ok || !body.url) {
      setError(body.error ?? "could not open document");
      return;
    }
    window.open(body.url, "_blank", "noreferrer");
  }

  async function act(
    kind: "recommendation" | "decision",
    decision: Recommendation | Decision,
  ) {
    if (reasonRequired(decision) && note.trim().length < 3) {
      setError("A reason of at least 3 characters is required for this action.");
      return;
    }
    setBusy(decision);
    setError(null);
    const res = await fetch(`/api/host-applications/${applicationId}/${kind}`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ decision, note: note.trim() || undefined }),
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

  async function verifyDoc(docId: string, verified: boolean) {
    let rejectionReason: string | undefined;
    if (!verified) {
      const r = window.prompt("Why is this document rejected?");
      if (r == null) return;
      rejectionReason = r.trim();
    }
    setBusy(docId);
    const res = await fetch(
      `/api/host-applications/${applicationId}/documents/${docId}/verify`,
      {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ verified, rejectionReason }),
      },
    );
    const body = await res.json();
    setBusy(null);
    if (!res.ok) {
      setError(body.error ?? "verify failed");
      return;
    }
    router.refresh();
  }

  return (
    <>
      <section className="mt-6">
        <h2 className="text-sm font-semibold uppercase text-[var(--color-ink)]/50">Documents</h2>
        <ul className="mt-2 space-y-2 text-sm">
          {documents.length === 0 && <li className="text-[var(--color-ink)]/50">No documents.</li>}
          {documents.map((d) => (
            <li
              key={d.id}
              className="flex items-center justify-between rounded-lg border border-[var(--color-border-subtle)] bg-white px-4 py-2"
            >
              <span>
                <span className="font-medium">{d.kind.replace(/_/g, " ")}</span>{" "}
                {d.verifiedAt ? (
                  <span className="text-[var(--color-success)]">✓ verified</span>
                ) : d.rejectionReason ? (
                  <span className="text-[var(--color-error)]">✕ {d.rejectionReason}</span>
                ) : (
                  <span className="text-[var(--color-ink)]/40">unreviewed</span>
                )}
              </span>
              <span className="flex items-center gap-3">
                <button
                  disabled={busy === d.id}
                  onClick={() => openDoc(d.id)}
                  className="text-[var(--color-forest)] hover:underline disabled:opacity-50"
                >
                  open
                </button>
                <button
                  disabled={busy === d.id}
                  onClick={() => verifyDoc(d.id, true)}
                  className="rounded border border-[var(--color-border)] px-2 py-0.5 text-xs"
                >
                  verify
                </button>
                <button
                  disabled={busy === d.id}
                  onClick={() => verifyDoc(d.id, false)}
                  className="rounded border border-[var(--color-border)] px-2 py-0.5 text-xs"
                >
                  reject
                </button>
              </span>
            </li>
          ))}
        </ul>
      </section>

      <section className="mt-6">
        <h2 className="text-sm font-semibold uppercase text-[var(--color-ink)]/50">
          {canDecide ? "Decision" : "Recommendation"}
        </h2>

        {canDecide && lastRecommendation && (
          <p className="mt-2 rounded-md bg-[var(--color-sage)] px-3 py-2 text-sm">
            Last recommendation: <strong>{LABEL[lastRecommendation.decision]}</strong>
            {lastRecommendation.note && <> — “{lastRecommendation.note}”</>} · by{" "}
            {lastRecommendation.reviewerId.slice(0, 8)}
          </p>
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
              disabled={busy === d}
              onClick={() => act(canDecide ? "decision" : "recommendation", d)}
              className="rounded-md border border-[var(--color-border)] bg-white px-3 py-1.5 text-sm font-medium disabled:opacity-50"
            >
              {busy === d ? "…" : LABEL[d]}
            </button>
          ))}
        </div>
        {!canDecide && (
          <p className="mt-2 text-xs text-[var(--color-ink)]/40">
            You can recommend. A staff member with hosts:decide commits the decision.
          </p>
        )}
      </section>

      <section className="mt-6">
        <h2 className="text-sm font-semibold uppercase text-[var(--color-ink)]/50">History</h2>
        <ul className="mt-2 space-y-1 text-sm">
          {reviews.length === 0 && <li className="text-[var(--color-ink)]/50">No activity yet.</li>}
          {reviews.map((r) => (
            <li key={r.id} className="rounded border border-[var(--color-border-subtle)] bg-white px-3 py-2">
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
