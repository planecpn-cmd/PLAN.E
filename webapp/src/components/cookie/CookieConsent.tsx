"use client";

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import {
  COOKIE_CONSENT_EVENT,
  doNotTrackEnabled,
  readConsent,
  writeConsent,
} from "@/lib/cookie-consent";

/**
 * First-visit cookie banner + preferences dialog. Mounted once in the root
 * layout. Reject is exactly as prominent as Accept. Nothing beyond strictly
 * necessary cookies is set until the visitor chooses.
 */
export function CookieConsent() {
  // Starts "hidden" so server and first client render match (the cookie is not
  // readable during SSR). A layout effect then reconciles with the real cookie
  // before paint — this is external-system sync, the legitimate use of an
  // effect for state.
  const [state, setState] = useState<"hidden" | "banner" | "manage">("hidden");
  const [functional, setFunctional] = useState(false);
  const [analytics, setAnalytics] = useState(false);
  const dnt = typeof window !== "undefined" && doNotTrackEnabled();

  useEffect(() => {
    const sync = (forceManage = false) => {
      const existing = readConsent();
      setFunctional(existing?.functional ?? false);
      setAnalytics(existing?.analytics ?? false);
      setState(forceManage ? "manage" : existing ? "hidden" : "banner");
    };
    sync();
    const open = () => sync(true);
    window.addEventListener(COOKIE_CONSENT_EVENT, open);
    return () => window.removeEventListener(COOKIE_CONSENT_EVENT, open);
  }, []);

  const save = useCallback((choice: { functional: boolean; analytics: boolean }) => {
    writeConsent(choice);
    setState("hidden");
  }, []);

  if (state === "hidden") return null;

  return (
    <div
      className="fixed inset-x-0 bottom-0 z-50 border-t border-[var(--color-border)] bg-white p-4 shadow-[0_-8px_24px_rgba(1,37,28,0.08)]"
      role="dialog"
      aria-label="Cookie preferences"
      aria-modal="false"
    >
      <div className="mx-auto max-w-[900px]">
        {state === "banner" ? (
          <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <p className="text-sm text-[var(--color-ink)]/80">
              We use strictly necessary cookies to run the site. With your consent we
              also use functional and analytics cookies.{" "}
              <Link
                href="/legal/cookie-policy"
                className="font-medium text-[var(--color-gold)] underline underline-offset-2"
              >
                Cookie Policy
              </Link>
              .
            </p>
            <div className="flex shrink-0 flex-wrap gap-2">
              <button
                onClick={() => save({ functional: false, analytics: false })}
                className="rounded-[var(--radius-pill)] border border-[var(--color-border)] px-4 py-2 text-sm font-semibold text-[var(--color-forest)] hover:bg-[var(--color-sage)]"
              >
                Reject all
              </button>
              <button
                onClick={() => save({ functional: true, analytics: true })}
                className="rounded-[var(--radius-pill)] border border-[var(--color-border)] px-4 py-2 text-sm font-semibold text-[var(--color-forest)] hover:bg-[var(--color-sage)]"
              >
                Accept all
              </button>
              <button
                onClick={() => setState("manage")}
                className="rounded-[var(--radius-pill)] px-4 py-2 text-sm font-semibold text-[var(--color-forest)] underline"
              >
                Manage preferences
              </button>
            </div>
          </div>
        ) : (
          <div>
            <p className="text-sm font-semibold text-[var(--color-forest)]">
              Cookie preferences
            </p>
            <ul className="mt-3 space-y-3 text-sm">
              <li className="flex items-start justify-between gap-4">
                <span>
                  <span className="font-medium">Strictly necessary</span>
                  <span className="block text-[var(--color-ink)]/60">
                    Sign-in, security, booking state. Always on.
                  </span>
                </span>
                <input type="checkbox" checked disabled aria-label="Strictly necessary (always on)" />
              </li>
              <li className="flex items-start justify-between gap-4">
                <span>
                  <span className="font-medium">Functional</span>
                  <span className="block text-[var(--color-ink)]/60">
                    Language, currency, recently viewed.
                  </span>
                </span>
                <input
                  type="checkbox"
                  checked={functional}
                  onChange={(e) => setFunctional(e.target.checked)}
                  aria-label="Functional cookies"
                />
              </li>
              <li className="flex items-start justify-between gap-4">
                <span>
                  <span className="font-medium">Analytics</span>
                  <span className="block text-[var(--color-ink)]/60">
                    {dnt
                      ? "Disabled — your browser sends a Do Not Track signal."
                      : "Aggregate usage and performance. No advertising profiles."}
                  </span>
                </span>
                <input
                  type="checkbox"
                  checked={analytics && !dnt}
                  disabled={dnt}
                  onChange={(e) => setAnalytics(e.target.checked)}
                  aria-label="Analytics cookies"
                />
              </li>
            </ul>
            <div className="mt-4 flex flex-wrap gap-2">
              <button
                onClick={() => save({ functional: false, analytics: false })}
                className="rounded-[var(--radius-pill)] border border-[var(--color-border)] px-4 py-2 text-sm font-semibold text-[var(--color-forest)] hover:bg-[var(--color-sage)]"
              >
                Reject all
              </button>
              <button
                onClick={() => save({ functional, analytics })}
                className="rounded-[var(--radius-pill)] bg-[var(--color-forest)] px-4 py-2 text-sm font-semibold text-white hover:bg-[var(--color-deep)]"
              >
                Save choices
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
