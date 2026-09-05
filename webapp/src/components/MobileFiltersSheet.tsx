"use client";

import { useState } from "react";
import { Icon } from "@/components/ui/Icon";
import { FilterPanel } from "@/components/FilterPanel";

export function MobileFiltersSheet({
  categories,
  families,
  regions,
}: {
  categories: { slug: string; name_en: string }[];
  families: { slug: string; name_en: string }[];
  regions: { slug: string; name_en: string }[];
}) {
  const [open, setOpen] = useState(false);

  return (
    <div className="lg:hidden">
      <button
        onClick={() => setOpen(true)}
        className="flex items-center gap-2 rounded-[var(--radius-pill)] border border-[var(--color-border)] bg-white px-4 py-2 text-sm font-semibold text-[var(--color-forest)]"
      >
        Filters
      </button>

      {open && (
        <div className="fixed inset-0 z-50 flex items-end bg-black/40" role="dialog" aria-modal="true">
          <div className="max-h-[85vh] w-full overflow-y-auto rounded-t-[var(--radius-lg)] bg-white p-6">
            <div className="mb-4 flex justify-end">
              <button onClick={() => setOpen(false)} aria-label="Close filters">
                <Icon name="close" />
              </button>
            </div>
            <FilterPanel categories={categories} families={families} regions={regions} onApply={() => setOpen(false)} />
          </div>
        </div>
      )}
    </div>
  );
}
