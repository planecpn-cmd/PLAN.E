"use client";

import { COOKIE_CONSENT_EVENT } from "@/lib/cookie-consent";

/** Footer link that reopens the cookie preferences dialog. */
export function CookieSettingsLink({ className }: { className?: string }) {
  return (
    <button
      type="button"
      onClick={() => window.dispatchEvent(new CustomEvent(COOKIE_CONSENT_EVENT))}
      className={className}
    >
      Cookie settings
    </button>
  );
}
