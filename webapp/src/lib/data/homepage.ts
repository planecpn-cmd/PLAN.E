// Single coordinated fetch for the marketing homepage (N2 Foundation).
//
// No section queries Supabase on its own: N3-N9 read their slice of
// getHomepageData()'s result, and the registry below decides what even gets
// fetched. Rule 1 applies here directly - an empty result is `null`, never a
// placeholder, so a section can render nothing instead of inventing content.
//
// This does not replace lib/data/home.ts, which the live homepage still uses
// today. That swap happens when a later node actually rebuilds the page.

import sectionsRegistry from "../../../SECTIONS.json";
import { createClient } from "@/lib/supabase/server";
import { getFamiliesAndCategories, type ExperienceFamilyRow } from "@/lib/data/families";
import { familiesWithPublishedCounts } from "@/lib/data/homepage-helpers.mjs";

export type SectionId =
  | "hero"
  | "brand_proposition"
  | "families"
  | "happening_this_week"
  | "why_plan_e"
  | "app_showcase"
  | "host_cta"
  | "final_cta"
  | "explore_by_feeling"
  | "editorial_story"
  | "destinations_grid"
  | "meet_the_hosts"
  | "ai_planner"
  | "community_proof";

export type SectionConfig = {
  id: SectionId;
  node?: string;
  enabled: boolean;
  data_source?: string;
  omit_if_empty?: boolean;
  note?: string;
  omit_reason?: string;
};

const SECTIONS = sectionsRegistry.sections as SectionConfig[];

export function getSectionConfig(id: SectionId): SectionConfig | undefined {
  return SECTIONS.find((s) => s.id === id);
}

export function isSectionEnabled(id: SectionId): boolean {
  return getSectionConfig(id)?.enabled === true;
}

export type FamilyWithCount = ExperienceFamilyRow & { publishedCount: number };

export type HomepageData = {
  /** SECTIONS.json "families" (N5). null when no family has a published experience. */
  families: FamilyWithCount[] | null;
  /** SECTIONS.json "happening_this_week" (N6) - disabled today, not queried. */
  happeningThisWeek: null;
  /** SECTIONS.json "why_plan_e" (N7) - disabled today, not queried. */
  whyPlanE: null;
  /** SECTIONS.json "app_showcase" (N8) - disabled today, not queried. */
  appShowcase: null;
};

export async function getHomepageData(): Promise<HomepageData> {
  const families = isSectionEnabled("families") ? await getFamiliesWithPublishedCounts() : null;

  return {
    families,
    // Each of these stays null until its SECTIONS.json entry is enabled -
    // see the section's own omit_reason for why it's off today.
    happeningThisWeek: null,
    whyPlanE: null,
    appShowcase: null,
  };
}

async function getFamiliesWithPublishedCounts(): Promise<FamilyWithCount[] | null> {
  const supabase = await createClient();
  const [{ families, categories }, { data: experiences }] = await Promise.all([
    getFamiliesAndCategories(),
    supabase.from("experiences").select("category_id").eq("status", "published"),
  ]);

  return familiesWithPublishedCounts(
    families,
    categories,
    (experiences ?? []) as { category_id: string | null }[],
  ) as FamilyWithCount[] | null;
}
