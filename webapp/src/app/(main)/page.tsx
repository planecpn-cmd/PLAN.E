import Image from "next/image";
import Link from "next/link";
import { getHomeData } from "@/lib/data/home";
import { SearchBar } from "@/components/SearchBar";
import { SectionHeader } from "@/components/ui/SectionHeader";
import { ContentRail } from "@/components/ui/ContentRail";
import { ExperienceCard } from "@/components/ui/ExperienceCard";
import { HomeCategorySection } from "@/components/HomeCategorySection";
import { Button } from "@/components/ui/Button";

export const revalidate = 300;

export default async function HomePage() {
  const { happeningThisWeek, sections } = await getHomeData();

  return (
    <div>
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

        <div className="absolute inset-x-0 top-0 flex justify-end px-4 pt-4 lg:px-6 lg:pt-5">
          <div className="flex h-9 items-center gap-1.5 rounded-[var(--radius-pill)] bg-[var(--color-forest)] px-3.5 text-sm font-bold text-white">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="var(--color-gold)" strokeWidth="2" aria-hidden="true">
              <path d="M4 8V6a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v2a2 2 0 0 0 0 8v2a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2v-2a2 2 0 0 0 0-8Z" />
            </svg>
            0 pts
          </div>
        </div>

        <div className="absolute inset-x-0 bottom-0 px-4 pb-6 lg:px-6 lg:pb-8">
          <div className="mx-auto max-w-6xl">
            <h1 className="max-w-xl font-[family-name:var(--font-display)] text-2xl font-bold leading-[1.05] text-white [text-shadow:0_2px_12px_rgba(0,0,0,0.6)] lg:text-4xl">
              Discover Nepal
              <br />
              your way.
            </h1>
            <div className="mt-4 max-w-lg">
              <SearchBar />
            </div>
            <div className="mt-3 flex max-w-lg gap-2.5">
              <Link href="/collection/trips-tours" className="flex-1">
                <Button variant="primary" fullWidth>
                  Curated Trips
                </Button>
              </Link>
              <Link href="/ai-planner" className="flex-1">
                <Button variant="secondary" fullWidth className="bg-white">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
                    <path d="M12 2l1.6 5.4L19 9l-5.4 1.6L12 16l-1.6-5.4L5 9l5.4-1.6L12 2Z" />
                  </svg>
                  Plan with AI
                </Button>
              </Link>
            </div>
          </div>
        </div>
      </section>

      <div className="mx-auto max-w-6xl px-4 pb-20 lg:px-6">
        {happeningThisWeek.length > 0 && (
          <section>
            <SectionHeader
              title="Happening This Week"
              subtitle="Experiences happening around Nepal this week"
              actionLabel="See All"
              actionHref="/collection/recommended"
            />
            <ContentRail>
              {happeningThisWeek.map((card, i) => (
                <div key={card.slug} className="w-64 shrink-0 lg:w-auto">
                  <ExperienceCard experience={card} priority={i === 0} />
                </div>
              ))}
            </ContentRail>
          </section>
        )}

        {sections.map((section) => (
          <HomeCategorySection key={section.slug} section={section} />
        ))}
      </div>
    </div>
  );
}
