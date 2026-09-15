import Image from "next/image";
import Link from "next/link";
import { Sparkles, Compass, Lightbulb, Users, Utensils, HeartHandshake } from "lucide-react";
import type { Database } from "@/lib/supabase/database.types";

type RegionRow = Database["public"]["Tables"]["regions"]["Row"];

// Static curated arrangement mapped to this repo's real family slugs (not a
// data claim - a routing convenience, same as the mood grid already used on
// /explore). No counts shown here; families.ts already knows which ones are
// non-empty and BrowseByExperience handles that separately.
const MOODS = [
  { title: "Relax", desc: "Slow down and recharge", family: "mind-soul", icon: Sparkles },
  { title: "Explore", desc: "See somewhere new", family: "trips-tours", icon: Compass },
  { title: "Learn", desc: "Culture, crafts & skills", family: "live-like-a-local", icon: Lightbulb },
  { title: "Connect", desc: "Meet people & communities", family: "meet-people", icon: Users },
  { title: "Taste", desc: "Discover local food", family: "live-like-a-local", icon: Utensils },
  { title: "Help", desc: "Make a local impact", family: "give-back", icon: HeartHandshake },
];

// Ported from ExploreExperienceShowcase's mood grid + location grid (source
// design). Locations bind to the real `regions` table with real
// cover_image_url - the source's per-region experience counts ("24
// Experiences", "38 Experiences") were fabricated with no backing query and
// are not carried over. Server component - hover states are plain CSS
// (Lighthouse mobile performance budget, P4).
export function MoodAndLocation({ regions }: { regions: RegionRow[] }) {
  return (
    <section className="marketing bg-[var(--m-canvas)] px-4 py-20 lg:px-6">
      <div className="mx-auto max-w-6xl">
        <div className="mb-8 text-left">
          <h2 className="font-m-serif text-2xl font-bold tracking-tight text-[var(--m-forest)] sm:text-3xl">
            Explore by mood
          </h2>
          <p className="mt-1 text-sm font-light text-[var(--m-ink-muted)]">Start with how you want to feel</p>
        </div>

        <div className="mb-16 grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-6">
          {MOODS.map((mood) => {
            const Icon = mood.icon;
            return (
              <Link
                key={mood.title}
                href={`/search?family=${mood.family}`}
                className="group flex flex-col items-start gap-3 rounded-2xl border border-black/[0.06] bg-[var(--m-canvas-pure)] p-5 transition-all duration-300 hover:-translate-y-1.5 hover:shadow-[var(--m-shadow-premium)]"
              >
                <div className="rounded-2xl border border-black/[0.08] bg-[var(--m-sage-light)] p-3 text-[var(--m-forest)] transition-transform duration-300 group-hover:-rotate-6 group-hover:scale-110">
                  <Icon className="h-5 w-5" />
                </div>
                <div>
                  <h3 className="font-m-serif text-sm font-bold text-[var(--m-forest)]">{mood.title}</h3>
                  <p className="mt-0.5 text-[11px] font-light leading-tight text-[var(--m-ink-muted)]">
                    {mood.desc}
                  </p>
                </div>
              </Link>
            );
          })}
        </div>

        <div className="border-t border-black/[0.06] pt-10">
          <div className="mb-8 text-left">
            <h2 className="font-m-serif text-2xl font-bold tracking-tight text-[var(--m-forest)] sm:text-3xl">
              Explore by location
            </h2>
            <p className="mt-1 text-sm font-light text-[var(--m-ink-muted)]">
              Cities, villages, valleys, and wild places across Nepal
            </p>
          </div>

          <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
            {regions.map((region) => (
              <Link
                key={region.id}
                href={`/search?region=${region.slug}`}
                className="group relative flex h-56 flex-col justify-end overflow-hidden rounded-[24px] bg-[var(--m-forest-dark)] shadow-[var(--m-shadow-premium-sm)] transition-all duration-300 hover:-translate-y-1.5 hover:shadow-[var(--m-shadow-premium-lg)]"
              >
                {region.cover_image_url ? (
                  <Image
                    src={region.cover_image_url}
                    alt=""
                    fill
                    sizes="(max-width: 1024px) 50vw, 25vw"
                    className="object-cover opacity-75 transition-all duration-700 group-hover:scale-110 group-hover:opacity-90"
                  />
                ) : null}
                <div className="absolute inset-0 bg-gradient-to-t from-black/90 via-black/40 to-transparent" />
                <div className="relative z-10 p-5">
                  <div className="flex items-baseline gap-2">
                    <h3 className="font-m-serif text-lg font-bold text-white drop-shadow group-hover:text-[var(--m-gold-light)]">
                      {region.name_en}
                    </h3>
                    {region.name_ne && <span className="text-xs text-white/60">{region.name_ne}</span>}
                  </div>
                </div>
              </Link>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
