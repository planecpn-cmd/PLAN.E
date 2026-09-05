"use client";

import { useEffect, useRef, useState } from "react";
import { supabase } from "@/lib/supabase";
import { Button } from "@/components/ui/Button";
import { recordAcceptances } from "@/lib/legal-acceptance";
import { LegalMarkdown } from "@/components/legal/LegalMarkdown";

const CONFIRMATIONS = [
  "I have read and understood this Risk Acknowledgment.",
  "I confirm the accuracy of the health and fitness information I have provided.",
  "I am 18 or older, or a parent or guardian confirming on behalf of a minor participant, whose details I have provided.",
];

/**
 * Full Risk Acknowledgment step in the booking flow — a step, not a modal.
 * Renders the document, gates the checkboxes on scrolling to the end, requires
 * all three ticks, then writes the acceptance row against `bookingId` and calls
 * `onAccepted`.
 */
export function RiskAcknowledgmentStep({
  bookingId,
  onAccepted,
}: {
  bookingId: string;
  onAccepted: () => void;
}) {
  const [body, setBody] = useState<string | null>(null);
  const [loadError, setLoadError] = useState(false);
  const [checked, setChecked] = useState([false, false, false]);
  const [scrolledEnd, setScrolledEnd] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);
  const scrollRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    let alive = true;
    supabase
      .from("legal_documents")
      .select("body_md")
      .eq("slug", "risk-acknowledgment")
      .eq("is_current", true)
      .eq("locale", "en")
      .maybeSingle()
      .then(({ data, error }) => {
        if (!alive) return;
        if (error || !data) setLoadError(true);
        else setBody(data.body_md);
      });
    return () => {
      alive = false;
    };
  }, []);

  function onScroll() {
    const el = scrollRef.current;
    if (!el) return;
    if (el.scrollTop + el.clientHeight >= el.scrollHeight - 48) setScrolledEnd(true);
  }

  // A short document that never scrolls counts as read.
  useEffect(() => {
    const el = scrollRef.current;
    if (el && body && el.scrollHeight <= el.clientHeight + 1) setScrolledEnd(true);
  }, [body]);

  const allChecked = checked.every(Boolean);

  async function submit() {
    setSubmitting(true);
    setSubmitError(null);
    try {
      await recordAcceptances(["risk-acknowledgment"], { bookingId });
      onAccepted();
    } catch {
      setSubmitting(false);
      setSubmitError("Could not record acknowledgment. Please try again.");
    }
  }

  if (loadError) {
    return (
      <p className="mt-6 text-sm text-[var(--color-error)]">
        The Risk Acknowledgment could not be loaded. Please retry with a network
        connection.
      </p>
    );
  }

  return (
    <div className="mt-6">
      <h2 className="font-[family-name:var(--font-display)] text-xl font-semibold text-[var(--color-forest)]">
        Risk Acknowledgment
      </h2>
      <p className="mt-1 text-sm text-[var(--color-ink)]/70">
        This experience carries real risk. Read this in full before continuing.
      </p>

      <div
        ref={scrollRef}
        onScroll={onScroll}
        className="mt-4 max-h-[50vh] overflow-y-auto rounded-[var(--radius-sm)] border border-[var(--color-border)] p-4"
      >
        {body === null ? (
          <p className="text-sm text-[var(--color-ink)]/60">Loading…</p>
        ) : (
          <LegalMarkdown body={body} />
        )}
      </div>

      <fieldset className="mt-4 space-y-2" disabled={!scrolledEnd}>
        {!scrolledEnd && (
          <p className="text-xs text-[var(--color-gold)]">Scroll to the end to continue.</p>
        )}
        {CONFIRMATIONS.map((label, i) => (
          <label
            key={i}
            className="flex items-start gap-2 text-sm text-[var(--color-ink)]"
          >
            <input
              type="checkbox"
              className="mt-1"
              checked={checked[i]}
              onChange={(e) =>
                setChecked((c) => {
                  const next = [...c];
                  next[i] = e.target.checked;
                  return next;
                })
              }
            />
            <span>{label}</span>
          </label>
        ))}
      </fieldset>

      {submitError && (
        <p className="mt-3 text-sm text-[var(--color-error)]">{submitError}</p>
      )}

      <Button
        variant="primary"
        fullWidth
        className="mt-4"
        isLoading={submitting}
        disabled={!scrolledEnd || !allChecked || submitting}
        onClick={submit}
      >
        Confirm and continue
      </Button>
    </div>
  );
}
