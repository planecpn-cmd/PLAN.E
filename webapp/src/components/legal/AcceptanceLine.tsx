import Link from "next/link";

const DOCS = {
  signUp: [
    { name: "Terms of Service", slug: "terms-of-service" },
    { name: "Privacy Policy", slug: "privacy-policy" },
    { name: "Community Guidelines", slug: "community-guidelines" },
  ],
  checkout: [
    { name: "Booking Terms", slug: "booking-terms" },
    { name: "Cancellation Policy", slug: "cancellation-policy" },
  ],
} as const;

function DocLink({ name, slug }: { name: string; slug: string }) {
  return (
    <Link
      href={`/legal/${slug}`}
      target="_blank"
      className="font-semibold text-[var(--color-gold)] underline underline-offset-2"
    >
      {name}
    </Link>
  );
}

/**
 * The one-line acceptance statement. One combined sentence with tappable
 * document names — not a row of checkboxes. The acceptance rows are written by
 * the surrounding flow.
 */
export function AcceptanceLine({ context }: { context: "signUp" | "checkout" }) {
  if (context === "signUp") {
    const [t, p, c] = DOCS.signUp;
    return (
      <p className="text-xs leading-relaxed text-[var(--color-ink)]/70">
        By creating an account you agree to our <DocLink {...t} />, <DocLink {...p} /> and{" "}
        <DocLink {...c} />.
      </p>
    );
  }
  const [b, c] = DOCS.checkout;
  return (
    <p className="text-xs leading-relaxed text-[var(--color-ink)]/70">
      By booking you accept the <DocLink {...b} /> and the <DocLink {...c} /> for this
      experience.
    </p>
  );
}
