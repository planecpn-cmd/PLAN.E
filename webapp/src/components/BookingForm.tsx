"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { supabase } from "@/lib/supabase";
import { useAuth } from "@/lib/AuthProvider";
import { formatNpr } from "@/lib/format";
import { ProgressSteps } from "@/components/ui/ProgressSteps";
import { CounterField } from "@/components/ui/CounterField";
import { TextField } from "@/components/ui/TextField";
import { Button } from "@/components/ui/Button";
import { AcceptanceLine } from "@/components/legal/AcceptanceLine";
import { RiskAcknowledgmentStep } from "@/components/legal/RiskAcknowledgmentStep";
import { recordAcceptances } from "@/lib/legal-acceptance";
import { CHECKOUT_ACCEPTANCE_SLUGS } from "@/lib/legal";
import type { Experience, Departure } from "@/lib/data/experiences";

// Risk Acknowledgment trigger. Category-based triggers (climbing / rafting /
// paragliding / canyoning) are covered here by difficulty, which is Moderate+
// for all of them in the catalogue; wire an explicit category check if that
// ever stops holding.
function needsRiskAck(experience: Experience): boolean {
  if (experience.difficulty && experience.difficulty !== "easy") return true;
  if ((experience.max_altitude_m ?? 0) > 3000) return true;
  return false;
}

