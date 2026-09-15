import { CreditCard, FileText, WifiOff } from "lucide-react";

// Ported from WhyPlanE (source design: numbered friction-point cards).
// Rewrote the content entirely - the source's "40-50% middleman" and
// "95%+ payout" statistics were unsourced, and its "verified guides" framing
// duplicated the fabricated verification-programme claim. This keeps only
// general, unfalsifiable Nepal-travel context (permits, connectivity) plus
// the one thing AUDIT.md confirms true about this platform: local payment
// methods. No commission figure - standing rule across this project.
const POINTS = [
  {
    icon: CreditCard,
    title: "Local payments, not foreign wire transfers",
    desc: "Khalti and eSewa are built into checkout, so paying for a trip doesn't mean cash, informal transfers, or foreign-exchange fees.",
  },
  {
    icon: FileText,
    title: "Permits and logistics, in one place",
    desc: "TIMS, ACAP, and national park entry requirements vary by trail and region - each experience page lays out what's included.",
  },
  {
    icon: WifiOff,
    title: "Built for Nepal's connectivity",
    desc: "Mountain trails regularly sit outside cellular coverage. Your booking and plans don't depend on a live connection once you've left.",
  },
];

export function WhyPlanE() {
  return (
    <section className="marketing bg-[var(--m-canvas)] px-4 py-20 lg:px-6">
      <div className="mx-auto max-w-6xl">
        <div className="mb-12 max-w-2xl text-left">
          <h2 className="font-m-serif text-2xl font-bold tracking-tight text-[var(--m-forest)] sm:text-3xl">
            Why PLAN E exists
          </h2>
          <p className="mt-3 text-base font-light leading-relaxed text-[var(--m-ink)]">
            Planning a trip across Nepal means navigating permits, patchy connectivity, and payment methods that
            don&apos;t always talk to international systems.
          </p>
        </div>

        <div className="grid grid-cols-1 gap-6 sm:grid-cols-3">
          {POINTS.map((point) => {
            const Icon = point.icon;
            return (
              <div
                key={point.title}
                className="rounded-3xl border border-black/[0.06] bg-[var(--m-canvas-pure)] p-7 shadow-[var(--m-shadow-premium-sm)]"
              >
                <div className="mb-4 flex h-12 w-12 items-center justify-center rounded-2xl border border-black/[0.08] bg-white text-[var(--m-forest)]">
                  <Icon className="h-5 w-5" />
                </div>
                <h3 className="font-m-serif text-base font-bold text-[var(--m-forest)]">{point.title}</h3>
                <p className="mt-2 text-sm font-light leading-relaxed text-[var(--m-ink-light)]">{point.desc}</p>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}
