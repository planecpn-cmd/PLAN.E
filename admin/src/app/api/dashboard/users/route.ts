import { withAdmin } from "@/lib/with-admin.server";
import { kathmanduTodayRangeUtc } from "@/lib/kathmandu-today";

// Dashboard counters scoped to users:manage only -- a moderator without this
// scope must not see user counts, even indirectly through a combined
// endpoint. "Active user" is not a tracked signal anywhere in the schema
// (no last-sign-in column on profiles); defined here as "made at least one
// booking in the last 30 days" -- the only activity signal the schema
// actually supports. Stated in the UI, not left as an unexplained number.
const ACTIVE_WINDOW_DAYS = 30;

export function GET(req: Request) {
  return withAdmin("users:manage", async (ctx) => {
    const { startUtc, endUtc } = kathmanduTodayRangeUtc();
    const activeSinceUtc = new Date(Date.now() - ACTIVE_WINDOW_DAYS * 24 * 60 * 60 * 1000).toISOString();

    const [newToday, total, activeUserIds] = await Promise.all([
      ctx.db.from("profiles").select("id", { count: "exact", head: true }).gte("created_at", startUtc).lt("created_at", endUtc),
      ctx.db.from("profiles").select("id", { count: "exact", head: true }),
      ctx.db.from("bookings").select("user_id").gte("created_at", activeSinceUtc),
    ]);

    for (const r of [newToday, total, activeUserIds]) {
      if (r.error) return Response.json({ error: r.error.message }, { status: 500 });
    }

    const activeUsers = new Set((activeUserIds.data ?? []).map((b) => b.user_id)).size;

    return Response.json({
      newUsersToday: newToday.count ?? 0,
      totalUsers: total.count ?? 0,
      activeUsers,
      activeDefinition: `made a booking in the last ${ACTIVE_WINDOW_DAYS} days`,
    });
  })(req);
}
