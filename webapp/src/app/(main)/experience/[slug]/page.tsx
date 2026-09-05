import Image from "next/image";
import Link from "next/link";
import { notFound } from "next/navigation";
import type { Metadata } from "next";
import { getExperienceBySlug, getExperienceExtras } from "@/lib/data/experiences";
import { formatNpr } from "@/lib/format";
import { RatingStars } from "@/components/ui/RatingStars";
import { Button } from "@/components/ui/Button";
import { BookmarkButton } from "@/components/BookmarkButton";
import { OrnamentDivider } from "@/components/ui/OrnamentDivider";

export const revalidate = 300;

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<Metadata> {
  const { slug } = await params;
  const experience = await getExperienceBySlug(slug);
  if (!experience) return { title: "Experience not found — PLAN E" };

  const description =
    experience.summary ?? experience.description?.slice(0, 155) ?? "Book this experience with PLAN E.";
  const url = `https://planenepal.com/experience/${experience.slug}`;

  return {
    title: `${experience.title} — PLAN E`,
    description,
    alternates: { canonical: url },
    openGraph: {
      title: experience.title,
      description,
      url,
      images: [{ url: experience.cover_image_url }],
      type: "website",
    },
    twitter: {
      card: "summary_large_image",
      title: experience.title,
      description,
      images: [experience.cover_image_url],
    },
  };
}

function spotsLeftBanner(nextDeparture: { start_date: string; spots_left: number } | undefined) {
  if (!nextDeparture) {
    return (
      <div className="bg-[var(--color-sage)] px-4 py-2.5 text-sm font-medium text-[var(--color-forest)] lg:rounded-t-[var(--radius-md)]">
        ⚡ Instant confirmation
      </div>
    );
  }
  const date = new Date(nextDeparture.start_date).toLocaleDateString("en-US", {
    day: "numeric",
    month: "short",
  });
  const low = nextDeparture.spots_left <= 5;
  return (
    <div
      className={`px-4 py-2.5 text-sm font-semibold lg:rounded-t-[var(--radius-md)] ${
        low ? "bg-[var(--color-warning-container)] text-[var(--color-warning)]" : "bg-[var(--color-success-container)] text-[var(--color-success)]"
      }`}
    >
      {low ? "🔥 " : ""}
      {nextDeparture.spots_left} spots {low ? "LEFT" : "available"} for {date}
    </div>
  );
}

