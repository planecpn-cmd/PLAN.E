"use client";

import dynamic from "next/dynamic";
import type { Experience } from "@/lib/data/experiences";

const MapView = dynamic(() => import("@/components/MapView").then((m) => m.MapView), {
  ssr: false,
  loading: () => <div className="flex h-full items-center justify-center text-[var(--color-ink)]/70">Loading map…</div>,
});

export function MapPageClient({ experiences }: { experiences: Experience[] }) {
  return <MapView experiences={experiences} />;
}
