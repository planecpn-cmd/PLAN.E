import type { Experience } from "@/lib/data/experiences";
import type { CategoryRow, ExperienceFamilyRow } from "@/lib/data/families";

// Mirrors lib/core/experience_presentation.dart's ExperiencePresentation.from().
export function familySupportsDifficulty(familySlug: string | undefined) {
  return familySlug === "adventure-together";
}

function formatDuration(hours: number | null): string {
  if (!hours) return "";
  if (hours < 24) return `${hours} ${hours === 1 ? "hour" : "hours"}`;
  const days = Math.floor(hours / 24);
  const remaining = hours % 24;
  const dayPart = `${days} ${days === 1 ? "day" : "days"}`;
  if (remaining === 0) return dayPart;
  return `${dayPart} ${remaining} ${remaining === 1 ? "hr" : "hrs"}`;
}

function titleCase(value: string) {
  return value ? value[0].toUpperCase() + value.slice(1) : value;
}

export type ExperiencePresentation = {
  familySlug: string | null;
  familyLabel: string | null;
  typeLabel: string | null;
  detailText: string;
};

export function presentExperience(
  experience: Experience,
  categoriesById: Map<string, CategoryRow>,
  familiesById: Map<string, ExperienceFamilyRow>,
): ExperiencePresentation {
  const category = experience.category_id ? categoriesById.get(experience.category_id) : undefined;
  const family = category?.family_id ? familiesById.get(category.family_id) : undefined;

  const parts = [formatDuration(experience.duration_hours)].filter(Boolean);
  if (familySupportsDifficulty(family?.slug) && experience.difficulty) {
    parts.push(titleCase(experience.difficulty));
  }

  return {
    familySlug: family?.slug ?? null,
    familyLabel: family?.name_en ?? null,
    typeLabel: category?.name_en ?? null,
    detailText: parts.join(" • "),
  };
}

export function buildPresentationMaps(categories: CategoryRow[], families: ExperienceFamilyRow[]) {
  return {
    categoriesById: new Map(categories.map((c) => [c.id, c] as const)),
    familiesById: new Map(families.map((f) => [f.id, f] as const)),
  };
}
