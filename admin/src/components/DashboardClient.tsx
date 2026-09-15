"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import type { Scope } from "@/lib/scopes";

type FetchState<T> = { data: T | null; error: string | null; loading: boolean };

function useCounters<T>(endpoint: string, enabled: boolean): FetchState<T> {
  const [state, setState] = useState<FetchState<T>>({ data: null, error: null, loading: enabled });

  useEffect(() => {
    if (!enabled) return;
    let cancelled = false;
    fetch(endpoint)
      .then(async (res) => {
        const body = await res.json();
        if (cancelled) return;
        if (!res.ok) {
          setState({ data: null, error: body.error ?? `request failed (${res.status})`, loading: false });
          return;
        }
        setState({ data: body as T, error: null, loading: false });
      })
      .catch((err) => {
        if (!cancelled) setState({ data: null, error: String(err), loading: false });
      });
    return () => {
      cancelled = true;
    };
  }, [endpoint, enabled]);

  return state;
}

interface UsersCounters {
  newUsersToday: number;
  totalUsers: number;
  activeUsers: number;
  activeDefinition: string;
}
interface HostsCounters {
  newHostsToday: number;
  totalHosts: number;
  activeHosts: number;
  hostApplicationsAwaitingReview: number;
  activeDefinition: string;
}
interface ExperiencesCounters {
  totalExperiences: number;
  publishedExperiences: number;
  experiencesAwaitingReview: number;
}
interface BookingsCounters {
  bookingsToday: number;
  cancellationsToday: number;
  totalBookings: number;
  upcomingBookings: number;
  grossBookingValueNpr: number;
  grossBookingValueDefinition: string;
}

function Card({
  label,
  value,
  href,
  hint,
}: {
  label: string;
  value: number | string;
  href?: string;
  hint?: string;
}) {
  const body = (
    <div className="rounded-lg border border-[var(--color-border-subtle)] bg-white p-4">
      <div className="text-2xl font-bold text-[var(--color-forest)] tabular-nums">{value}</div>
      <div className="mt-1 text-sm text-[var(--color-ink)]/70">{label}</div>
      {hint && <div className="mt-1 text-xs text-[var(--color-ink)]/45">{hint}</div>}
    </div>
  );
  if (!href) return body;
  return (
    <Link href={href} className="block transition-colors hover:border-[var(--color-forest)]">
      {body}
    </Link>
  );
}

function CardSkeleton() {
  return (
    <div className="animate-pulse rounded-lg border border-[var(--color-border-subtle)] bg-white p-4">
      <div className="h-7 w-12 rounded bg-[var(--color-sage)]" />
      <div className="mt-2 h-4 w-24 rounded bg-[var(--color-sage)]" />
    </div>
  );
}

function CardError({ message }: { message: string }) {
  return (
    <div className="rounded-lg border border-[var(--color-error-container)] bg-[var(--color-error-container)]/30 p-4">
      <div className="text-sm text-[var(--color-error)]">Couldn&apos;t load</div>
      <div className="mt-1 text-xs text-[var(--color-ink)]/60">{message}</div>
    </div>
  );
}

function Section({
  title,
  visible,
  children,
}: {
  title: string;
  visible: boolean;
  children: React.ReactNode;
}) {
  if (!visible) return null;
  return (
    <section className="mt-6 first:mt-0">
      <h2 className="text-sm font-semibold text-[var(--color-ink)]/80">{title}</h2>
      <div className="mt-3 grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4">{children}</div>
    </section>
  );
}

