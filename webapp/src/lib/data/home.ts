import { createClient } from "@/lib/supabase/server";
import type { Experience } from "@/lib/data/experiences";
import { getFamiliesAndCategories } from "@/lib/data/families";
import { buildPresentationMaps, presentExperience } from "@/lib/data/presentation";
import type { ExperienceCardData } from "@/components/ui/ExperienceCard";

export type HomeFilterSpec = { label: string; categories: string[]; terms: string[] };
export type HomeSectionSpec = {
  slug: string;
  title: string;
  description: string;
  filters: HomeFilterSpec[];
};

// Transcribed from lib/features/home/home_discovery.dart (mobile) for content parity.
export const homeSections: HomeSectionSpec[] = [
  {
    slug: "adventure-together",
    title: "Adventure Together",
    description: "Group trips, shared adventures, new connections",
    filters: [
      { label: "Trek", categories: ["trekking", "hiking"], terms: ["trek", "hike", "hiking"] },
      { label: "Climb", categories: ["climbing"], terms: ["climbing"] },
      { label: "Water", categories: [], terms: ["rafting", "canyoning", "kayaking"] },
      { label: "Wild Escape", categories: ["wildlife"], terms: ["safari", "jungle", "wildlife"] },
      { label: "Sky", categories: [], terms: ["paragliding", "skydiving", "helicopter", "scenic flight"] },
    ],
  },
  {
    slug: "mind-soul",
    title: "Soul & Mind",
    description: "Wellness, reflection, healing and creativity",
    filters: [
      { label: "Yoga", categories: ["yoga"], terms: ["yoga"] },
      { label: "Meditation", categories: ["meditation"], terms: ["meditation", "mindfulness"] },
      { label: "Sound & Healing", categories: [], terms: ["sound healing", "sound bath", "singing bowl"] },
      {
        label: "Creative Workshops",
        categories: ["creative-workshop", "craft-workshop"],
        terms: ["pottery", "art workshop", "craft workshop"],
      },
    ],
  },
  {
    slug: "meet-people",
    title: "Meet People",
    description: "Connect, socialize, make new friends",
    filters: [
      { label: "Social", categories: ["meetup"], terms: ["social", "meetup", "community evening"] },
      { label: "Communities", categories: ["community-event"], terms: ["community night"] },
      {
        label: "Join an Activity",
        categories: ["group-activity", "creative-workshop", "craft-workshop"],
        terms: ["social walk", "group hike"],
      },
      {
        label: "Local Connections",
        categories: ["homestay", "village-stay", "community-event"],
        terms: ["local hosts", "meet residents"],
      },
    ],
  },
  {
    slug: "give-back",
    title: "Give Back",
    description: "Help communities, share and contribute",
    filters: [
      { label: "Community", categories: ["skill-sharing", "volunteer-project"], terms: ["school support"] },
      { label: "Nature & Environment", categories: ["conservation-project"], terms: ["conservation", "clean-up", "cleanup"] },
      { label: "Volunteering", categories: ["volunteering", "volunteer-project"], terms: ["volunteer"] },
    ],
  },
  {
    slug: "live-like-a-local",
    title: "Live Like a Local",
    description: "Local life, traditions and authentic experiences",
    filters: [
      {
        label: "Learn",
        categories: ["craft-workshop", "farm-experience", "food-experience", "skill-sharing"],
        terms: ["cooking", "traditional skills"],
      },
      {
        label: "Culture",
        categories: ["culture", "village-stay", "homestay"],
        terms: ["festival", "heritage", "ceremony"],
      },
    ],
  },
];

function rank(experiences: Experience[]) {
  return [...experiences].sort((a, b) => {
    const rating = b.rating_avg - a.rating_avg;
    if (rating !== 0) return rating;
    return b.rating_count - a.rating_count;
  });
}

function matches(exp: Experience, categorySlug: string | undefined, filter: HomeFilterSpec) {
  const text = `${exp.title} ${exp.summary ?? ""}`.toLowerCase();
  return (categorySlug && filter.categories.includes(categorySlug)) || filter.terms.some((t) => text.includes(t));
}

export type HomeSectionData = {
  slug: string;
  title: string;
  description: string;
  filterResults: { label: string; cards: ExperienceCardData[] }[];
  overview: ExperienceCardData[];
};

export async function getHomeData() {
  const supabase = await createClient();
  const [{ data: experiences }, { categories, families }] = await Promise.all([
    supabase.from("experiences").select("*").eq("status", "published"),
    getFamiliesAndCategories(),
  ]);

  const list = (experiences ?? []) as Experience[];
  const categoryIdToSlug = new Map(categories.map((c) => [c.id, c.slug] as const));
  const { categoriesById, familiesById } = buildPresentationMaps(categories, families);

  // Home's own cards never show the family badge — home_screen.dart's
  // _buildExperienceCard passes typeLabel/detailText but no familyLabel.
  const toCard = (e: Experience): ExperienceCardData => {
    const presentation = presentExperience(e, categoriesById, familiesById);
    return {
      slug: e.slug,
      title: e.title,
      locationName: e.location_name,
      coverImageUrl: e.cover_image_url,
      pricePaisa: e.price_paisa,
      ratingAvg: e.rating_avg,
      ratingCount: e.rating_count,
      typeLabel: presentation.typeLabel,
      detailText: presentation.detailText,
    };
  };

  const happeningThisWeek = rank(list).slice(0, 8).map(toCard);

  const sections: HomeSectionData[] = homeSections.map((section) => {
    const filterResults = section.filters.map((filter) => ({
      label: filter.label,
      cards: rank(list.filter((e) => matches(e, categoryIdToSlug.get(e.category_id ?? ""), filter)))
        .slice(0, 8)
        .map(toCard),
    }));
    const seen = new Set<string>();
    const overview: ExperienceCardData[] = [];
    for (const f of filterResults) {
      const top = f.cards[0];
      if (top && !seen.has(top.slug)) {
        seen.add(top.slug);
        overview.push(top);
      }
    }
    return { ...section, filterResults, overview };
  });

  return { happeningThisWeek, sections };
}
