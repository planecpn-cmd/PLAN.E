"use client";

import Image from "next/image";
import Link from "next/link";
import { RatingStars } from "./RatingStars";
import { formatNpr } from "@/lib/format";

export interface ExperienceCardData {
  slug: string;
  title: string;
  locationName: string | null;
  coverImageUrl: string;
  pricePaisa: number;
  ratingAvg: number;
  ratingCount: number;
  familyLabel?: string | null;
  typeLabel?: string | null;
  detailText?: string | null;
}

// Matches lib/widgets/experience_card.dart: title above location, a dark
// family badge over the top-left of the photo, bookmark top-right, and a
// "type • detail" meta line in forest — not the mobile app's own inline
// "/ person" text, which the card never renders (only the detail page does).
export function ExperienceCard({
  experience,
  variant = "poster",
  saved,
  onToggleSave,
  priority,
}: {
  experience: ExperienceCardData;
  variant?: "poster" | "horizontal";
  saved?: boolean;
  onToggleSave?: () => void;
  priority?: boolean;
}) {
  const horizontal = variant === "horizontal";
  const meta = [experience.typeLabel, experience.detailText].filter(Boolean).join(" • ");

  return (
    <div
      className={`group relative overflow-hidden rounded-[var(--radius-md)] border border-[var(--color-border-subtle)] bg-[var(--color-card)] transition-shadow duration-200 hover:shadow-[0_8px_24px_rgba(1,37,28,0.08)] ${
        horizontal ? "flex w-full" : ""
      }`}
    >
      <Link href={`/experience/${experience.slug}`} className={horizontal ? "flex w-full" : "block"}>
        <div
          className={`relative shrink-0 overflow-hidden bg-[var(--color-sage)] ${
            horizontal ? "aspect-square w-32 sm:w-40" : "aspect-[4/3] w-full"
          }`}
        >
          <Image
            src={experience.coverImageUrl}
            alt={experience.title}
            fill
            sizes={horizontal ? "160px" : "(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 25vw"}
            className="object-cover transition duration-300 group-hover:scale-105"
            priority={priority}
            loading={priority ? undefined : "lazy"}
          />
          {experience.familyLabel && (
            <span className="absolute left-2 top-2 rounded-[var(--radius-sm)] bg-[var(--color-deep)]/85 px-2 py-1 text-[10px] font-semibold uppercase tracking-wide text-[var(--color-ivory)]">
              {experience.familyLabel}
            </span>
          )}
        </div>
        <div className="flex flex-1 flex-col gap-1 p-3">
          <h3 className="font-[family-name:var(--font-display)] text-base font-bold leading-snug text-[var(--color-ink)] line-clamp-2">
            {experience.title}
          </h3>
          {experience.locationName && (
            <p className="flex items-center gap-1 text-xs text-[var(--color-ink)]/60">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true" className="shrink-0">
                <path d="M12 22s7-7.4 7-12.5A7 7 0 0 0 5 9.5C5 14.6 12 22 12 22Zm0-9a3 3 0 1 0 0-6 3 3 0 0 0 0 6Z" />
              </svg>
              <span className="truncate">{experience.locationName}</span>
            </p>
          )}
          {meta && <p className="truncate text-xs font-semibold text-[var(--color-forest)]">{meta}</p>}
          <div className="mt-1 flex items-center justify-between gap-2">
            {experience.ratingCount > 0 ? (
              <RatingStars rating={experience.ratingAvg} reviewCount={experience.ratingCount} />
            ) : (
              <span />
            )}
            <span className="font-bold text-[var(--color-forest)]">{formatNpr(experience.pricePaisa)}</span>
          </div>
        </div>
      </Link>

      {onToggleSave && (
        <button
          type="button"
          onClick={onToggleSave}
          aria-label={saved ? "Remove from saved" : "Save experience"}
          aria-pressed={saved}
          className="absolute right-1 top-1 z-10 flex h-9 w-9 items-center justify-center rounded-full text-[var(--color-deep)] transition-colors hover:bg-white/70 focus-visible:outline focus-visible:outline-2 focus-visible:outline-[var(--color-gold)]"
        >
          <svg width="20" height="20" viewBox="0 0 24 24" fill={saved ? "var(--color-forest)" : "none"} stroke="currentColor" strokeWidth="2" aria-hidden="true">
            <path d="M6 3h12a1 1 0 0 1 1 1v17l-7-4-7 4V4a1 1 0 0 1 1-1Z" />
          </svg>
        </button>
      )}
    </div>
  );
}
