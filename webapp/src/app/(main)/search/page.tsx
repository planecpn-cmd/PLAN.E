import type { Metadata } from "next";
import { searchExperiences, type SearchParams } from "@/lib/data/search";
import { SearchQueryInput } from "@/components/SearchQueryInput";
import { FilterPanel } from "@/components/FilterPanel";
import { MobileFiltersSheet } from "@/components/MobileFiltersSheet";
import { ExperienceCard } from "@/components/ui/ExperienceCard";
import { EmptyState } from "@/components/ui/EmptyState";
import { ErrorState } from "@/components/ui/ErrorState";

export const metadata: Metadata = {
  title: "Search experiences — PLAN E",
  description: "Search and filter experiences across Nepal.",
  alternates: { canonical: "https://planenepal.com/search" },
};

export default async function SearchPage({
  searchParams,
}: {
  searchParams: Promise<SearchParams>;
}) {
  const params = await searchParams;
  const { cards, error, categories, families, regions } = await searchExperiences(params);
  const hasFilters = Object.values(params).some(Boolean);

  return (
    <div className="mx-auto max-w-6xl px-4 py-6 lg:px-6 lg:py-10">
      <div className="flex flex-col gap-3 lg:flex-row lg:items-center">
        <div className="flex-1">
          <SearchQueryInput />
        </div>
        <MobileFiltersSheet categories={categories} families={families} regions={regions} />
      </div>

      <div className="mt-6 grid gap-8 lg:grid-cols-[280px_1fr]">
        <aside className="hidden lg:block">
          <div className="sticky top-20 rounded-[var(--radius-md)] border border-[var(--color-border)] bg-white p-5">
            <FilterPanel categories={categories} families={families} regions={regions} />
          </div>
        </aside>

        <div>
          <div className="mb-4 flex items-center justify-between">
            <h1 className="font-[family-name:var(--font-display)] text-xl font-semibold">
              {cards.length} experience{cards.length === 1 ? "" : "s"} found
            </h1>
          </div>

          {error ? (
            <ErrorState message={error} />
          ) : cards.length === 0 ? (
            <EmptyState
              title="No Experiences Found"
              description={hasFilters ? "Try adjusting or resetting your filters." : "Try a different search."}
            />
          ) : (
            <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3">
              {cards.map((card) => (
                <ExperienceCard key={card.slug} experience={card} />
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
