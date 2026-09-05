"use client";

/**
 * Cookie consent state for the PLAN E website (see the Cookie Policy).
 *
 *  - "necessary" is always on and cannot be rejected.
 *  - "functional" and "analytics" are opt-in.
 *  - A Do Not Track signal forces "analytics" off regardless of stored choice.
 *  - The choice is stored for 12 months.
 *
 * No analytics script must load until `hasConsent("analytics")` is true.
 */

export type CookieCategory = "necessary" | "functional" | "analytics";

export interface CookieConsent {
  necessary: true;
  functional: boolean;
  analytics: boolean;
  /** epoch ms when the choice was made */
  ts: number;
}

export const COOKIE_NAME = "plan_e_cookie_consent";
const MAX_AGE_SECONDS = 60 * 60 * 24 * 365; // 12 months
export const COOKIE_CONSENT_EVENT = "plan-e:open-cookie-settings";
export const COOKIE_CONSENT_CHANGED = "plan-e:cookie-consent-changed";

export function doNotTrackEnabled(): boolean {
  if (typeof navigator === "undefined") return false;
  const dnt =
    navigator.doNotTrack ??
    // @ts-expect-error - legacy vendor fields
    window.doNotTrack ??
    // @ts-expect-error - legacy vendor fields
    navigator.msDoNotTrack;
  return dnt === "1" || dnt === "yes";
}

export function readConsent(): CookieConsent | null {
  if (typeof document === "undefined") return null;
  const raw = document.cookie
    .split("; ")
    .find((c) => c.startsWith(`${COOKIE_NAME}=`))
    ?.split("=")[1];
  if (!raw) return null;
  try {
    const parsed = JSON.parse(decodeURIComponent(raw)) as Partial<CookieConsent>;
    return {
      necessary: true,
      functional: Boolean(parsed.functional),
      analytics: Boolean(parsed.analytics) && !doNotTrackEnabled(),
      ts: typeof parsed.ts === "number" ? parsed.ts : Date.now(),
    };
  } catch {
    return null;
  }
}

export function writeConsent(choice: {
  functional: boolean;
  analytics: boolean;
}): CookieConsent {
  const value: CookieConsent = {
    necessary: true,
    functional: choice.functional,
    analytics: choice.analytics && !doNotTrackEnabled(),
    ts: Date.now(),
  };
  document.cookie =
    `${COOKIE_NAME}=${encodeURIComponent(JSON.stringify(value))}` +
    `; path=/; max-age=${MAX_AGE_SECONDS}; SameSite=Lax`;
  window.dispatchEvent(new CustomEvent(COOKIE_CONSENT_CHANGED, { detail: value }));
  return value;
}

export function hasConsent(category: CookieCategory): boolean {
  if (category === "necessary") return true;
  const c = readConsent();
  if (!c) return false;
  return category === "analytics" ? c.analytics : c.functional;
}
