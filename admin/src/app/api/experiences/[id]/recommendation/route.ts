import { withAdmin } from "@/lib/with-admin.server";
import { isRecommendation, reasonRequired } from "@/lib/experience-review";

// content:manage records a recommendation. No status change — review recommends,
// content:decide commits.
export function POST(req: Request, { params }: { params: Promise<{ id: string }> }) {
  return withAdmin(
    "content:manage",
    async (ctx) => {
      const { id } = await params;
      const body = (await req.json().catch(() => null)) as
        | { decision?: string; note?: string; checklist?: Record<string, unknown> }
        | null;

      const decision = body?.decision;
      const note = body?.note?.trim() || null;
      const checklist = body?.checklist ?? {};

      if (!decision || !isRecommendation(decision)) {
        return Response.json(
          { error: "decision must be recommend_approve | recommend_reject | recommend_changes" },
          { status: 400 },
        );
      }
      if (reasonRequired(decision) && (!note || note.length < 3)) {
        return Response.json({ error: "a note is required for this recommendation" }, { status: 400 });
      }

      const { data: exp } = await ctx.db
        .from("experiences")
        .select("status")
        .eq("id", id)
        .maybeSingle();
      if (!exp) return Response.json({ error: "not found" }, { status: 404 });

      const { data: row, error } = await ctx.db
        .from("experience_reviews")
        .insert({
          experience_id: id,
          reviewer_id: ctx.actorUserId,
          from_status: exp.status,
          to_status: null,
          decision,
          checklist,
          note,
        })
        .select("id")
        .single();
      if (error) return Response.json({ error: error.message }, { status: 500 });

      ctx.audit({
        action: "experience.recommend",
        entityType: "experiences",
        entityId: id,
        after: { decision, review_id: row.id },
        reason: note ?? undefined,
      });
      return Response.json({ reviewId: row.id });
    },
    { mutating: true, action: "experience.recommend" },
  )(req);
}
