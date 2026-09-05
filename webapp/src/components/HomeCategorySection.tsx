"use client";

import { useState } from "react";
import { SectionHeader } from "@/components/ui/SectionHeader";
import { ChipPill } from "@/components/ui/ChipPill";
import { ContentRail } from "@/components/ui/ContentRail";
import { ExperienceCard } from "@/components/ui/ExperienceCard";
import type { HomeSectionData } from "@/lib/data/home";

export function HomeCategorySection({ section }: { section: HomeSectionData }) {
  const [active, setActive] = useState<string | null>(null);

  if (section.overview.length === 0) return null;

  const visible = active ? section.filterResults.find((f) => f.label === active)?.cards ?? [] : section.overview;

  return (
    <section className="mt-12">
      <SectionHeader title={section.title} subtitle={section.description} actionLabel="See All" actionHref={`/search?family=${section.slug}`} />

      <div className="mt-4 flex gap-2 overflow-x-auto pb-1">
        <ChipPill active={active === null} onClick={() => setActive(null)}>
          Overview
        </ChipPill>
        {section.filterResults
          .filter((f) => f.cards.length > 0)
          .map((f) => (
            <ChipPill key={f.label} active={active === f.label} onClick={() => setActive(f.label)}>
              {f.label}
            </ChipPill>
          ))}
      </div>

      <ContentRail>
        {visible.map((card) => (
          <div key={card.slug} className="w-64 shrink-0 lg:w-auto">
            <ExperienceCard experience={card} />
          </div>
        ))}
      </ContentRail>
    </section>
  );
}
