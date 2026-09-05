import { createClient } from "@/lib/supabase/server";
import type { Database } from "@/lib/supabase/database.types";

export type Experience = Database["public"]["Tables"]["experiences"]["Row"];
export type Departure = Database["public"]["Tables"]["experience_departures"]["Row"];
export type ItineraryItem = Database["public"]["Tables"]["itinerary_items"]["Row"];
export type Review = Database["public"]["Tables"]["reviews"]["Row"];

export async function getExperienceBySlug(slug: string) {
  const supabase = await createClient();
  const { data } = await supabase
    .from("experiences")
    .select("*")
    .eq("slug", slug)
    .eq("status", "published")
    .maybeSingle();
  return data as Experience | null;
}

export async function getExperienceExtras(experienceId: string) {
  const supabase = await createClient();
  const [departures, itinerary, reviews] = await Promise.all([
    supabase
      .from("experience_departures")
      .select("*")
      .eq("experience_id", experienceId)
      .eq("status", "open")
      .order("start_date"),
    supabase
      .from("itinerary_items")
      .select("*")
      .eq("experience_id", experienceId)
      .order("day_number")
      .order("sort_order"),
    supabase
      .from("reviews")
      .select("*")
      .eq("experience_id", experienceId)
      .order("created_at", { ascending: false })
      .limit(10),
  ]);

  return {
    departures: (departures.data ?? []) as Departure[],
    itinerary: (itinerary.data ?? []) as ItineraryItem[],
    reviews: (reviews.data ?? []) as Review[],
  };
}

export async function listPublishedExperiences(limit = 24) {
  const supabase = await createClient();
  const { data } = await supabase
    .from("experiences")
    .select("*")
    .eq("status", "published")
    .order("rating_avg", { ascending: false })
    .limit(limit);
  return (data ?? []) as Experience[];
}
