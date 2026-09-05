"use client";

import { useEffect, useRef, useState } from "react";
import { useRouter, useSearchParams, usePathname } from "next/navigation";
import { Icon } from "@/components/ui/Icon";

export function SearchQueryInput() {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const [value, setValue] = useState(searchParams.get("q") ?? "");
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    if (timer.current) clearTimeout(timer.current);
    timer.current = setTimeout(() => {
      const params = new URLSearchParams(searchParams.toString());
      if (value) params.set("q", value);
      else params.delete("q");
      router.push(`${pathname}?${params.toString()}`);
      // eslint-disable-next-line react-hooks/exhaustive-deps
    }, 350);
    return () => {
      if (timer.current) clearTimeout(timer.current);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [value]);

  return (
    <div className="flex items-center gap-2 rounded-[var(--radius-pill)] border border-[var(--color-border)] bg-white px-4 py-3">
      <Icon name="search" className="shrink-0 text-[var(--color-ink)]/70" />
      <input
        value={value}
        onChange={(e) => setValue(e.target.value)}
        placeholder="Search experiences, places, or activities..."
        aria-label="Search experiences"
        className="w-full bg-transparent outline-none placeholder:text-[var(--color-ink)]/70"
      />
    </div>
  );
}
