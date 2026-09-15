import Image from "next/image";
import Link from "next/link";
import { formatNpr } from "@/lib/format";
import type { Experience } from "@/lib/data/experiences";

// Ported from PerspectiveCarousel (source design: large photo cards in a
// horizontal rail). Real published experiences, real cover images, real
// prices. No star score shown - this repo's own ExperienceCard already
// established that rule (the underlying number isn't backed by
// anon-readable review rows). The source's CAROUSEL_EXPEDITIONS (invented
// trip names with an invented star score and review total) was not ported.
// Server component - hover lift is plain CSS (Lighthouse mobile
// performance budget, P4).
export function PerspectiveCarousel({ experiences }: { experiences: Experience[] }) {
  return (
    <section className="marketing bg-[var(--m-forest-dark)] px-4 py-20 lg:px-6">
      <div className="mx-auto max-w-6xl">
        <div className="mb-8 text-left">
          <h2 className="font-m-serif text-2xl font-bold tracking-tight text-white sm:text-3xl">
            Where earth meets the infinite sky
          </h2>
          <p className="mt-1 text-sm font-light text-white/60">A closer look at experiences across Nepal</p>
        </div>

        <div className="no-scrollbar -mx-4 flex snap-x gap-5 overflow-x-auto px-4 pb-2 lg:mx-0 lg:grid lg:grid-cols-4 lg:overflow-visible lg:px-0">
          {experiences.map((exp) => (
            <Link
              key={exp.id}
              href={`/experience/${exp.slug}`}
              className="group relative flex h-96 w-72 shrink-0 snap-start flex-col justify-end overflow-hidden rounded-[24px] shadow-[var(--m-shadow-premium)] transition-transform duration-300 hover:-translate-y-1.5 lg:w-auto"
            >
              <Image
                src={exp.cover_image_url}
                alt={exp.title}
                fill
                sizes="(max-width: 1024px) 288px, 25vw"
                className="object-cover transition-transform duration-700 group-hover:scale-110"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-black/90 via-black/30 to-transparent" />
              <div className="relative z-10 p-5">
                {exp.location_name && (
                  <span className="font-mono text-[10px] uppercase tracking-wider text-[var(--m-gold-light)]">
                    {exp.location_name}
                  </span>
                )}
                <h3 className="mt-1 font-m-serif text-lg font-bold text-white drop-shadow">{exp.title}</h3>
                <p className="mt-1 font-m-display text-sm font-semibold text-white/90">
                  {formatNpr(exp.price_paisa)}
                </p>
              </div>
            </Link>
          ))}
        </div>
      </div>
    </section>
  );
}
