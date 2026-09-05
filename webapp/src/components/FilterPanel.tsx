"use client";

import { useRouter, useSearchParams, usePathname } from "next/navigation";
import { ChipPill } from "@/components/ui/ChipPill";
import { Button } from "@/components/ui/Button";

const SORTS = [
  { value: "", label: "Relevance" },
  { value: "rating", label: "Highest Rated" },
  { value: "price_asc", label: "Price Low→High" },
  { value: "price_desc", label: "Price High→Low" },
  { value: "duration", label: "Duration: Shortest" },
  { value: "newest", label: "Newest" },
];

const DIFFICULTIES = [
  { value: "", label: "Any" },
  { value: "easy", label: "Easy" },
  { value: "moderate", label: "Moderate" },
  { value: "challenging", label: "Challenging" },
  { value: "strenuous", label: "Strenuous" },
];

const DURATIONS = [
  { value: "", label: "Any" },
  { value: "2h", label: "Up to 2 hours" },
  { value: "half", label: "Half day" },
  { value: "full", label: "Full day" },
  { value: "weekend", label: "Weekend" },
  { value: "3days", label: "Up to 3 days" },
];

export function FilterPanel({
  categories,
  families,
  regions,
  onApply,
}: {
  categories: { slug: string; name_en: string }[];
  families: { slug: string; name_en: string }[];
  regions: { slug: string; name_en: string }[];
  onApply?: () => void;
}) {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();

  function setParam(key: string, value: string) {
    const params = new URLSearchParams(searchParams.toString());
    if (value) params.set(key, value);
    else params.delete(key);
    router.push(`${pathname}?${params.toString()}`);
    onApply?.();
  }

  function resetAll() {
    const params = new URLSearchParams();
    const q = searchParams.get("q");
    if (q) params.set("q", q);
    router.push(`${pathname}?${params.toString()}`);
    onApply?.();
  }

  const current = (key: string) => searchParams.get(key) ?? "";

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h2 className="font-[family-name:var(--font-display)] text-lg font-semibold">Filter & Sort</h2>
        <button onClick={resetAll} className="text-sm font-medium text-[var(--color-error)]">
          Reset All
        </button>
      </div>

      <Facet label="Sort By">
        {SORTS.map((s) => (
          <ChipPill key={s.value} active={current("sort") === s.value} onClick={() => setParam("sort", s.value)}>
            {s.label}
          </ChipPill>
        ))}
      </Facet>

      <Facet label="Experience family">
        <ChipPill active={!current("family")} onClick={() => setParam("family", "")}>
          Any
        </ChipPill>
        {families.map((f) => (
          <ChipPill key={f.slug} active={current("family") === f.slug} onClick={() => setParam("family", f.slug)}>
            {f.name_en}
          </ChipPill>
        ))}
      </Facet>

      <Facet label="Difficulty level">
        {DIFFICULTIES.map((d) => (
          <ChipPill key={d.value} active={current("difficulty") === d.value} onClick={() => setParam("difficulty", d.value)}>
            {d.label}
          </ChipPill>
        ))}
      </Facet>

      <div>
        <p className="mb-2 text-sm font-semibold text-[var(--color-ink)]/70">Price Range (NPR)</p>
        <div className="flex gap-2">
          <input
            type="number"
            placeholder="Min"
            defaultValue={current("min_price")}
            onBlur={(e) => setParam("min_price", e.target.value)}
            className="w-full rounded-[var(--radius-sm)] border border-[var(--color-border)] px-3 py-2 text-sm"
          />
          <input
            type="number"
            placeholder="Max"
            defaultValue={current("max_price")}
            onBlur={(e) => setParam("max_price", e.target.value)}
            className="w-full rounded-[var(--radius-sm)] border border-[var(--color-border)] px-3 py-2 text-sm"
          />
        </div>
      </div>

      <Facet label="Duration">
        {DURATIONS.map((d) => (
          <ChipPill key={d.value} active={current("duration") === d.value} onClick={() => setParam("duration", d.value)}>
            {d.label}
          </ChipPill>
        ))}
      </Facet>

      <Facet label="Experience type">
        <ChipPill active={!current("category")} onClick={() => setParam("category", "")}>
          Any
        </ChipPill>
        {categories.map((c) => (
          <ChipPill key={c.slug} active={current("category") === c.slug} onClick={() => setParam("category", c.slug)}>
            {c.name_en}
          </ChipPill>
        ))}
      </Facet>

      <Facet label="Region">
        <ChipPill active={!current("region")} onClick={() => setParam("region", "")}>
          Any
        </ChipPill>
        {regions.map((r) => (
          <ChipPill key={r.slug} active={current("region") === r.slug} onClick={() => setParam("region", r.slug)}>
            {r.name_en}
          </ChipPill>
        ))}
      </Facet>

      <Button variant="primary" fullWidth onClick={() => onApply?.()} className="lg:hidden">
        Apply Filters
      </Button>
    </div>
  );
}

function Facet({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div>
      <p className="mb-2 text-sm font-semibold text-[var(--color-ink)]/70">{label}</p>
      <div className="flex flex-wrap gap-2">{children}</div>
    </div>
  );
}
