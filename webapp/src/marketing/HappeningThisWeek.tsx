import Image from "next/image";
import Link from "next/link";
import type { DepartureWithExperience } from "@/lib/data/homepage";

// Ported from HappeningThisWeek (source design). Real open departures
// starting within 7 days, joined to published experiences - sorted by
// departure date, never by a popularity score. Renders nothing when there
// are none (page.tsx only mounts this section when
// getHomepageData().happeningThisWeek is non-null).
export function HappeningThisWeek({ departures }: { departures: DepartureWithExperience[] }) {
  return (
    <section className="marketing bg-[var(--m-canvas-pure)] px-4 py-20 lg:px-6">
      <div className="mx-auto max-w-6xl">
        <div className="mb-8 text-left">
          <h2 className="font-m-serif text-2xl font-bold tracking-tight text-[var(--m-forest)] sm:text-3xl">
            Happening this week
          </h2>
          <p className="mt-1 text-sm font-light text-[var(--m-ink-muted)]">Departures leaving in the next 7 days</p>
        </div>
        <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
          {departures.map((dep) => (
            <Link
              key={`${dep.experienceSlug}-${dep.startDate}`}
              href={`/experience/${dep.experienceSlug}`}
              className="group relative flex h-64 flex-col justify-end overflow-hidden rounded-[20px] shadow-[var(--m-shadow-premium-sm)] transition-shadow hover:shadow-[var(--m-shadow-premium)]"
            >
              <Image
                src={dep.coverImageUrl}
                alt={dep.experienceTitle}
                fill
                sizes="(max-width: 1024px) 50vw, 25vw"
                className="object-cover transition-transform duration-500 group-hover:scale-105"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-black/90 via-black/30 to-transparent" />
              <div className="relative z-10 p-4">
                <span className="rounded-full bg-[var(--m-gold)] px-2.5 py-0.5 font-mono text-[10px] font-bold text-white">
                  {new Date(dep.startDate).toLocaleDateString("en-US", { day: "numeric", month: "short" })}
                </span>
                <h3 className="mt-2 line-clamp-2 font-m-serif text-base font-bold text-white drop-shadow">
                  {dep.experienceTitle}
                </h3>
                <p className="text-xs text-white/70">{dep.spotsLeft} spots left</p>
              </div>
            </Link>
          ))}
        </div>
      </div>
    </section>
  );
}
