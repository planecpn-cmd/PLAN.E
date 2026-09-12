import { withAdmin } from "@/lib/with-admin.server";
import { isRecommendation, reasonRequired } from "@/lib/host-review";

// hosts:review records a recommendation. No status change — that is the
// four-eyes split: review recommends, decide commits.
export function POST(req: Request, { params }: { params: Promise<{ id: string }> }) {
  return withAdmin(
    "hosts:review",
    async (ctx) => {
      const { id } = await params;
      const body = (await req.json().catch(() => null)) as
        | { decision?: string; note?: string; checklist?: Record<string, unknown> }
        | null;

      const decision = body?.decision;
      const note = body?.note?.trim() || null;
      const checklist = body?.checklist ?? {};

      if (!decision || !isRecommendation(decision)) {
        return Response.json({ error: "decision must be recommend_approve | recommend_reject | recommend_changes" }, { status: 400 });
      }
      if (reasonRequired(decision) && (!note || note.length < 3)) {
        return Response.json({ error: "a note is required for this recommendation" }, { status: 400 });
      }

      const { data: app } = await ctx.db
        .from("host_applications")
        .select("status")
        .eq("id", id)
        .maybeSingle();
      if (!app) return Response.json({ error: "not found" }, { status: 404 });

      const { data: row, error } = await ctx.db
        .from("host_application_reviews")
        .insert({
          application_id: id,
          reviewer_id: ctx.actorUserId,
          from_status: app.status,
          to_status: null,
          decision,
          checklist,
          note,
        })
        .select("id")
        .single();
      if (error) return Response.json({ error: error.message }, { status: 500 });

      ctx.audit({
        action: "host_application.recommend",
        entityType: "host_applications",
        entityId: id,
        after: { decision, review_id: row.id },
        reason: note ?? undefined,
      });
      return Response.json({ reviewId: row.id });
    },
    { mutating: true, action: "host_application.recommend" },
  )(req);
}
