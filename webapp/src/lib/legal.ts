// Shared legal-document constants. Safe to import from both client and server
// components (no server-only imports here).

export const LEGAL_DOC_ORDER = [
  "terms-of-service",
  "privacy-policy",
  "booking-terms",
  "cancellation-policy",
  "refund-policy",
  "payment-policy",
  "grievance-policy",
  "account-deletion-policy",
  "community-guidelines",
  "safety-and-risk-policy",
  "risk-acknowledgment",
  "emergency-policy",
  "cookie-policy",
] as const;

export type LegalSlug = (typeof LEGAL_DOC_ORDER)[number];

/** Documents a signed-in user must hold a current-version acceptance for. */
export const ACCEPTANCE_REQUIRED_SLUGS: LegalSlug[] = [
  "terms-of-service",
  "privacy-policy",
  "booking-terms",
  "cancellation-policy",
  "community-guidelines",
  "risk-acknowledgment",
];

/** Accepted together at sign-up. */
export const SIGN_UP_ACCEPTANCE_SLUGS: LegalSlug[] = [
  "terms-of-service",
  "privacy-policy",
  "community-guidelines",
];

/** Accepted together at checkout. */
export const CHECKOUT_ACCEPTANCE_SLUGS: LegalSlug[] = [
  "booking-terms",
  "cancellation-policy",
];

export interface LegalDocument {
  id: string;
  slug: string;
  version: string;
  locale: string;
  title: string;
  body_md: string;
  effective_at: string;
  requires_acceptance: boolean;
  is_current: boolean;
}

/** H2 headings → `{ id, text }`, matching the slug ids the renderer emits. */
export function extractToc(bodyMd: string): { id: string; text: string }[] {
  const toc: { id: string; text: string }[] = [];
  for (const line of bodyMd.split("\n")) {
    const m = /^##\s+(?!#)(.+?)\s*$/.exec(line);
    if (m) toc.push({ id: slugifyHeading(m[1]), text: m[1] });
  }
  return toc;
}

export function slugifyHeading(text: string): string {
  return text
    .toLowerCase()
    .replace(/[^\w\s-]/g, "")
    .trim()
    .replace(/\s+/g, "-");
}
