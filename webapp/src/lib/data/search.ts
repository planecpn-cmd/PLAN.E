import { createClient } from "@/lib/supabase/server";
import { getFamiliesAndCategories } from "@/lib/data/families";
import { buildPresentationMaps, presentExperience } from "@/lib/data/presentation";
import type { Experience } from "@/lib/data/experiences";
import type { ExperienceCardData } from "@/components/ui/ExperienceCard";

export type SearchParams = {
  q?: string;
  category?: string;
  family?: string;
  region?: string;
  difficulty?: string;
  min_price?: string;
  max_price?: string;
  duration?: string;
  sort?: string;
};

export async function searchExperiences(params: SearchParams) {
  const supabase = await createClient();

  const [{ categories, families }, { data: regions }] = await Promise.all([
    getFamiliesAndCategories(),
    supabase.from("regions").select("id, slug, name_en").order("sort_order"),
  ]);

  let query = supabase.from("experiences").select("*").eq("status", "published");

  if (params.region) {
    const region = (regions ?? []).find((r) => r.slug === params.region);
    if (region) query = query.eq("region_id", region.id);
  }

  if (params.category) {
    const category = categories.find((c) => c.slug === params.category);
    if (category) query = query.eq("category_id", category.id);
  } else if (params.family) {
    // Matches ExperienceTaxonomy.familyFor(): resolve via categories.family_id,
    // the real FK — not a client-side slug guess.
    const family = families.find((f) => f.slug === params.family);
    const categoryIds = family ? categories.filter((c) => c.family_id === family.id).map((c) => c.id) : [];
    if (categoryIds.length > 0) query = query.in("category_id", categoryIds);
  }

  if (params.difficulty) {
    query = query.eq("difficulty", params.difficulty as Experience["difficulty"] & string);
  }
  if (params.min_price) query = query.gte("price_paisa", Number(params.min_price) * 100);
  if (params.max_price) query = query.lte("price_paisa", Number(params.max_price) * 100);
  if (params.duration) {
    const max = { "2h": 2, half: 6, full: 12, weekend: 48, "3days": 72 }[params.duration];
    if (max) query = query.lte("duration_hours", max);
  }
  if (params.q) query = query.textSearch("search_tsv", params.q, { type: "websearch" });

  switch (params.sort) {
    case "rating":
      query = query.order("rating_avg", { ascending: false });
      break;
    case "price_asc":
      query = query.order("price_paisa", { ascending: true });
      break;
    case "price_desc":
      query = query.order("price_paisa", { ascending: false });
      break;
    case "duration":
      query = query.order("duration_hours", { ascending: true });
      break;
    case "newest":
      query = query.order("created_at", { ascending: false });
      break;
    default:
      query = query.order("rating_avg", { ascending: false }).order("rating_count", { ascending: false });
  }

  const { data, error } = await query.limit(48);

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

  return {
    cards,
    error: error?.message ?? null,
    categories,
    families,
    regions: regions ?? [],
  };
}
