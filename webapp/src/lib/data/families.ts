import { createClient } from "@/lib/supabase/server";

export type ExperienceFamilyRow = {
  id: string;
  slug: string;
  name_en: string;
  name_ne: string;
  description: string | null;
  cover_image_url: string | null;
};

export type CategoryRow = { id: string; slug: string; name_en: string; family_id: string | null };

// Matches lib/widgets/experience_family_card.dart's `_compactSubtitle` getter exactly.
export function familyCompactSubtitle(slug: string, fallback: string): string {
  const map: Record<string, string> = {
    "trips-tours": "Tours, trips & packages",
    "adventure-together": "Shared outdoor challenges",
    "live-like-a-local": "Food, culture & homestays",
    "mind-soul": "Wellness & creative escapes",
    "meet-people": "Activities, events & community",
    "give-back": "Volunteering & local impact",
  };
  return map[slug] ?? fallback;
}

export async function getFamiliesAndCategories() {
  const supabase = await createClient();
  const [{ data: families }, { data: categories }] = await Promise.all([
    supabase.from("experience_families").select("id, slug, name_en, name_ne, description, cover_image_url").order("sort_order"),
    supabase.from("categories").select("id, slug, name_en, family_id").order("sort_order"),
  ]);
  return {
    families: (families ?? []) as ExperienceFamilyRow[],
    categories: (categories ?? []) as CategoryRow[],
  };
}
