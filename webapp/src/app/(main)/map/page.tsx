import type { Metadata } from "next";
import { createClient } from "@/lib/supabase/server";
import { MapPageClient } from "@/components/MapPageClient";
import { ExperienceCard, type ExperienceCardData } from "@/components/ui/ExperienceCard";
import type { Experience } from "@/lib/data/experiences";

export const metadata: Metadata = { title: "Map View — PLAN E" };
export const revalidate = 300;

function toCard(e: Experience): ExperienceCardData {
  return {
    slug: e.slug,
    title: e.title,
    locationName: e.location_name,
    coverImageUrl: e.cover_image_url,
    pricePaisa: e.price_paisa,
    ratingAvg: e.rating_avg,
    ratingCount: e.rating_count,
  };
}

export default async function MapPage() {
  const supabase = await createClient();
  const { data } = await supabase
    .from("experiences")
    .select("*")
    .eq("status", "published")
    .not("lat", "is", null)
    .not("lng", "is", null)
    .limit(200);

  const experiences = (data ?? []) as Experience[];

  return (
    <div className="flex h-[calc(100vh-64px)] flex-col lg:flex-row">
      <div className="hidden w-full max-w-sm shrink-0 overflow-y-auto border-r border-[var(--color-border-subtle)] p-4 lg:block">
        <h1 className="mb-3 font-[family-name:var(--font-display)] text-xl font-semibold">
          {experiences.length} experiences on the map
        </h1>
        <div className="space-y-4">
          {experiences.map((e) => (
            <ExperienceCard key={e.id} experience={toCard(e)} variant="horizontal" />
          ))}
        </div>
      </div>
      <div className="flex-1">
        <MapPageClient experiences={experiences} />
      </div>
    </div>
  );
}
