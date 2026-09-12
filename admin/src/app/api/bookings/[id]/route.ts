import { withAdmin } from "@/lib/with-admin.server";

// Booking detail: the row, participants, departure, payment, cancellation, and a
// vertical timeline. bookings:read.
export function GET(_req: Request, { params }: { params: Promise<{ id: string }> }) {
  return withAdmin("bookings:read", async (ctx) => {
    const { id } = await params;

    const { data: booking, error } = await ctx.db.from("bookings").select("*").eq("id", id).maybeSingle();
    if (error) return Response.json({ error: error.message }, { status: 500 });
    if (!booking) return Response.json({ error: "not found" }, { status: 404 });

    const [{ data: participants }, { data: departure }, { data: payment }, { data: cancellations }] =
      await Promise.all([
        ctx.db.from("booking_participants").select("full_name,age,is_lead").eq("booking_id", id),
        ctx.db
          .from("experience_departures")
          .select("start_date,end_date,total_spots,spots_left,status")
          .eq("id", booking.departure_id)
          .maybeSingle(),
        ctx.db
          .from("payments")
          .select("id,provider,provider_ref,amount_paisa,status,paid_at,created_at")
          .eq("booking_id", id)
          .maybeSingle(),
        ctx.db
          .from("booking_cancellations")
          .select("id,actor_id,actor_kind,reason,refund_id,from_status,created_at")
          .eq("booking_id", id)
          .order("created_at", { ascending: false }),
      ]);

    const refunds = payment
      ? (
          await ctx.db
            .from("refunds")
            .select("id,amount_paisa,status,reason,provider_refund_ref,failure_reason,created_at,updated_at")
            .eq("payment_id", payment.id)
            .order("created_at", { ascending: false })
        ).data ?? []
      : [];

    // vertical timeline, not columns
    const timeline: { at: string | null; label: string }[] = [
      { at: booking.created_at, label: "Booking created" },
      { at: payment?.created_at ?? null, label: `Payment initiated (${payment?.provider ?? "—"})` },
      { at: payment?.paid_at ?? null, label: "Payment paid" },
      { at: booking.status === "confirmed" || booking.completed_at ? booking.updated_at : null, label: "Booking confirmed" },
      { at: booking.completed_at, label: "Trip completed" },
      { at: booking.cancelled_at, label: "Booking cancelled" },
    ].filter((e) => e.at);

    return Response.json({
      booking,
      participants: participants ?? [],
      departure: departure ?? null,
      payment: payment ?? null,
      refunds,
      cancellations: cancellations ?? [],
      timeline,
    });
  })(_req);
}
