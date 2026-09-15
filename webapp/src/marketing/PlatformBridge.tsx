import { Compass, CreditCard, Users } from "lucide-react";

// Ported from PlatformBridge (source design: two-sided traveler/host
// framing). Rewrote the copy - the source claimed a "Verified Operator
// Program" and "certified Nepali hosts", neither of which exists (30/31
// listings have no host_id, AUDIT.md). Kept only what's true today: direct
// booking on the platform, and real Khalti/eSewa payment methods. No
// commission figure - standing rule across this project.
const SIDES = [
  {
    title: "For travelers",
    icon: Compass,
    points: [
      "Browse and book experiences directly on the platform",
      "Pay with Khalti or eSewa, no international card fees",
    ],
  },
  {
    title: "For hosts",
    icon: Users,
    points: [
      "List an experience directly, without a storefront agency",
      "Get discovered by travelers already planning their trip",
    ],
  },
];

export function PlatformBridge() {
  return (
    <section className="marketing bg-[var(--m-canvas-pure)] px-4 py-20 lg:px-6">
      <div className="mx-auto max-w-5xl">
        <div className="mb-12 max-w-2xl text-left">
          <h2 className="font-m-serif text-2xl font-bold tracking-tight text-[var(--m-forest)] sm:text-3xl">
            One bridge, both sides of the trail
          </h2>
          <p className="mt-3 text-base font-light leading-relaxed text-[var(--m-ink)]">
            PLAN E connects travelers and hosts directly on one platform, without a storefront agency in between.
          </p>
        </div>

        <div className="grid grid-cols-1 gap-6 sm:grid-cols-2">
          {SIDES.map((side) => {
            const Icon = side.icon;
            return (
              <div
                key={side.title}
                className="rounded-3xl border border-black/[0.06] bg-[var(--m-canvas)] p-7 shadow-[var(--m-shadow-premium-sm)]"
              >
                <div className="mb-4 flex h-12 w-12 items-center justify-center rounded-2xl bg-[var(--m-sage-light)] text-[var(--m-forest)]">
                  <Icon className="h-5 w-5" />
                </div>
                <h3 className="font-m-serif text-lg font-bold text-[var(--m-forest)]">{side.title}</h3>
                <ul className="mt-3 space-y-2">
                  {side.points.map((point) => (
                    <li key={point} className="flex items-start gap-2 text-sm font-light text-[var(--m-ink-light)]">
                      <CreditCard className="mt-0.5 h-3.5 w-3.5 shrink-0 text-[var(--m-gold)]" aria-hidden />
                      <span>{point}</span>
                    </li>
                  ))}
                </ul>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}
