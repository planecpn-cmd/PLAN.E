import Link from "next/link";
import { notFound } from "next/navigation";
import type { Metadata } from "next";
import { createClient } from "@/lib/supabase/server";
import { formatNpr } from "@/lib/format";
import { Button } from "@/components/ui/Button";
import { RefreshStatusButton } from "@/components/RefreshStatusButton";

export const metadata: Metadata = { title: "Booking Confirmation — PLAN E" };

export default async function ConfirmationPage({
  params,
}: {
  params: Promise<{ bookingId: string }>;
}) {
  const { bookingId } = await params;
  const supabase = await createClient();
  const { data: booking } = await supabase.from("bookings").select("*").eq("id", bookingId).maybeSingle();

  if (!booking) notFound();

  const { data: experience } = await supabase
    .from("experiences")
    .select("title")
    .eq("id", booking.experience_id)
    .maybeSingle();

  const isConfirmed = booking.status === "confirmed" || booking.status === "completed";
  const experienceTitle = experience?.title;

  return (
    <div className="mx-auto max-w-md px-4 py-16 text-center lg:py-20">
      <div
        className={`mx-auto flex h-16 w-16 items-center justify-center rounded-full ${
          isConfirmed ? "bg-[var(--color-success-container)]" : "bg-[var(--color-warning-container)]"
        }`}
      >
        <span className={`text-3xl ${isConfirmed ? "text-[var(--color-success)]" : "text-[var(--color-warning)]"}`}>
          {isConfirmed ? "✓" : "…"}
        </span>
      </div>

      <h1 className="mt-5 font-[family-name:var(--font-display)] text-3xl font-bold">
        {isConfirmed ? "Booking Confirmed!" : "Awaiting Payment Confirmation"}
      </h1>
      <p className="mt-2 text-[var(--color-ink)]/70">
        {isConfirmed
          ? "Your adventure is officially reserved."
          : "We're waiting for your payment to be confirmed. This updates automatically once the gateway settles."}
      </p>

      <div className="mt-6 rounded-[var(--radius-md)] border border-[var(--color-border)] p-5 text-left">
        <div className="flex items-center justify-between text-sm">
          <span className="rounded-full bg-[var(--color-sage)] px-2.5 py-1 font-semibold uppercase text-[var(--color-forest)]">
            {booking.status}
          </span>
          <span className="text-[var(--color-ink)]/70">#{booking.booking_ref}</span>
        </div>
        {experienceTitle && <p className="mt-3 font-medium">{experienceTitle}</p>}
        <p className="mt-1 text-sm text-[var(--color-ink)]/70">Contact: {booking.contact_name}</p>
        <p className="text-sm text-[var(--color-ink)]/70">
          Guests: {booking.adults} adult{booking.adults === 1 ? "" : "s"}
          {booking.children > 0 ? `, ${booking.children} children` : ""}
        </p>
        <hr className="my-3 border-[var(--color-border)]" />
        <div className="flex justify-between font-semibold">
          <span>Total</span>
          <span>{formatNpr(booking.total_paisa)}</span>
        </div>
      </div>

      <p className="mt-3 flex justify-center gap-4 text-sm">
        <Link href="/legal/cancellation-policy" className="text-[var(--color-gold)] underline underline-offset-2">
          Cancellation Policy
        </Link>
        <Link href="/legal/refund-policy" className="text-[var(--color-gold)] underline underline-offset-2">
          Refund Policy
        </Link>
      </p>

      {!isConfirmed && <RefreshStatusButton />}

      {isConfirmed && (
        <div className="mt-6 space-y-3">
          <Link href="/plans">
            <Button variant="primary" fullWidth>
              VIEW MY PLANS
            </Button>
          </Link>
        </div>
      )}
      <Link href="/" className="mt-3 block">
        <Button variant="secondary" fullWidth>
          BACK TO HOME
        </Button>
      </Link>
    </div>
  );
}