export default async function ExperienceDetailPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const experience = await getExperienceBySlug(slug);
  if (!experience) notFound();

  const { departures, itinerary, reviews } = await getExperienceExtras(experience.id);
  const nextDeparture = departures[0];

  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "Product",
    name: experience.title,
    description: experience.summary ?? experience.description ?? undefined,
    image: [experience.cover_image_url, ...(experience.gallery ?? [])],
    offers: {
      "@type": "Offer",
      priceCurrency: "NPR",
      price: (experience.price_paisa / 100).toFixed(2),
      availability: nextDeparture ? "https://schema.org/InStock" : "https://schema.org/SoldOut",
      url: `https://planenepal.com/experience/${experience.slug}`,
    },
    ...(experience.rating_count > 0
      ? {
          aggregateRating: {
            "@type": "AggregateRating",
            ratingValue: experience.rating_avg,
            reviewCount: experience.rating_count,
          },
        }
      : {}),
  };

  return (
    <div className="mx-auto max-w-6xl px-4 py-6 lg:px-6 lg:py-10">
      {/* eslint-disable-next-line react/no-danger */}
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />

      <div className="grid gap-8 lg:grid-cols-[1fr_360px] lg:items-start">
        <div>
          <div className="relative aspect-[16/10] w-full overflow-hidden rounded-[var(--radius-md)] bg-[var(--color-sage)] lg:aspect-[16/9]">
            <Image
              src={experience.cover_image_url}
              alt={experience.title}
              fill
              sizes="(max-width: 1024px) 100vw, 66vw"
              className="object-cover"
              priority
            />
            <div className="absolute right-3 top-3 flex gap-2">
              <BookmarkButton experienceId={experience.id} />
            </div>
          </div>

          <div className="mt-5">
            <h1 className="font-[family-name:var(--font-display)] text-3xl font-bold text-[var(--color-ink)] lg:text-[40px]">
              {experience.title}
            </h1>
            {experience.location_name && (
              <p className="mt-1.5 flex items-center gap-1.5 text-[var(--color-ink)]/70">
                {experience.location_name}
              </p>
            )}
            {experience.rating_count > 0 && (
              <div className="mt-2">
                <RatingStars rating={experience.rating_avg} reviewCount={experience.rating_count} />
              </div>
            )}
          </div>

          <dl className="mt-6 grid grid-cols-2 gap-4 rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-card)] p-4 text-sm sm:grid-cols-4">
            <Stat label="Duration" value={experience.duration_hours ? `${experience.duration_hours}h` : "—"} />
            <Stat label="Difficulty" value={experience.difficulty ?? "—"} />
            <Stat label="Group size" value={experience.group_size_max ? `Up to ${experience.group_size_max}` : "—"} />
            <Stat label="Min age" value={experience.min_age ? `${experience.min_age}+` : "Any age"} />
          </dl>

          <Section title="About this experience">
            <p className="whitespace-pre-line leading-relaxed text-[var(--color-ink)]/85">
              {experience.description ?? experience.summary}
            </p>
          </Section>

          {experience.included && experience.included.length > 0 && (
            <Section title="What's included">
              <Checklist items={experience.included} tone="success" />
            </Section>
          )}

          {experience.bring_list && experience.bring_list.length > 0 && (
            <Section title="What to bring">
              <Checklist items={experience.bring_list} tone="forest" />
            </Section>
          )}

          {itinerary.length > 0 && (
            <Section title="Itinerary">
              <ol className="space-y-3">
                {itinerary.map((item) => (
                  <li key={item.id} className="rounded-[var(--radius-sm)] border border-[var(--color-border)] p-3.5">
                    <p className="text-sm font-semibold text-[var(--color-forest)]">Day {item.day_number}</p>
                    <p className="mt-0.5 font-medium">{item.title}</p>
                    {item.description && (
                      <p className="mt-1 text-sm text-[var(--color-ink)]/70">{item.description}</p>
                    )}
                  </li>
                ))}
              </ol>
            </Section>
          )}

          {experience.meeting_point && (
            <Section title="Meeting point">
              <div className="flex items-center justify-between rounded-[var(--radius-sm)] border border-[var(--color-border)] p-4">
                <p className="text-[var(--color-ink)]/85">{experience.meeting_point}</p>
                <Link
                  href={`/map?experience=${experience.slug}`}
                  className="shrink-0 text-sm font-semibold text-[var(--color-forest)] underline underline-offset-2"
                >
                  View on Map
                </Link>
              </div>
            </Section>
          )}

          {experience.things_to_know && experience.things_to_know.length > 0 && (
            <Section title="Things to know">
              <Checklist items={experience.things_to_know} tone="ink" />
            </Section>
          )}

          <Section title={`Reviews (${experience.rating_count})`}>
            {reviews.length === 0 ? (
              <p className="text-[var(--color-ink)]/70">No reviews yet. Be the first to join!</p>
            ) : (
              <div className="space-y-3">
                {reviews.slice(0, 6).map((r) => (
                  <div key={r.id} className="rounded-[var(--radius-sm)] border border-[var(--color-border)] p-3.5">
                    <RatingStars rating={r.rating} />
                    {r.title && <p className="mt-1 font-medium">{r.title}</p>}
                    {r.body && <p className="mt-1 text-sm text-[var(--color-ink)]/70">{r.body}</p>}
                  </div>
                ))}
              </div>
            )}
          </Section>
        </div>

        {/* Sticky booking panel — folds the mobile PriceBottomBar in at lg+ per the responsive spec. */}
        <aside className="lg:sticky lg:top-20">
          <div className="overflow-hidden rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-card)] shadow-[0_8px_24px_rgba(1,37,28,0.06)]">
            {spotsLeftBanner(nextDeparture)}
            <div className="p-5">
              <p className="font-[family-name:var(--font-display)] text-2xl font-bold text-[var(--color-forest)]">
                {formatNpr(nextDeparture?.price_override_paisa ?? experience.price_paisa)}
              </p>
              <p className="text-xs text-[var(--color-ink)]/70">per person</p>

              {nextDeparture && (
                <p className="mt-4 text-sm text-[var(--color-ink)]/80">
                  Next departure{" "}
                  <span className="font-medium">
                    {new Date(nextDeparture.start_date).toLocaleDateString("en-US", {
                      day: "numeric",
                      month: "short",
                      year: "numeric",
                    })}
                  </span>
                </p>
              )}

              <Link href={`/booking/${experience.slug}`} className="mt-4 block">
                <Button variant="primary" fullWidth>
                  JOIN NOW
                </Button>
              </Link>

              <p className="mt-3 flex flex-wrap gap-x-4 gap-y-1 text-xs">
                <Link
                  href="/legal/cancellation-policy"
                  className="text-[var(--color-gold)] underline underline-offset-2"
                >
                  Cancellation Policy
                </Link>
                {(experience.difficulty && experience.difficulty !== "easy") ||
                (experience.max_altitude_m ?? 0) > 3000 ? (
                  <Link
                    href="/legal/safety-and-risk-policy"
                    className="text-[var(--color-gold)] underline underline-offset-2"
                  >
                    Safety &amp; Risk Policy
                  </Link>
                ) : null}
              </p>
            </div>
          </div>
        </aside>
      </div>

      {/* Mobile-only sticky price bar (PriceBottomBar) — hidden at lg where the side panel takes over. */}
      <div className="fixed inset-x-0 bottom-[74px] z-30 border-t border-[var(--color-border-subtle)] bg-white/95 px-4 py-3 backdrop-blur lg:hidden">
        <div className="flex items-center justify-between gap-4">
          <div>
            <p className="text-lg font-bold text-[var(--color-forest)]">{formatNpr(experience.price_paisa)}</p>
            <p className="text-xs text-[var(--color-ink)]/70">per person</p>
          </div>
          <Link href={`/booking/${experience.slug}`}>
            <Button variant="primary">JOIN NOW</Button>
          </Link>
        </div>
      </div>
    </div>
  );
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <dt className="text-xs uppercase tracking-wide text-[var(--color-ink)]/70">{label}</dt>
      <dd className="mt-0.5 font-semibold capitalize">{value}</dd>
    </div>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="mt-8">
      <OrnamentDivider className="mb-6" />
      <h2 className="mb-3 font-[family-name:var(--font-display)] text-xl font-semibold">{title}</h2>
      {children}
    </div>
  );
}

function Checklist({ items, tone }: { items: string[]; tone: "success" | "forest" | "ink" }) {
  const color =
    tone === "success" ? "text-[var(--color-success)]" : tone === "forest" ? "text-[var(--color-forest)]" : "text-[var(--color-ink)]/70";
  return (
    <ul className="grid gap-2 sm:grid-cols-2">
      {items.map((item) => (
        <li key={item} className="flex items-start gap-2 text-[var(--color-ink)]/85">
          <span className={`mt-0.5 ${color}`}>✓</span>
          {item}
        </li>
      ))}
    </ul>
  );
}
