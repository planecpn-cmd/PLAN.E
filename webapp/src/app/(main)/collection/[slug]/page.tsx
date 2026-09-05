import type { Metadata } from "next";
import { createClient } from "@/lib/supabase/server";
import { getFamiliesAndCategories } from "@/lib/data/families";
import { buildPresentationMaps, presentExperience } from "@/lib/data/presentation";
import { ExperienceCard, type ExperienceCardData } from "@/components/ui/ExperienceCard";
import { EmptyState } from "@/components/ui/EmptyState";
import type { Experience } from "@/lib/data/experiences";

export const revalidate = 300;

const COLLECTION_META: Record<string, { title: string; description: string }> = {
  recommended: { title: "Recommended for You", description: "Our top-rated experiences across Nepal." },
  trending: { title: "Trending Experiences", description: "What travelers are booking right now." },
  homestays: { title: "Homestays", description: "Stay with a local family across Nepal." },
  "live-like-a-local": { title: "Live Like a Local", description: "Food, homes, villages, culture, and crafts." },
  "adventure-together": { title: "Adventure Together", description: "Outdoor adventures made for sharing." },
  "mind-soul": { title: "Soul & Mind", description: "Wellness, reflection, healing and creativity." },
  "give-back": { title: "Give Back", description: "Community, conservation, and meaningful impact." },
  "trips-tours": { title: "Trips & Tours", description: "Day trips, guided tours, packages, and sightseeing." },
  "meet-people": { title: "Meet People", description: "Connect, socialize, make new friends." },
};

const FAMILY_SLUGS = new Set([
  "live-like-a-local",
  "adventure-together",
  "mind-soul",
  "give-back",
  "trips-tours",
  "meet-people",
]);

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<Metadata> {
  const { slug } = await params;
  const meta = COLLECTION_META[slug] ?? { title: slug, description: "Browse experiences on PLAN E." };
  return {
    title: `${meta.title} — PLAN E`,
    description: meta.description,
    alternates: { canonical: `https://planenepal.com/collection/${slug}` },
  };
}

export default async function CollectionPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const meta = COLLECTION_META[slug] ?? { title: slug.replace(/-/g, " "), description: "Browse experiences on PLAN E." };

  const supabase = await createClient();
  const { categories, families } = await getFamiliesAndCategories();
  let query = supabase.from("experiences").select("*").eq("status", "published");

  if (slug === "recommended" || slug === "trending") {
    query = query.order("rating_avg", { ascending: false }).order("rating_count", { ascending: false });
  } else if (slug === "homestays") {
    const category = categories.find((c) => c.slug === "homestay");
    if (category) query = query.eq("category_id", category.id);
  } else if (FAMILY_SLUGS.has(slug)) {
    const family = families.find((f) => f.slug === slug);
    const categoryIds = family ? categories.filter((c) => c.family_id === family.id).map((c) => c.id) : [];
    if (categoryIds.length > 0) query = query.in("category_id", categoryIds);
  } else {
    const category = categories.find((c) => c.slug === slug);
    if (category) query = query.eq("category_id", category.id);
  }

  const { data } = await query.limit(30);
  const { categoriesById, familiesById } = buildPresentationMaps(categories, families);
  const cards: ExperienceCardData[] = ((data ?? []) as Experience[]).map((e) => {
    const presentation = presentExperience(e, categoriesById, familiesById);
    return {
      slug: e.slug,
      title: e.title,
      locationName: e.location_name,
      coverImageUrl: e.cover_image_url,
      pricePaisa: e.price_paisa,
      ratingAvg: e.rating_avg,
      ratingCount: e.rating_count,
      familyLabel: presentation.familyLabel,
      typeLabel: presentation.typeLabel,
      detailText: presentation.detailText,
    };
  });

  return (
    <div className="mx-auto max-w-4xl px-4 py-8 lg:px-6 lg:py-12">
      <h1 className="font-[family-name:var(--font-display)] text-3xl font-bold capitalize">{meta.title}</h1>
      <p className="mt-1 text-[var(--color-ink)]/70">{meta.description}</p>
      <p className="mt-1 text-sm text-[var(--color-ink)]/70">{cards.length} experiences available</p>

      {cards.length === 0 ? (
        <div className="mt-8">
          <EmptyState title="Nothing here yet" description="Check back soon for more experiences." />
        </div>
      ) : (
        <div className="mt-6 grid grid-cols-1 gap-4 sm:grid-cols-2">
          {cards.map((card) => (
            <ExperienceCard key={card.slug} experience={card} variant="horizontal" />
          ))}
        </div>
      )}
    </div>
  );
}
