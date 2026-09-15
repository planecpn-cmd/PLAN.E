import { notFound } from "next/navigation";
import type { Metadata } from "next";
import { getExperienceBySlug, getExperienceExtras } from "@/lib/data/experiences";
import { BookingForm } from "@/components/BookingForm";

export const metadata: Metadata = { title: "Booking Form — PLAN E" };

export default async function BookingPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const experience = await getExperienceBySlug(slug);
  if (!experience) notFound();

  const { departures } = await getExperienceExtras(experience.id);

  return (
    <div className="mx-auto max-w-2xl px-4 py-6 lg:py-10">
      <BookingForm experience={experience} departures={departures} />
    </div>
  );
}
