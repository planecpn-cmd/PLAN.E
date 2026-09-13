import Link from "next/link";
import { notFound } from "next/navigation";
import { requireScope } from "@/lib/session";
import { createAnonServerClient } from "@/lib/supabase/server";
import { AdminShell } from "@/components/AdminShell";
import { OpsActionForm } from "@/components/OpsActionForm";

export default async function BookingDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const session = await requireScope("bookings:read");
  const { id } = await params;
  const supabase = await createAnonServerClient();

  const { data: b } = await supabase.from("bookings").select("*").eq("id", id).maybeSingle();
  if (!b) notFound();

  const [{ data: participants }, { data: departure }, { data: payment }, { data: cancellations }] =
    await Promise.all([
      supabase.from("booking_participants").select("full_name,age,is_lead").eq("booking_id", id),
      supabase
        .from("experience_departures")
        .select("start_date,end_date,status")
        .eq("id", b.departure_id)
        .maybeSingle(),
      supabase
        .from("payments")
        .select("id,provider,amount_paisa,status,paid_at,created_at")
        .eq("booking_id", id)
        .maybeSingle(),
      supabase
        .from("booking_cancellations")
        .select("reason,actor_kind,from_status,created_at")
        .eq("booking_id", id)
        .order("created_at", { ascending: false }),
    ]);

  const canAct = session.scopes.includes("payments:act");
  const cancellable = ["pending", "confirmed", "cancellation_requested"].includes(b.status as string);

  const timeline = [
    { at: b.created_at, label: "Booking created" },
    { at: payment?.created_at, label: `Payment initiated (${payment?.provider ?? "—"})` },
    { at: payment?.paid_at, label: "Payment paid" },
    { at: b.completed_at, label: "Trip completed" },
    { at: b.cancelled_at, label: "Booking cancelled" },
  ].filter((e) => e.at);

  return (
    <AdminShell scopes={session.scopes} email={session.email}>
      <Link href="/bookings" className="text-sm text-[var(--color-ink)]/60 hover:underline">
        ← Bookings
      </Link>
      <h1 className="mt-2 text-xl font-bold text-[var(--color-forest)]">{b.booking_ref}</h1>
      <p className="mt-1 text-sm text-[var(--color-ink)]/60">
        {String(b.status).replace(/_/g, " ")} · {b.contact_name} · {b.contact_phone}
      </p>

      <section className="mt-6 grid gap-6 sm:grid-cols-2">
        <div>
          <h2 className="text-sm font-semibold uppercase text-[var(--color-ink)]/50">Details</h2>
          <dl className="mt-2 space-y-1 text-sm">
            <div>People: {(b.adults ?? 0) + (b.children ?? 0)}</div>
            <div>Total: NPR {Math.round((b.total_paisa ?? 0) / 100).toLocaleString()}</div>
            <div>
              Departure: {departure ? `${departure.start_date} → ${departure.end_date} (${departure.status})` : "—"}
            </div>
            <div>
              Payment:{" "}
              {payment
                ? `${payment.provider} · NPR ${Math.round(payment.amount_paisa / 100).toLocaleString()} · ${payment.status}`
                : "none"}
            </div>
          </dl>
          {(participants ?? []).length > 0 && (
            <ul className="mt-3 text-sm">
              {(participants ?? []).map((p, i) => (
                <li key={i}>
                  {p.full_name}
                  {p.is_lead ? " (lead)" : ""}
                  {p.age ? ` · ${p.age}` : ""}
                </li>
              ))}
            </ul>
          )}
        </div>

        <div>
          <h2 className="text-sm font-semibold uppercase text-[var(--color-ink)]/50">Timeline</h2>
          <ol className="mt-2 space-y-2 text-sm">
            {timeline.map((e, i) => (
              <li key={i} className="border-l-2 border-[var(--color-forest)] pl-3">
                <div className="font-medium">{e.label}</div>
                <div className="text-xs text-[var(--color-ink)]/50">
                  {new Date(e.at as string).toLocaleString()}
                </div>
              </li>
            ))}
          </ol>
        </div>
      </section>

      {(cancellations ?? []).length > 0 && (
        <section className="mt-6">
          <h2 className="text-sm font-semibold uppercase text-[var(--color-ink)]/50">Cancellation</h2>
          {(cancellations ?? []).map((c, i) => (
            <p key={i} className="mt-1 text-sm">
              {c.actor_kind}: “{c.reason}” (from {c.from_status}) ·{" "}
              {new Date(c.created_at).toLocaleString()}
            </p>
          ))}
        </section>
      )}

      {canAct && cancellable && (
        <section className="mt-6">
          <h2 className="text-sm font-semibold uppercase text-[var(--color-ink)]/50">Actions</h2>
          <OpsActionForm
            endpoint={`/api/bookings/${id}/cancel`}
            label="Cancel booking"
            danger
            confirm="Cancel this booking? This is recorded with your reason."
          />
        </section>
      )}
    </AdminShell>
  );
}
