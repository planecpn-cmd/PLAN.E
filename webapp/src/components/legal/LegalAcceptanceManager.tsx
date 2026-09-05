"use client";

import { useEffect, useRef, useState } from "react";
import { useAuth } from "@/lib/AuthProvider";
import { Button } from "@/components/ui/Button";
import { LegalMarkdown } from "@/components/legal/LegalMarkdown";
import {
  flushPendingAcceptances,
  outstandingReacceptances,
  recordAcceptances,
} from "@/lib/legal-acceptance";
import type { LegalDocument } from "@/lib/legal";

/**
 * Mounted inside the app shell. On sign-in it flushes stashed sign-up
 * acceptances, then checks for `requires_acceptance` documents the user owes at
 * their current version:
 *   - not yet effective  → dismissible notice
 *   - effective          → non-dismissible overlay until accepted
 */
export function LegalAcceptanceManager() {
  const { user, loading } = useAuth();
  const [outstanding, setOutstanding] = useState<LegalDocument[]>([]);
  const [noticeDismissed, setNoticeDismissed] = useState(false);

  useEffect(() => {
    if (loading || !user) return;
    let alive = true;
    (async () => {
      await flushPendingAcceptances();
      const docs = await outstandingReacceptances();
      if (alive) setOutstanding(docs);
    })();
    return () => {
      alive = false;
    };
  }, [user, loading]);

  if (outstanding.length === 0) return null;

  const blocking = outstanding.filter((d) => new Date(d.effective_at) <= new Date());
  if (blocking.length > 0) {
    return (
      <ReacceptOverlay
        doc={blocking[0]}
        remaining={blocking.length}
        onAccepted={async () => setOutstanding(await outstandingReacceptances())}
      />
    );
  }

  if (noticeDismissed) return null;
  return (
    <div className="fixed inset-x-0 top-0 z-40 bg-[var(--color-sage)] px-4 py-2 text-center text-sm font-medium text-[var(--color-forest)]">
      Updated {outstanding.map((d) => d.title).join(", ")} take effect soon — you
      will be asked to accept them.{" "}
      <button onClick={() => setNoticeDismissed(true)} aria-label="Dismiss" className="underline">
        Dismiss
      </button>
    </div>
  );
}

function ReacceptOverlay({
  doc,
  remaining,
  onAccepted,
}: {
  doc: LegalDocument;
  remaining: number;
  onAccepted: () => void | Promise<void>;
}) {
  const [scrolledEnd, setScrolledEnd] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const scrollRef = useRef<HTMLDivElement>(null);

  function onScroll() {
    const el = scrollRef.current;
    if (el && el.scrollTop + el.clientHeight >= el.scrollHeight - 48) setScrolledEnd(true);
  }

  async function accept() {
    setSubmitting(true);
    setError(null);
    try {
      await recordAcceptances([doc.slug]);
      await onAccepted();
    } catch {
      setSubmitting(false);
      setError("Could not record acceptance. Check your connection.");
    }
  }

  return (
    <div className="fixed inset-0 z-[60] flex items-center justify-center bg-black/40 p-4">
      <div className="flex max-h-[90vh] w-full max-w-[720px] flex-col rounded-[var(--radius-md)] bg-white">
        <div className="border-b border-[var(--color-border-subtle)] p-4">
          <h2 className="font-[family-name:var(--font-display)] text-lg font-semibold text-[var(--color-forest)]">
            Updated: {doc.title}
          </h2>
          <p className="mt-1 text-sm text-[var(--color-ink)]/70">
            Please review and accept to continue.
            {remaining > 1 ? ` (${remaining} documents to review.)` : ""}
          </p>
        </div>
        <div ref={scrollRef} onScroll={onScroll} className="flex-1 overflow-y-auto p-4">
          <LegalMarkdown body={doc.body_md} />
        </div>
        <div className="border-t border-[var(--color-border-subtle)] p-4">
          {error && <p className="mb-2 text-sm text-[var(--color-error)]">{error}</p>}
          <Button
            variant="primary"
            fullWidth
            isLoading={submitting}
            disabled={!scrolledEnd || submitting}
            onClick={accept}
          >
            {scrolledEnd ? `Accept ${doc.title}` : "Scroll to the end to accept"}
          </Button>
        </div>
      </div>
    </div>
  );
}
