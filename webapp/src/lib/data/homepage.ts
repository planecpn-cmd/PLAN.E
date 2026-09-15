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
import { listPublishedExperiences, type Experience } from "@/lib/data/experiences";
import type { Database } from "@/lib/supabase/database.types";

type RegionRow = Database["public"]["Tables"]["regions"]["Row"];

export type SectionId =
  | "hero"
  | "brand_proposition"
  | "families"
  | "mood_and_location"
  | "featured_experiences"
  | "happening_this_week"
  | "platform_bridge"
  | "why_plan_e"
  | "safety_and_policies"
  | "faq"
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

export type DepartureWithExperience = {
  experienceSlug: string;
  experienceTitle: string;
  coverImageUrl: string;
  locationName: string | null;
  startDate: string;
  spotsLeft: number;
};

export type HomepageData = {
  /** SECTIONS.json "families" (N5 / M-PORT). null when no family has a published experience. */
  families: FamilyWithCount[] | null;
  /** SECTIONS.json "mood_and_location" (M-PORT). Real regions table, ordered. */
  regions: RegionRow[] | null;
  /** SECTIONS.json "featured_experiences" (M-PORT, PerspectiveCarousel). Real published experiences. */
  featuredExperiences: Experience[] | null;
  /** SECTIONS.json "happening_this_week" (M-PORT). Open departures starting within 7 days. null when none. */
  happeningThisWeek: DepartureWithExperience[] | null;
  /** SECTIONS.json "app_showcase" (N8) - disabled today, not queried. */
  appShowcase: null;
};

export async function getHomepageData(): Promise<HomepageData> {
  const [families, regions, featuredExperiences, happeningThisWeek] = await Promise.all([
    isSectionEnabled("families") ? getFamiliesWithPublishedCounts() : Promise.resolve(null),
    isSectionEnabled("mood_and_location") ? getRegions() : Promise.resolve(null),
    isSectionEnabled("featured_experiences") ? getFeaturedExperiences() : Promise.resolve(null),
    isSectionEnabled("happening_this_week") ? getHappeningThisWeek() : Promise.resolve(null),
  ]);

  return {
    families,
    regions,
    featuredExperiences,
    happeningThisWeek,
    // Stays null until its SECTIONS.json entry is enabled - see omit_reason.
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

async function getRegions(): Promise<RegionRow[] | null> {
  const supabase = await createClient();
  const { data } = await supabase.from("regions").select("*").order("sort_order");
  return data && data.length > 0 ? (data as RegionRow[]) : null;
}

async function getFeaturedExperiences(): Promise<Experience[] | null> {
  const experiences = await listPublishedExperiences(8);
  return experiences.length > 0 ? experiences : null;
}

/** Nepal-local calendar date, matching the gate suite's own nepalDate(). */
function nepalDate(offsetDays = 0): string {
  const d = new Date(Date.now() + offsetDays * 86_400_000);
  return new Intl.DateTimeFormat("en-CA", { timeZone: "Asia/Kathmandu" }).format(d);
}

async function getHappeningThisWeek(): Promise<DepartureWithExperience[] | null> {
  const supabase = await createClient();
  const today = nepalDate();
  const end = nepalDate(6);
  const { data } = await supabase
    .from("experience_departures")
    .select("start_date, spots_left, experiences!inner(slug, title, cover_image_url, location_name, status)")
    .eq("status", "open")
    .gte("start_date", today)
    .lte("start_date", end)
    .eq("experiences.status", "published")
    .order("start_date")
    .limit(8);

  const rows = (data ?? []) as unknown as {
    start_date: string;
    spots_left: number;
    experiences: { slug: string; title: string; cover_image_url: string; location_name: string | null };
  }[];

  const mapped: DepartureWithExperience[] = rows.map((r) => ({
    experienceSlug: r.experiences.slug,
    experienceTitle: r.experiences.title,
    coverImageUrl: r.experiences.cover_image_url,
    locationName: r.experiences.location_name,
    startDate: r.start_date,
    spotsLeft: r.spots_left,
  }));

  return mapped.length > 0 ? mapped : null;
}
