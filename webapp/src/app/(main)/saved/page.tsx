"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { supabase } from "@/lib/supabase";
import { useAuth } from "@/lib/AuthProvider";
import { ExperienceCard, type ExperienceCardData } from "@/components/ui/ExperienceCard";
import { EmptyState } from "@/components/ui/EmptyState";
import { Button } from "@/components/ui/Button";
import { ExperienceCardSkeleton } from "@/components/ui/Skeleton";
import { Icon } from "@/components/ui/Icon";

type SavedRow = {
  experience_id: string;
  experiences: {
    slug: string;
    title: string;
    location_name: string | null;
    cover_image_url: string;
    price_paisa: number;
    rating_avg: number;
    rating_count: number;
  } | null;
};

type SavedCard = ExperienceCardData & { experienceId: string };

export default function SavedPage() {
  const { user, loading: authLoading } = useAuth();
  const [cards, setCards] = useState<SavedCard[] | null>(null);

  useEffect(() => {
    if (authLoading || !user) return;
    let cancelled = false;
    supabase
      .from("saved_experiences")
      .select("experience_id, experiences(slug, title, location_name, cover_image_url, price_paisa, rating_avg, rating_count)")
      .eq("user_id", user.id)
      .then(({ data }) => {
        if (cancelled) return;
        const rows = (data ?? []) as unknown as SavedRow[];
        setCards(
          rows
            .filter((r) => r.experiences)
            .map((r) => ({
              experienceId: r.experience_id,
              slug: r.experiences!.slug,
              title: r.experiences!.title,
              locationName: r.experiences!.location_name,
              coverImageUrl: r.experiences!.cover_image_url,
              pricePaisa: r.experiences!.price_paisa,
              ratingAvg: r.experiences!.rating_avg,
              ratingCount: r.experiences!.rating_count,
            })),
        );
      });
    return () => {
      cancelled = true;
    };
  }, [user, authLoading]);

  async function remove(slug: string, experienceId: string) {
    if (!user) return;
    await supabase.from("saved_experiences").delete().eq("user_id", user.id).eq("experience_id", experienceId);
    setCards((prev) => prev?.filter((c) => c.slug !== slug) ?? prev);
  }

  if (authLoading) {
    return (
      <div className="mx-auto max-w-6xl px-4 py-8 lg:px-6 lg:py-12">
        <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
          {Array.from({ length: 4 }).map((_, i) => (
            <ExperienceCardSkeleton key={i} />
          ))}
        </div>
      </div>
    );
  }

  if (!user) {
    return (
      <div className="mx-auto max-w-6xl px-4 py-16 lg:px-6">
        <EmptyState
          title="Log in to see your saved experiences"
          description="Save your favorite Nepal experiences to view them anytime."
          action={
            <Link href="/auth/login" className="mt-3 inline-block">
              <Button variant="primary">Log in</Button>
            </Link>
          }
        />
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-6xl px-4 py-8 lg:px-6 lg:py-12">
      <h1 className="font-[family-name:var(--font-display)] text-3xl font-bold">Saved Experiences</h1>

      {cards === null ? (
        <div className="mt-6 grid grid-cols-2 gap-4 lg:grid-cols-4">
          {Array.from({ length: 4 }).map((_, i) => (
            <ExperienceCardSkeleton key={i} />
          ))}
        </div>
      ) : cards.length === 0 ? (
        <div className="mt-8">
          <EmptyState
            title="No Saved Experiences Yet"
            description="Save your favorite Nepal experiences to view them anytime."
            action={
              <Link href="/explore" className="mt-3 inline-block">
                <Button variant="primary">
                  <Icon name="compass" size={16} />
                  Explore Experiences
                </Button>
              </Link>
            }
          />
        </div>
      ) : (
        <div className="mt-6 grid grid-cols-2 gap-4 lg:grid-cols-4">
          {cards.map((card) => (
            <ExperienceCard
              key={card.slug}
              experience={card}
              saved
              onToggleSave={() => remove(card.slug, card.experienceId)}
            />
          ))}
        </div>
      )}
    </div>
  );
}
