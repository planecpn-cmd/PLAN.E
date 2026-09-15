import Link from "next/link";
import type { Metadata } from "next";
import { getHomepageData, isSectionEnabled } from "@/lib/data/homepage";
import { Button } from "@/components/ui/Button";
import { Hero } from "@/marketing/Hero";
import { BrandManifesto } from "@/marketing/BrandManifesto";
import { BrowseByExperience } from "@/marketing/BrowseByExperience";
import { MoodAndLocation } from "@/marketing/MoodAndLocation";
import { PerspectiveCarousel } from "@/marketing/PerspectiveCarousel";
import { HappeningThisWeek } from "@/marketing/HappeningThisWeek";
import { PlatformBridge } from "@/marketing/PlatformBridge";
import { WhyPlanE } from "@/marketing/WhyPlanE";
import { SafetyAndPolicies } from "@/marketing/SafetyAndPolicies";
import { FaqSection } from "@/marketing/FaqSection";

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

// WebSite + Organization only, no aggregateRating - same reasoning as
// experience/[slug]'s JSON-LD (AUDIT.md (b)): nothing here is backed by
// anon-readable review rows, so nothing rating-shaped is claimed.
const jsonLd = [
  {
    "@context": "https://schema.org",
    "@type": "WebSite",
    name: "PLAN E",
    url: "https://planenepal.com",
    description: DESCRIPTION,
  },
  {
    "@context": "https://schema.org",
    "@type": "Organization",
    name: "PLAN E",
    url: "https://planenepal.com",
  },
];

export default async function HomePage() {
  const { families, regions, featuredExperiences, happeningThisWeek } = await getHomepageData();

  return (
    <div>
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />

      {isSectionEnabled("hero") && <Hero />}
      {isSectionEnabled("brand_proposition") && <BrandManifesto />}
      {isSectionEnabled("families") && families && <BrowseByExperience families={families} />}
      {isSectionEnabled("mood_and_location") && regions && <MoodAndLocation regions={regions} />}
      {isSectionEnabled("featured_experiences") && featuredExperiences && (
        <PerspectiveCarousel experiences={featuredExperiences} />
      )}
      {isSectionEnabled("happening_this_week") && happeningThisWeek && (
        <HappeningThisWeek departures={happeningThisWeek} />
      )}
      {isSectionEnabled("platform_bridge") && <PlatformBridge />}
      {isSectionEnabled("why_plan_e") && <WhyPlanE />}
      {isSectionEnabled("safety_and_policies") && <SafetyAndPolicies />}
      {isSectionEnabled("faq") && <FaqSection />}

      {isSectionEnabled("host_cta") && (
        <section className="marketing bg-[var(--m-canvas-pure)] px-4 pb-14 text-center lg:px-6 lg:pb-20">
          <p className="font-m-serif text-2xl font-bold leading-tight text-[var(--m-forest)] lg:text-3xl">
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
        <section className="marketing bg-[var(--m-canvas-pure)] px-4 pb-14 text-center lg:px-6 lg:pb-20">
          <p className="font-m-serif text-2xl font-bold leading-tight text-[var(--m-forest)] lg:text-3xl">
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
