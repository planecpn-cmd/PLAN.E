import { withAdmin } from "@/lib/with-admin.server";
import { kathmanduTodayRangeUtc } from "@/lib/kathmandu-today";

// Dashboard counters scoped to hosts:review only. "Awaiting review" =
// submitted or under_review -- 'verification' means a decision already
// happened and the applicant owes documents back, not "in the queue" in the
// same sense. "Active host" uses host_accounts.is_active directly -- the
// schema already tracks this exactly, nothing to define.
export function GET(req: Request) {
  return withAdmin("hosts:review", async (ctx) => {
    const { startUtc, endUtc } = kathmanduTodayRangeUtc();

    const [newHostsToday, totalHosts, activeHosts, awaitingReview] = await Promise.all([
      ctx.db.from("host_accounts").select("user_id", { count: "exact", head: true }).gte("created_at", startUtc).lt("created_at", endUtc),
      ctx.db.from("host_accounts").select("user_id", { count: "exact", head: true }),
      ctx.db.from("host_accounts").select("user_id", { count: "exact", head: true }).eq("is_active", true),
      ctx.db.from("host_applications").select("id", { count: "exact", head: true }).in("status", ["submitted", "under_review"]),
    ]);

    for (const r of [newHostsToday, totalHosts, activeHosts, awaitingReview]) {
      if (r.error) return Response.json({ error: r.error.message }, { status: 500 });
    }

    return Response.json({
      newHostsToday: newHostsToday.count ?? 0,
      totalHosts: totalHosts.count ?? 0,
      activeHosts: activeHosts.count ?? 0,
      hostApplicationsAwaitingReview: awaitingReview.count ?? 0,
      activeDefinition: "host_accounts.is_active",
    });
  })(req);
}
