import Image from "next/image";
import Link from "next/link";
import type { ExperienceFamilyRow } from "@/lib/data/families";
import { familyCompactSubtitle } from "@/lib/data/families";

// Matches lib/widgets/experience_family_card.dart: real cover photo (or a
// sage placeholder if the DB row has none), dark gradient overlay, serif
// title, and the app's own hardcoded compact subtitle per family.
export function FamilyTile({ family }: { family: ExperienceFamilyRow }) {
  return (
    <Link
      href={`/search?family=${family.slug}`}
      className="group relative flex h-36 flex-col justify-end overflow-hidden rounded-[var(--radius-md)] bg-[var(--color-sage)] p-3 text-white transition-transform hover:scale-[1.01]"
    >
      {family.cover_image_url && (
        <Image
          src={family.cover_image_url}
          alt=""
          fill
          sizes="(max-width: 1024px) 50vw, 33vw"
          className="object-cover"
        />
      )}
      <div
        className="absolute inset-0"
        style={{ background: "linear-gradient(to bottom, rgba(0,0,0,0.09) 20%, rgba(0,27,20,0.85) 100%)" }}
      />
      <h3 className="relative font-[family-name:var(--font-display)] text-lg font-bold leading-tight">
        {family.name_en}
      </h3>
      <p className="relative mt-0.5 text-xs font-medium text-[var(--color-sage)]">
        {familyCompactSubtitle(family.slug, family.description ?? "")}
      </p>
    </Link>
  );
}
