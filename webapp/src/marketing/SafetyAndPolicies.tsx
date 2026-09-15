import Link from "next/link";
import { ShieldCheck, LifeBuoy, MessageSquareWarning, FileWarning } from "lucide-react";

// Replaces the source's TrustAndSafety, which was built entirely around a
// fabricated "4-step Govt. & TAAN verification" program that does not exist
// on this platform. Rewritten to point at what's actually real: the legal
// documents already live in this repo (same links as the site Footer).
// These pages currently 404 - a pre-existing, already-tracked gap
// (BLOCKED.md item #4), same exception the rest of the site already
// applies rather than a new one introduced here.
const POLICIES = [
  { title: "Safety & Risk Policy", href: "/legal/safety-and-risk-policy", icon: ShieldCheck },
  { title: "Emergency Policy", href: "/legal/emergency-policy", icon: LifeBuoy },
  { title: "Cancellation Policy", href: "/legal/cancellation-policy", icon: FileWarning },
  { title: "Grievance Policy", href: "/legal/grievance-policy", icon: MessageSquareWarning },
];

export function SafetyAndPolicies() {
  return (
    <section className="marketing bg-[var(--m-forest-dark)] px-4 py-20 lg:px-6">
      <div className="mx-auto max-w-5xl">
        <div className="mb-10 max-w-2xl text-left">
          <h2 className="font-m-serif text-2xl font-bold tracking-tight text-white sm:text-3xl">
            Safety &amp; policies
          </h2>
          <p className="mt-3 text-base font-light leading-relaxed text-white/75">
            Read the terms that govern every booking before you go.
          </p>
        </div>
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {POLICIES.map((policy) => {
            const Icon = policy.icon;
            return (
              <Link
                key={policy.href}
                href={policy.href}
                className="group flex flex-col gap-3 rounded-2xl border border-white/10 bg-white/5 p-5 transition-colors hover:bg-white/10"
              >
                <Icon className="h-5 w-5 text-[var(--m-gold-light)]" />
                <span className="text-sm font-semibold text-white group-hover:text-[var(--m-gold-light)]">
                  {policy.title}
                </span>
              </Link>
            );
          })}
        </div>
      </div>
    </section>
  );
}