export function DashboardClient({ scopes }: { scopes: Scope[] }) {
  const hasUsers = scopes.includes("users:manage");
  const hasHosts = scopes.includes("hosts:review");
  const hasExperiences = scopes.includes("content:manage");
  const hasBookings = scopes.includes("bookings:read");

  const users = useCounters<UsersCounters>("/api/dashboard/users", hasUsers);
  const hosts = useCounters<HostsCounters>("/api/dashboard/hosts", hasHosts);
  const experiences = useCounters<ExperiencesCounters>("/api/dashboard/experiences", hasExperiences);
  const bookings = useCounters<BookingsCounters>("/api/dashboard/bookings", hasBookings);

  const anyScope = hasUsers || hasHosts || hasExperiences || hasBookings;

  return (
    <div>
      <h1 className="text-xl font-bold text-[var(--color-forest)]">Dashboard</h1>

      {!anyScope && (
        <p className="mt-4 text-sm text-[var(--color-ink)]/60">
          Your account has no scopes with dashboard counters yet.
        </p>
      )}

      <Section title="Today's activity" visible={anyScope}>
        {hasUsers &&
          (users.loading ? (
            <CardSkeleton />
          ) : users.error ? (
            <CardError message={users.error} />
          ) : (
            <Card label="New users today" value={users.data!.newUsersToday} href="/users" />
          ))}
        {hasHosts &&
          (hosts.loading ? (
            <CardSkeleton />
          ) : hosts.error ? (
            <CardError message={hosts.error} />
          ) : (
            <>
              <Card label="New hosts today" value={hosts.data!.newHostsToday} href="/host-applications" />
              <Card
                label="Host applications awaiting review"
                value={hosts.data!.hostApplicationsAwaitingReview}
                href="/host-applications?status=submitted"
              />
            </>
          ))}
        {hasBookings &&
          (bookings.loading ? (
            <CardSkeleton />
          ) : bookings.error ? (
            <CardError message={bookings.error} />
          ) : (
            <>
              <Card label="Bookings today" value={bookings.data!.bookingsToday} href="/bookings" />
              <Card
                label="Cancellations today"
                value={bookings.data!.cancellationsToday}
                href="/bookings?status=cancelled"
              />
            </>
          ))}
        {hasExperiences &&
          (experiences.loading ? (
            <CardSkeleton />
          ) : experiences.error ? (
            <CardError message={experiences.error} />
          ) : (
            <Card
              label="Experiences awaiting review"
              value={experiences.data!.experiencesAwaitingReview}
              href="/experiences?status=pending_review"
            />
          ))}
      </Section>

      <Section title="Platform overview" visible={hasUsers || hasHosts || hasExperiences}>
        {hasUsers &&
          (users.loading ? (
            <CardSkeleton />
          ) : users.error ? null : (
            <>
              <Card label="Total users" value={users.data!.totalUsers} href="/users" />
              <Card label="Active users" value={users.data!.activeUsers} href="/users" hint={users.data!.activeDefinition} />
            </>
          ))}
        {hasHosts &&
          (hosts.loading ? (
            <CardSkeleton />
          ) : hosts.error ? null : (
            <>
              <Card label="Total hosts" value={hosts.data!.totalHosts} href="/host-applications" />
              <Card
                label="Active hosts"
                value={hosts.data!.activeHosts}
                href="/host-applications"
                hint={hosts.data!.activeDefinition}
              />
            </>
          ))}
        {hasExperiences &&
          (experiences.loading ? (
            <CardSkeleton />
          ) : experiences.error ? null : (
            <>
              <Card label="Total experiences" value={experiences.data!.totalExperiences} href="/experiences?status=all" />
              <Card
                label="Published experiences"
                value={experiences.data!.publishedExperiences}
                href="/experiences?status=published"
              />
            </>
          ))}
      </Section>

      <Section title="Booking overview" visible={hasBookings}>
        {bookings.loading ? (
          <>
            <CardSkeleton />
            <CardSkeleton />
            <CardSkeleton />
            <CardSkeleton />
          </>
        ) : bookings.error ? (
          <CardError message={bookings.error} />
        ) : (
          <>
            <Card label="Total bookings" value={bookings.data!.totalBookings} href="/bookings" />
            <Card
              label="Today's cancellations"
              value={bookings.data!.cancellationsToday}
              href="/bookings?status=cancelled"
            />
            <Card label="Upcoming bookings" value={bookings.data!.upcomingBookings} href="/bookings" />
            <Card
              label="Gross booking value"
              value={`Rs ${bookings.data!.grossBookingValueNpr.toLocaleString("en-IN")}`}
              hint={bookings.data!.grossBookingValueDefinition}
            />
          </>
        )}
      </Section>
    </div>
  );
}
