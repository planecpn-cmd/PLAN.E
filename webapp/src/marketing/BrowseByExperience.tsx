import Image from "next/image";
import Link from "next/link";
import { ArrowUpRight } from "lucide-react";
import type { FamilyWithCount } from "@/lib/data/homepage";

// Ported from ExploreExperienceShowcase's "Browse by experience" grid
// (source design: full-bleed photo cards, dark vignette, hover lift). Real
// families only - no fifth taxonomy, no fabricated per-family stats
// ('14 Expeditions', '100% TAAN Verified', '4.96/5.0'). Shows the real
// published count instead. Server component - the hover lift is plain CSS,
// not framer-motion (Lighthouse mobile performance budget, P4).
export function BrowseByExperience({ families }: { families: FamilyWithCount[] }) {
  return (
    <section className="marketing bg-[var(--m-canvas-pure)] px-4 py-20 lg:px-6">
      <div className="mx-auto max-w-6xl">
        <div className="mb-8 text-left">
          <h2 className="font-m-serif text-2xl font-bold tracking-tight text-[var(--m-forest)] sm:text-3xl">
            Browse by experience
          </h2>
          <p className="mt-1 text-sm font-light text-[var(--m-ink-muted)]">
            Choose the kind of day you want to have
          </p>
        </div>

        <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {families.map((family) => (
            <Link
              key={family.slug}
              href={`/search?family=${family.slug}`}
              className="group relative flex h-72 flex-col justify-end overflow-hidden rounded-[28px] border border-black/[0.06] shadow-[var(--m-shadow-premium-sm)] transition-all duration-300 hover:-translate-y-1.5 hover:shadow-[var(--m-shadow-premium-lg)] sm:h-80"
            >
              {family.cover_image_url ? (
                <Image
                  src={family.cover_image_url}
                  alt=""
                  fill
                  sizes="(max-width: 1024px) 50vw, 33vw"
                  className="object-cover transition-transform duration-700 group-hover:scale-110"
                />
              ) : (
                <div className="absolute inset-0 bg-[var(--m-sage)]" />
              )}
              <div className="absolute inset-0 bg-gradient-to-t from-black/95 via-black/45 to-black/10" />

              <div className="absolute right-4 top-4 z-10 flex h-9 w-9 items-center justify-center rounded-full bg-white/20 text-white backdrop-blur-md transition-all group-hover:rotate-45 group-hover:bg-[var(--m-gold)] group-hover:text-[var(--m-forest)]">
                <ArrowUpRight className="h-4 w-4" />
              </div>

              <div className="relative z-10 flex flex-col gap-1 p-6">
                <h3 className="font-m-serif text-xl font-bold tracking-wide text-white drop-shadow-md sm:text-2xl">
                  {family.name_en}
                </h3>
                {family.description && (
                  <p className="line-clamp-2 text-sm font-light text-white/85 drop-shadow">{family.description}</p>
                )}
                <span className="mt-2 inline-flex w-fit items-center rounded-full border border-white/15 bg-white/15 px-3 py-1 font-mono text-[11px] font-medium text-white backdrop-blur-md">
                  {family.publishedCount} {family.publishedCount === 1 ? "experience" : "experiences"}
                </span>
              </div>
            </Link>
          ))}
        </div>
      </div>
    </section>
  );
}
