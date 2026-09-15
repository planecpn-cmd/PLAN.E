import Image from "next/image";
import Link from "next/link";
import type { Metadata } from "next";
import { getHomepageData, isSectionEnabled } from "@/lib/data/homepage";
import { SearchBar } from "@/components/SearchBar";
import { SectionHeader } from "@/components/ui/SectionHeader";
import { FamilyTile } from "@/components/ui/FamilyTile";
import { Button } from "@/components/ui/Button";

export const revalidate = 300;

const TITLE = "PLAN E — Discover experiences across Nepal";
const DESCRIPTION = "Book treks, homestays, and cultural experiences across Nepal.";

export const metadata: Metadata = {
  title: TITLE,
  description: DESCRIPTION,
  alternates: { canonical: "/" },
  openGraph: {
    title: TITLE,
    description: DESCRIPTION,
    url: "/",
    type: "website",
    images: [{ url: "/brand/home-hero.webp" }],
  },
  twitter: {
    card: "summary_large_image",
    title: TITLE,
    description: DESCRIPTION,
    images: ["/brand/home-hero.webp"],
  },
};

// No aggregateRating - same reasoning as experience/[slug]'s JSON-LD
// (AUDIT.md (b)): rating_count is not backed by anon-readable review rows.
const jsonLd = {
  "@context": "https://schema.org",
  "@type": "WebSite",
  name: "PLAN E",
  url: "https://planenepal.com",
  description: DESCRIPTION,
};

export default async function HomePage() {
  const { families } = await getHomepageData();

  return (
    <div>
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />
      {isSectionEnabled("hero") && (
        <section className="relative h-[300px] overflow-hidden lg:h-[340px]">
          <Image
            src="/brand/home-hero.webp"
            alt="Travellers hiking a mountain trail in Nepal"
            fill
            priority
            sizes="100vw"
            className="object-cover object-left"
          />
          <div
            className="absolute inset-0"
            style={{
              background:
                "linear-gradient(to bottom, rgba(0,0,0,0.55) 0%, rgba(0,0,0,0.15) 22%, rgba(0,22,15,0.72) 78%, var(--color-ivory) 100%)",
            }}
          />

          <div className="absolute inset-x-0 bottom-0 px-4 pb-6 lg:px-6 lg:pb-8">
            <div className="mx-auto max-w-6xl">
              <h1 className="max-w-xl font-[family-name:var(--font-display)] text-2xl font-bold leading-[1.05] text-white [text-shadow:0_2px_12px_rgba(0,0,0,0.6)] lg:text-4xl">
                Find your kind of Nepal.
              </h1>
              <p className="mt-2 max-w-lg text-sm text-white/90 [text-shadow:0_1px_8px_rgba(0,0,0,0.5)] lg:text-base">
                Adventure, culture, people, wellness and experiences worth remembering - all across Nepal.
              </p>
              <div className="mt-4 max-w-lg">
                <SearchBar />
              </div>
            </div>
          </div>
        </section>
      )}

      {isSectionEnabled("brand_proposition") && (
        <section className="mx-auto max-w-3xl px-4 py-14 text-center lg:px-6 lg:py-20">
          <p className="font-[family-name:var(--font-display)] text-2xl font-bold leading-tight text-[var(--color-ink)] lg:text-3xl">
            Nepal isn&apos;t one kind of experience.
          </p>
          <p className="mt-2 font-[family-name:var(--font-display)] text-2xl font-bold leading-tight text-[var(--color-forest)] lg:text-3xl">
            Neither are you.
          </p>
        </section>
      )}

      {isSectionEnabled("families") && families && (
        <section className="mx-auto max-w-6xl px-4 pb-14 lg:px-6 lg:pb-20">
          <SectionHeader title="Browse by experience" subtitle="Choose the kind of day you want to have" />
          <div className="mt-4 grid grid-cols-2 gap-3 lg:grid-cols-3">
            {families.map((family) => (
              <FamilyTile key={family.slug} family={family} />
            ))}
          </div>
        </section>
      )}

      {isSectionEnabled("host_cta") && (
        <section className="mx-auto max-w-3xl px-4 pb-14 text-center lg:px-6 lg:pb-20">
          <p className="font-[family-name:var(--font-display)] text-2xl font-bold leading-tight text-[var(--color-ink)] lg:text-3xl">
            Know something worth sharing?
          </p>
          <div className="mt-5 flex justify-center">
            <Link href="/host">
              <Button variant="secondary">Become a host</Button>
            </Link>
          </div>
        </section>
      )}

      {isSectionEnabled("final_cta") && (
        <section className="mx-auto max-w-3xl px-4 pb-14 text-center lg:px-6 lg:pb-20">
          <p className="font-[family-name:var(--font-display)] text-2xl font-bold leading-tight text-[var(--color-ink)] lg:text-3xl">
            So, what&apos;s your PLAN E?
          </p>
          <div className="mt-5 flex justify-center">
            <Link href="/explore">
              <Button variant="primary">Get Started</Button>
            </Link>
          </div>
        </section>
      )}
    </div>
  );
}
