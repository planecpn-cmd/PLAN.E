import Link from "next/link";
import { experienceMoods } from "@/lib/data/taxonomy";
import { Icon, type IconName } from "@/components/ui/Icon";

const moodIcon: Record<string, IconName> = {
  Relax: "spa",
  Explore: "route",
  Learn: "lightbulb",
  Connect: "people",
  Taste: "restaurant",
  Help: "volunteer",
};

export function MoodGrid() {
  return (
    <div className="grid grid-cols-2 gap-2 lg:grid-cols-3">
      {experienceMoods.map((mood) => (
        <Link
          key={mood.label}
          href={`/search?family=${mood.familySlug}`}
          className="flex min-h-[68px] items-center gap-3 rounded-[var(--radius-md)] border border-[var(--color-border-subtle)] bg-white p-3 transition-colors hover:border-[var(--color-forest)]"
        >
          <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-[var(--color-sage)] text-[var(--color-forest)]">
            <Icon name={moodIcon[mood.label] ?? "route"} size={20} />
          </span>
          <span>
            <span className="block text-sm font-bold">{mood.label}</span>
            <span className="block text-xs text-[var(--color-ink)]/70 line-clamp-2">{mood.subtitle}</span>
          </span>
        </Link>
      ))}
    </div>
  );
}
