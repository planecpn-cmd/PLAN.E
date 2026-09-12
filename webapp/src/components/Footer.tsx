"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Logo } from "@/components/ui/Logo";
import { CookieSettingsLink } from "@/components/cookie/CookieSettingsLink";
import { LEGAL_DOC_ORDER } from "@/lib/legal";

const LEGAL_TITLES: Record<string, string> = {
  "terms-of-service": "Terms of Service",
  "privacy-policy": "Privacy Policy",
  "booking-terms": "Booking Terms",
  "cancellation-policy": "Cancellation Policy",
  "refund-policy": "Refund Policy",
  "payment-policy": "Payment Policy",
  "grievance-policy": "Grievance Policy",
  "account-deletion-policy": "Account Deletion",
  "community-guidelines": "Community Guidelines",
  "safety-and-risk-policy": "Safety & Risk",
  "risk-acknowledgment": "Risk Acknowledgment",
  "emergency-policy": "Emergency Policy",
  "cookie-policy": "Cookie Policy",
};

const linkClass = "hover:text-[var(--color-forest)]";

// Shared by both footer variants: unchanged, still tracked separately as a
// launch blocker (all 13 currently 404 - AUDIT.md / BLOCKED.md). Not this
// node's job to fix; reusing it as-is keeps this from being a NEW 404, since
// it is the same block the site already shows everywhere today.
function LegalLinks() {
  return (
    <div className="mt-6 border-t border-[var(--color-border-subtle)] pt-4">
      <nav aria-label="Legal" className="flex flex-wrap gap-x-5 gap-y-2 text-[var(--color-ink)]/60">
        {LEGAL_DOC_ORDER.map((slug) => (
          <Link key={slug} href={`/legal/${slug}`} className={linkClass}>
            {LEGAL_TITLES[slug]}
          </Link>
        ))}
        <CookieSettingsLink className={linkClass} />
      </nav>
    </div>
  );
}

// Marketing footer (homepage only - N2 Foundation). Same reasoning as
// MarketingNav in Nav.tsx: "Why PLAN E" / "How It Works" / "About" have no
// route to point to yet, so they are omitted rather than linked as 404s.
// "For Hosts" reuses /host, same as the nav.
function MarketingFooter() {
  return (
    <footer className="hidden border-t border-[var(--color-border-subtle)] bg-[var(--color-card-alt)] lg:block">
      <div className="mx-auto max-w-[1280px] px-6 py-8 text-sm text-[var(--color-ink)]/70">
        <div className="flex items-start justify-between gap-8">
          <div className="flex flex-col gap-3">
            <Logo size={16} />
            <p>&copy; {new Date().getFullYear()} PLAN E Nepal</p>
          </div>
          <nav aria-label="Site" className="flex gap-6">
            <Link href="/explore" className={linkClass}>
              Explore
            </Link>
            <Link href="/host" className={linkClass}>
              For Hosts
            </Link>
          </nav>
        </div>
        <LegalLinks />
      </div>
    </footer>
  );
}

export function Footer() {
  const pathname = usePathname();
  if (pathname === "/") return <MarketingFooter />;

  return (
    <footer className="hidden border-t border-[var(--color-border-subtle)] bg-[var(--color-card-alt)] lg:block">
      <div className="mx-auto max-w-[1280px] px-6 py-8 text-sm text-[var(--color-ink)]/70">
        <div className="flex items-start justify-between gap-8">
          <div className="flex flex-col gap-3">
            <Logo size={16} />
            <p>&copy; {new Date().getFullYear()} PLAN E Nepal</p>
          </div>
          <nav aria-label="Site" className="flex gap-6">
            <Link href="/explore" className={linkClass}>
              Explore
            </Link>
            <Link href="/host" className={linkClass}>
              Become a host
            </Link>
          </nav>
        </div>
        <LegalLinks />
      </div>
    </footer>
  );
}
