import Image from "next/image";
import Link from "next/link";
import type { Metadata } from "next";
import { createClient } from "@/lib/supabase/server";
import { getFamiliesAndCategories } from "@/lib/data/families";
import { SearchBar } from "@/components/SearchBar";
import { SectionHeader } from "@/components/ui/SectionHeader";
import { FamilyTile } from "@/components/ui/FamilyTile";
import { MoodGrid } from "@/components/ui/MoodGrid";
import { Icon, type IconName } from "@/components/ui/Icon";

export const revalidate = 300;

export const metadata: Metadata = {
  title: "Explore Nepal experiences — PLAN E",
  description: "Browse experiences across Nepal by type, mood, and region.",
};

// Matches ExploreScreen._regionIcon() exactly.
function regionIcon(slug: string): IconName {
  switch (slug) {
    case "everest":
    case "manaslu":
    case "kanchenjunga":
      return "terrain";
    case "annapurna":
    case "langtang":
      return "terrain";
    case "mustang":
      return "bank";
    case "chitwan":
      return "forest";
    case "pokhara":
    case "rara":
      return "water";
    case "kathmandu":
      return "temple";
    default:
      return "mapPin";
  }
}

export default async function ExplorePage() {
  const supabase = await createClient();
  const [{ data: regions }, { families }] = await Promise.all([
    supabase.from("regions").select("id, slug, name_en, name_ne, cover_image_url").order("sort_order"),
    getFamiliesAndCategories(),
  ]);

  return (
    <div>
      {/* Title + search float over the top of the photo; the dark scrim
          only covers that band and clears by the time the photo fades to
          ivory at the very bottom. */}
      <section className="relative h-44 overflow-hidden lg:h-52">
        <Image
          src="/brand/explore-hero.webp"
          alt=""
          fill
          priority
          sizes="100vw"
          className="object-cover"
          style={{ objectPosition: "50% 35%" }}
        />
        <div
          className="absolute inset-0"
          style={{
            background:
              "linear-gradient(to bottom, rgba(0,0,0,0.65) 0%, rgba(0,0,0,0.4) 30%, rgba(0,0,0,0) 47%, var(--color-ivory) 100%)",
          }}
        />
        <div className="relative mx-auto max-w-6xl px-4 pt-6 lg:px-6 lg:pt-8">
          <h1 className="font-[family-name:var(--font-display)] text-2xl font-bold text-white [text-shadow:0_2px_8px_rgba(0,0,0,0.5)] lg:text-3xl">
            Explore
          </h1>
          <div className="mt-3">
            <SearchBar placeholder="Search experiences, places, or activities..." />
          </div>
        </div>
      </section>

      <div className="mx-auto max-w-6xl px-4 pb-16 lg:px-6">
        <section className="mt-3">
          <div className="flex items-end justify-between gap-4">
            <div>
              <h2 className="font-[family-name:var(--font-display)] text-xl font-semibold lg:text-2xl">
                Browse by experience
              </h2>
              <p className="mt-1 text-sm text-[var(--color-ink)]/60">Choose the kind of day you want to have</p>
            </div>
            <Link href="/search" className="shrink-0 text-sm font-semibold text-[var(--color-forest)] hover:underline">
              All filters
            </Link>
          </div>
          <div className="mt-4 grid grid-cols-2 gap-3 lg:grid-cols-3">
            {families.map((family) => (
              <FamilyTile key={family.slug} family={family} />
            ))}
          </div>
        </section>

        <section className="mt-10">
          <SectionHeader title="Explore by mood" subtitle="Start with how you want to feel" />
          <div className="mt-4">
            <MoodGrid />
          </div>
        </section>

        <section className="mt-10">
          <SectionHeader title="Explore by location" subtitle="Cities, villages, valleys, and wild places" actionLabel="See All" actionHref="/search" />
          <div className="mt-4 flex gap-3 overflow-x-auto pb-2 lg:grid lg:grid-cols-5 lg:overflow-visible">
            {(regions ?? []).map((region) => (
              <Link
                key={region.id}
                href={`/search?region=${region.slug}`}
                className="relative flex h-28 w-40 shrink-0 flex-col justify-end overflow-hidden rounded-[var(--radius-lg)] bg-gradient-to-br from-[var(--color-forest)] to-[var(--color-deep)] p-3 shadow-[0_5px_10px_rgba(0,0,0,0.1)] lg:w-auto"
              >
                <Icon
                  name={regionIcon(region.slug)}
                  size={76}
                  className="pointer-events-none absolute -bottom-3 -right-3 text-white/10"
                />
                <span className="relative font-[family-name:var(--font-display)] font-bold text-white">
                  {region.name_en}
                </span>
                <span className="relative text-[11px] text-[var(--color-sage)]">{region.name_ne}</span>
              </Link>
            ))}
          </div>
        </section>

        <div className="mt-10">
          <Link
            href="/map"
            className="inline-flex items-center gap-2 rounded-[var(--radius-pill)] border border-[var(--color-border)] bg-white px-4 py-2 text-sm font-semibold text-[var(--color-forest)] hover:bg-[var(--color-sage)]"
          >
            Map View
          </Link>
        </div>
      </div>
    </div>
  );
}
