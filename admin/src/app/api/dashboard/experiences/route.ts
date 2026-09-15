import { withAdmin } from "@/lib/with-admin.server";

// Dashboard counters scoped to content:manage only, matching the Experiences
// nav item's own gate.
export function GET(req: Request) {
  return withAdmin("content:manage", async (ctx) => {
    const [total, published, awaitingReview] = await Promise.all([
      ctx.db.from("experiences").select("id", { count: "exact", head: true }),
      ctx.db.from("experiences").select("id", { count: "exact", head: true }).eq("status", "published"),
      ctx.db.from("experiences").select("id", { count: "exact", head: true }).eq("status", "pending_review"),
    ]);

    for (const r of [total, published, awaitingReview]) {
      if (r.error) return Response.json({ error: r.error.message }, { status: 500 });
    }

    return Response.json({
      totalExperiences: total.count ?? 0,
      publishedExperiences: published.count ?? 0,
      experiencesAwaitingReview: awaitingReview.count ?? 0,
    });
  })(req);
}
