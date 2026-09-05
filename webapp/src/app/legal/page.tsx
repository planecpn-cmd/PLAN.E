import type { Metadata } from "next";
import Link from "next/link";
import { getCurrentLegalDocuments } from "@/lib/data/legal";

export const revalidate = 3600;

export const metadata: Metadata = {
  title: "Legal & Policies — PLAN E",
  description:
    "Terms, privacy, booking, cancellation, refund, payment, grievance, safety and other policies for PLAN E.",
  alternates: { canonical: "https://planenepal.com/legal" },
};

export default async function LegalIndexPage() {
  const docs = await getCurrentLegalDocuments();

  return (
    <div className="mx-auto max-w-[720px] px-6 py-12">
      <h1 className="font-[family-name:var(--font-display)] text-3xl font-bold text-[var(--color-deep)]">
        Legal &amp; Policies
      </h1>
      <p className="mt-2 text-[var(--color-ink)]/70">
        The agreements and policies that govern the use of PLAN E.
      </p>

      {docs.length === 0 ? (
        <p className="mt-8 text-[var(--color-ink)]/70">
          No policies are published yet. Please check back.
        </p>
      ) : (
        <ul className="mt-8 divide-y divide-[var(--color-border-subtle)]">
          {docs.map((doc) => (
            <li key={doc.slug}>
              <Link
                href={`/legal/${doc.slug}`}
                className="flex items-center justify-between gap-4 py-4 hover:text-[var(--color-forest)]"
              >
                <span className="font-medium">{doc.title}</span>
                <span className="shrink-0 text-xs text-[var(--color-ink)]/60">
                  v{doc.version}
                </span>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
