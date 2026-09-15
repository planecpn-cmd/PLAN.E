"use client";

import { useState } from "react";
import Link from "next/link";
import { ChevronDown } from "lucide-react";

// Ported from FaqSection (source design: accordion). Rewrote the payment
// answer entirely - the source claimed "30% to 50% broker commissions" are
// avoided (unsourced comparison) and that payments sit in "secure escrow ...
// disbursed when your journey is underway" (not how this platform's payment
// finalization actually works - a booking is confirmed once the payment
// gateway settles it, not held until departure). No commission figure -
// standing rule across this project.
const FAQS = [
  {
    q: "How do I pay for a booking?",
    a: "Checkout uses Khalti or eSewa. Your booking is confirmed once the payment gateway settles the payment.",
  },
  {
    q: "What if I need to cancel?",
    a: "Cancellations are governed by the Cancellation Policy, which applies to every booking made through PLAN E.",
  },
  {
    q: "Do I need an app to book?",
    a: "No - booking works directly on this site. There's no app-store download required.",
  },
  {
    q: "How do I list an experience as a host?",
    a: "Start a host application from the For Hosts page. Applications are reviewed before a listing goes live.",
  },
];

export function FaqSection() {
  const [openIndex, setOpenIndex] = useState<number | null>(null);

  return (
    <section className="marketing bg-[var(--m-canvas-pure)] px-4 py-20 lg:px-6">
      <div className="mx-auto max-w-3xl">
        <h2 className="font-m-serif text-2xl font-bold tracking-tight text-[var(--m-forest)] sm:text-3xl">
          Frequently asked questions
        </h2>

        <div className="mt-8 divide-y divide-black/[0.06] rounded-2xl border border-black/[0.06]">
          {FAQS.map((item, idx) => {
            const isOpen = openIndex === idx;
            return (
              <div key={item.q}>
                <button
                  type="button"
                  onClick={() => setOpenIndex(isOpen ? null : idx)}
                  aria-expanded={isOpen}
                  className="flex w-full items-center justify-between gap-4 px-5 py-4 text-left"
                >
                  <span className="text-sm font-semibold text-[var(--m-forest)]">{item.q}</span>
                  <ChevronDown
                    className={`h-4 w-4 shrink-0 text-[var(--m-ink-muted)] transition-transform ${isOpen ? "rotate-180" : ""}`}
                  />
                </button>
                {isOpen && (
                  <p className="px-5 pb-4 text-sm font-light leading-relaxed text-[var(--m-ink-light)]">{item.a}</p>
                )}
              </div>
            );
          })}
        </div>

        <p className="mt-6 text-sm text-[var(--m-ink-muted)]">
          More detail lives in the{" "}
          <Link href="/legal" className="font-semibold text-[var(--m-forest)] underline underline-offset-2">
            legal documents
          </Link>
          .
        </p>
      </div>
    </section>
  );
}
