"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { Icon } from "@/components/ui/Icon";

export function SearchBar({ placeholder = "What do you want to do?" }: { placeholder?: string }) {
  const router = useRouter();
  const [value, setValue] = useState("");

  function submit(e: React.FormEvent) {
    e.preventDefault();
    router.push(value ? `/search?q=${encodeURIComponent(value)}` : "/search");
  }

  return (
    <form onSubmit={submit} role="search" className="flex w-full max-w-lg items-center gap-2 rounded-[var(--radius-pill)] bg-white px-5 py-3.5 shadow-lg">
      <Icon name="search" className="shrink-0 text-[var(--color-ink)]/70" />
      <input
        value={value}
        onChange={(e) => setValue(e.target.value)}
        placeholder={placeholder}
        aria-label="Search experiences"
        className="w-full bg-transparent text-[var(--color-ink)] outline-none placeholder:text-[var(--color-ink)]/70"
      />
    </form>
  );
}
