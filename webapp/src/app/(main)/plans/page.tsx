"use client";

import { Suspense, useEffect, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { supabase } from "@/lib/supabase";
import { useAuth } from "@/lib/AuthProvider";
import { formatNpr } from "@/lib/format";
import { Button } from "@/components/ui/Button";
import { EmptyState } from "@/components/ui/EmptyState";
import { Icon, type IconName } from "@/components/ui/Icon";

const TABS = [
  { key: "upcoming", label: "Upcoming" },
  { key: "drafts", label: "Drafts" },
  { key: "past", label: "History" },
  { key: "cancelled", label: "Cancelled" },
] as const;

type Tab = (typeof TABS)[number]["key"];

type BookingRow = {
  id: string;
  booking_ref: string;
  status: string;
  is_draft: boolean;
  adults: number;
  children: number;
  total_paisa: number;
  experience_id: string;
  created_at: string;
  experiences: { title: string; slug: string; cover_image_url: string } | null;
};

const TOOLS: { label: string; icon: IconName }[] = [
  { label: "Schedule", icon: "calendar" },
  { label: "Messages", icon: "user" },
  { label: "Gear Checklist", icon: "bookmark" },
  { label: "Budget", icon: "bank" },
];

function PlansContent() {
  const { user, loading: authLoading } = useAuth();
  const router = useRouter();
  const searchParams = useSearchParams();
  const tab = (searchParams.get("tab") as Tab) ?? "upcoming";
  const [bookings, setBookings] = useState<BookingRow[] | null>(null);

  useEffect(() => {
    if (authLoading || !user) return;
    setBookings(null);
    let query = supabase
      .from("bookings")
      .select("id, booking_ref, status, is_draft, adults, children, total_paisa, experience_id, created_at, experiences(title, slug, cover_image_url)")
      .eq("user_id", user.id)
      .order("created_at", { ascending: false });

    if (tab === "upcoming") query = query.eq("status", "confirmed");
    else if (tab === "drafts") query = query.eq("is_draft", true);
    else if (tab === "past") query = query.eq("status", "completed");
    else query = query.eq("status", "cancelled");

    query.then(({ data }) => setBookings((data ?? []) as unknown as BookingRow[]));
  }, [user, authLoading, tab]);

  function setTab(next: Tab) {
    router.push(`/plans?tab=${next}`);
  }

  if (authLoading) return null;

  if (!user) {
    return (
      <div className="mx-auto max-w-6xl px-4 py-16 lg:px-6">
        <EmptyState
          title="Log in to see your plans"
          description="Sign in to view your upcoming trips, drafts, and booking history."
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
    <div className="mx-auto max-w-4xl px-4 py-8 lg:px-6 lg:py-12">
      <h1 className="font-[family-name:var(--font-display)] text-3xl font-bold">Plans</h1>

      <div className="mt-5 inline-flex gap-1 rounded-[var(--radius-pill)] bg-[var(--color-sage)] p-1">
        {TABS.map((t) => (
          <button
            key={t.key}
            onClick={() => setTab(t.key)}
            className={`rounded-[var(--radius-pill)] px-4 py-2 text-sm font-semibold transition-colors ${
              tab === t.key ? "bg-[var(--color-forest)] text-white" : "text-[var(--color-ink)]/70"
            }`}
          >
            {t.label}
          </button>
        ))}
      </div>

      {bookings === null ? (
        <p className="mt-8 text-sm text-[var(--color-ink)]/60">Loading…</p>
      ) : bookings.length === 0 ? (
        <div className="mt-8">
          <EmptyState
            title={emptyTitle(tab)}
            description="Explore experiences across Nepal and start planning your next trip."
            action={
              <Link href="/explore" className="mt-3 inline-block">
                <Button variant="primary">Explore Experiences</Button>
              </Link>
            }
          />
        </div>
      ) : (
        <div className="mt-6 space-y-4">
          {bookings.map((b) => (
            <BookingCard key={b.id} booking={b} tab={tab} />
          ))}

          {tab === "upcoming" && (
            <div className="mt-8">
              <h2 className="font-[family-name:var(--font-display)] text-lg font-semibold">Experience Tools</h2>
              <div className="mt-3 grid grid-cols-2 gap-3">
                {TOOLS.map((tool) => (
                  <div
                    key={tool.label}
                    className="flex items-center gap-3 rounded-[var(--radius-md)] border border-[var(--color-border)] p-4"
                  >
                    <span className="flex h-9 w-9 items-center justify-center rounded-full bg-[var(--color-sage)] text-[var(--color-forest)]">
                      <Icon name={tool.icon} size={18} />
                    </span>
                    <span className="text-sm font-semibold">{tool.label}</span>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}

function emptyTitle(tab: Tab) {
  switch (tab) {
    case "upcoming":
      return "No upcoming trips";
    case "drafts":
      return "No draft bookings";
    case "past":
      return "No completed trips yet";
    default:
      return "No cancelled bookings";
  }
}

function BookingCard({ booking, tab }: { booking: BookingRow; tab: Tab }) {
  const badge =
    tab === "upcoming"
      ? { label: "CONFIRMED", tone: "bg-[var(--color-sage)] text-[var(--color-success)]" }
      : tab === "drafts"
        ? { label: "DRAFT", tone: "bg-[var(--color-warning-container)] text-[var(--color-warning)]" }
        : tab === "past"
          ? { label: "COMPLETED", tone: "bg-[var(--color-success-container)] text-[var(--color-success)]" }
          : { label: "CANCELLED", tone: "bg-[var(--color-error-container)] text-[var(--color-error)]" };

  return (
    <div className="overflow-hidden rounded-[var(--radius-md)] border border-[var(--color-border)]">
      {booking.experiences && (
        <div className="relative h-32 w-full">
          <Image src={booking.experiences.cover_image_url} alt={booking.experiences.title} fill sizes="700px" className="object-cover" />
          <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent" />
          <p className="absolute bottom-2 left-3 right-3 font-[family-name:var(--font-display)] font-semibold text-white line-clamp-1">
            {booking.experiences.title}
          </p>
        </div>
      )}
      <div className="p-4">
        <div className="flex items-center justify-between">
          <span className={`rounded-[var(--radius-pill)] px-2.5 py-1 text-[11px] font-bold ${badge.tone}`}>{badge.label}</span>
          <span className="text-xs text-[var(--color-ink)]/50">#{booking.booking_ref}</span>
        </div>
        <p className="mt-2 text-sm text-[var(--color-ink)]/70">
          {booking.adults} adult{booking.adults === 1 ? "" : "s"}
          {booking.children > 0 ? `, ${booking.children} children` : ""}
        </p>
        <hr className="my-3 border-[var(--color-border-subtle)]" />
        <div className="flex items-center justify-between">
          <div>
            <p className="text-xs text-[var(--color-ink)]/50">Total Paid</p>
            <p className="font-bold text-[var(--color-forest)]">{formatNpr(booking.total_paisa)}</p>
          </div>
          {booking.experiences && (
            <Link href={`/experience/${booking.experiences.slug}`} className="text-sm font-semibold text-[var(--color-forest)] hover:underline">
              View Experience
            </Link>
          )}
        </div>
      </div>
    </div>
  );
}

export default function PlansPage() {
  return (
    <Suspense>
      <PlansContent />
    </Suspense>
  );
}
