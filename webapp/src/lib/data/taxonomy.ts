// Transcribed from lib/widgets/experience_mood_grid.dart (mobile) for content
// parity. Moods have no DB table in either client — this hardcoded list is
// the real source of truth on mobile too.

export type ExperienceMood = {
  label: string;
  subtitle: string;
  familySlug: string;
};

export const experienceMoods: ExperienceMood[] = [
  { label: "Relax", subtitle: "Slow down and recharge", familySlug: "mind-soul" },
  { label: "Explore", subtitle: "See somewhere new", familySlug: "trips-tours" },
  { label: "Learn", subtitle: "Culture, crafts and skills", familySlug: "live-like-a-local" },
  { label: "Connect", subtitle: "Meet people and communities", familySlug: "meet-people" },
  { label: "Taste", subtitle: "Discover local food", familySlug: "live-like-a-local" },
  { label: "Help", subtitle: "Make a local impact", familySlug: "give-back" },
];
