import { withAdmin } from "@/lib/with-admin.server";
import { kathmanduTodayRangeUtc } from "@/lib/kathmandu-today";

// Dashboard counters scoped to bookings:read only. Gross booking value is the
// one money figure C1 clears as safe (same number regardless of commission
// direction) -- defined as SUM(total_paisa) for confirmed/completed bookings,
// matching the "real spend" definition already used in /api/users. Excludes
// pending/cancelled/expired, which never represented real transacted value.
export function GET(req: Request) {
  return withAdmin("bookings:read", async (ctx) => {
    const { startUtc, endUtc, dateStr } = kathmanduTodayRangeUtc();

    const [bookingsToday, cancellationsToday, totalBookings, valueRows, upcomingDepartures] = await Promise.all([
      ctx.db.from("bookings").select("id", { count: "exact", head: true }).gte("created_at", startUtc).lt("created_at", endUtc),
      ctx.db.from("bookings").select("id", { count: "exact", head: true }).eq("status", "cancelled").gte("cancelled_at", startUtc).lt("cancelled_at", endUtc),
      ctx.db.from("bookings").select("id", { count: "exact", head: true }),
      ctx.db.from("bookings").select("total_paisa").in("status", ["confirmed", "completed"]),
      ctx.db.from("experience_departures").select("id").gte("start_date", dateStr),
    ]);

    for (const r of [bookingsToday, cancellationsToday, totalBookings, valueRows, upcomingDepartures]) {
      if (r.error) return Response.json({ error: r.error.message }, { status: 500 });
    }

    const grossBookingValuePaisa = (valueRows.data ?? []).reduce((sum, r) => sum + (r.total_paisa ?? 0), 0);

    const departureIds = (upcomingDepartures.data ?? []).map((d) => d.id);
    let upcomingBookings = 0;
    if (departureIds.length > 0) {
      const { count, error } = await ctx.db
        .from("bookings")
        .select("id", { count: "exact", head: true })
        .in("departure_id", departureIds)
        .in("status", ["pending", "confirmed"]);
      if (error) return Response.json({ error: error.message }, { status: 500 });
      upcomingBookings = count ?? 0;
    }

    return Response.json({
      bookingsToday: bookingsToday.count ?? 0,
      cancellationsToday: cancellationsToday.count ?? 0,
      totalBookings: totalBookings.count ?? 0,
      upcomingBookings,
      grossBookingValueNpr: Math.round(grossBookingValuePaisa / 100),
      grossBookingValueDefinition: "sum of confirmed + completed bookings",
    });
  })(req);
}