export function BookingForm({ experience, departures }: { experience: Experience; departures: Departure[] }) {
  const { user, loading: authLoading } = useAuth();
  const router = useRouter();

  const [departureId, setDepartureId] = useState(departures[0]?.id ?? "");
  const [adults, setAdults] = useState(1);
  const [children, setChildren] = useState(0);
  const [contactName, setContactName] = useState("");
  const [contactPhone, setContactPhone] = useState("");
  const [notes, setNotes] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [intent, setIntent] = useState<{ bookingId: string; totalPaisa: number; quoteExpiresAt: string } | null>(null);
  const [payingWith, setPayingWith] = useState<"khalti" | "esewa" | null>(null);
  const [riskAccepted, setRiskAccepted] = useState(false);
  const riskRequired = needsRiskAck(experience);

  useEffect(() => {
    if (!authLoading && !user) {
      router.push(`/auth/required?reason=${encodeURIComponent("book this experience")}`);
    }
  }, [authLoading, user, router]);

  const departure = departures.find((d) => d.id === departureId);
  const unitPrice = departure?.price_override_paisa ?? experience.price_paisa;
  const childPrice = experience.child_price_paisa ?? Math.floor(unitPrice * 0.75);
  const subtotal = adults * unitPrice + children * childPrice;
  const fee = Math.round(subtotal * 0.05);
  const total = subtotal + fee;
  const maxSpots = departure?.spots_left ?? 20;

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    if (!departure) {
      setError("Pick a departure date first.");
      return;
    }
    setSubmitting(true);
    setError(null);

    const { data, error: fnError } = await supabase.functions.invoke("create-booking-intent", {
      body: {
        experience_id: experience.id,
        departure_id: departure.id,
        adults,
        children,
        contact_name: contactName,
        contact_phone: contactPhone,
        payment_provider: "khalti",
      },
    });

    if (fnError || data?.error) {
      setSubmitting(false);
      setError(data?.error ?? fnError?.message ?? "Could not create booking. Try again.");
      return;
    }

    // Record the Booking Terms + Cancellation Policy acceptance against this
    // booking BEFORE payment. Abort if consent cannot be recorded.
    try {
      await recordAcceptances(CHECKOUT_ACCEPTANCE_SLUGS, { bookingId: data.booking_id });
    } catch {
      setSubmitting(false);
      setError("Could not record your acceptance of the booking terms. Please try again.");
      return;
    }

    setSubmitting(false);
    setIntent({ bookingId: data.booking_id, totalPaisa: data.total_paisa, quoteExpiresAt: data.quote_expires_at });
  }

  async function pay(provider: "khalti" | "esewa") {
    if (!intent) return;
    setPayingWith(provider);
    setError(null);
    const { data, error: fnError } = await supabase.functions.invoke("initiate-payment", {
      body: { booking_id: intent.bookingId, provider },
    });
    setPayingWith(null);
    if (fnError || data?.error) {
      setError(data?.error ?? fnError?.message ?? "Could not start payment. Try again.");
      return;
    }
    window.location.href = data.payment_url;
  }

  return (
    <div>
      <h1 className="font-[family-name:var(--font-display)] text-2xl font-bold">Booking Form</h1>
      <div className="mt-5">
        <ProgressSteps steps={["Booking Details", "Confirmation"]} currentStep={intent ? 1 : 0} />
      </div>

      {!intent ? (
        <form onSubmit={submit} className="mt-8 space-y-6">
          <div className="rounded-[var(--radius-md)] border border-[var(--color-border)] p-4">
            <p className="font-semibold">{experience.title}</p>
            <p className="text-sm text-[var(--color-ink)]/70">{experience.location_name}</p>
            <p className="mt-1 text-sm">Price per adult: {formatNpr(experience.price_paisa)}</p>
          </div>

          <div>
            <p className="mb-2 font-semibold">Select Departure Date</p>
            <div className="space-y-2">
              {departures.length === 0 && (
                <p className="text-sm text-[var(--color-ink)]/70">No open departure dates right now.</p>
              )}
              {departures.map((d) => (
                <label
                  key={d.id}
                  className={`flex cursor-pointer items-center justify-between rounded-[var(--radius-sm)] border p-3 text-sm ${
                    departureId === d.id ? "border-[var(--color-forest)] bg-[var(--color-sage)]" : "border-[var(--color-border)]"
                  }`}
                >
                  <span className="flex items-center gap-2">
                    <input
                      type="radio"
                      name="departure"
                      checked={departureId === d.id}
                      onChange={() => setDepartureId(d.id)}
                    />
                    {new Date(d.start_date).toLocaleDateString("en-US", { day: "numeric", month: "short", year: "numeric" })}
                  </span>
                  <span className={d.spots_left < 5 ? "font-semibold text-[var(--color-error)]" : "text-[var(--color-ink)]/70"}>
                    {d.spots_left} spots available
                  </span>
                </label>
              ))}
            </div>
          </div>

          <div className="rounded-[var(--radius-md)] border border-[var(--color-border)] p-4 space-y-3">
            <p className="font-semibold">Number of Guests</p>
            <CounterField label="Adults" value={adults} onChange={setAdults} min={1} max={maxSpots} />
            <CounterField label="Children" value={children} onChange={setChildren} min={0} max={maxSpots} />
          </div>

          <div className="space-y-3">
            <p className="font-semibold">Primary Contact Info</p>
            <TextField label="Full Name" required value={contactName} onChange={(e) => setContactName(e.target.value)} />
            <TextField
              label="Nepali Phone Number"
              required
              value={contactPhone}
              onChange={(e) => setContactPhone(e.target.value)}
              placeholder="+9779XXXXXXXX"
            />
            <label className="block text-sm font-medium">Special Requirements / Notes</label>
            <textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              rows={2}
              className="w-full rounded-[var(--radius-sm)] border border-[var(--color-border)] p-3 text-sm"
            />
          </div>

          <div className="rounded-[var(--radius-md)] bg-[var(--color-card-alt)] p-4 text-sm">
            <Row label={`Adults (${adults})`} value={formatNpr(adults * unitPrice)} />
            {children > 0 && <Row label={`Children (${children})`} value={formatNpr(children * childPrice)} />}
            <hr className="my-2 border-[var(--color-border)]" />
            <Row label="Subtotal" value={formatNpr(subtotal)} />
            <Row label="Service Fee (5%)" value={formatNpr(fee)} muted />
            <p className="mt-0.5 text-xs text-[var(--color-ink)]/50">
              <Link
                href="/legal/payment-policy"
                target="_blank"
                className="underline underline-offset-2 hover:text-[var(--color-forest)]"
              >
                About the service fee
              </Link>
            </p>
            <hr className="my-2 border-[var(--color-border)]" />
            <Row label="Estimated Total" value={formatNpr(total)} bold />
          </div>

          {error && <p className="text-sm text-[var(--color-error)]">{error}</p>}

          <AcceptanceLine context="checkout" />
          <Button type="submit" variant="primary" fullWidth isLoading={submitting} disabled={departures.length === 0}>
            Proceed to Pay
          </Button>
        </form>
      ) : riskRequired && !riskAccepted ? (
        <div className="mt-8 rounded-[var(--radius-md)] border border-[var(--color-border)] p-5">
          <RiskAcknowledgmentStep
            bookingId={intent.bookingId}
            onAccepted={() => setRiskAccepted(true)}
          />
        </div>
      ) : (
        <div className="mt-8 rounded-[var(--radius-md)] border border-[var(--color-border)] p-5">
          <p className="font-semibold">Payment Intent Checkout</p>
          <p className="mt-1 text-sm text-[var(--color-ink)]/70">
            Server re-priced quote created — pick a gateway to continue.
          </p>

          <div className="mt-4 rounded-[var(--radius-sm)] bg-[var(--color-card-alt)] p-3 text-sm">
            <p>Quote valid until {new Date(intent.quoteExpiresAt).toLocaleTimeString()}</p>
            <p className="mt-1 font-semibold">Total: {formatNpr(intent.totalPaisa)}</p>
          </div>

          {error && <p className="mt-3 text-sm text-[var(--color-error)]">{error}</p>}

          <div className="mt-4 space-y-2">
            <Button variant="primary" fullWidth isLoading={payingWith === "khalti"} onClick={() => pay("khalti")}>
              Pay {formatNpr(intent.totalPaisa)} via Khalti
            </Button>
            <Button variant="secondary" fullWidth isLoading={payingWith === "esewa"} onClick={() => pay("esewa")}>
              Pay {formatNpr(intent.totalPaisa)} via eSewa
            </Button>
          </div>
        </div>
      )}
    </div>
  );
}

function Row({ label, value, bold, muted }: { label: string; value: string; bold?: boolean; muted?: boolean }) {
  return (
    <div className={`flex justify-between ${bold ? "font-bold" : ""} ${muted ? "text-[var(--color-ink)]/70" : ""}`}>
      <span>{label}</span>
      <span>{value}</span>
    </div>
  );
}
