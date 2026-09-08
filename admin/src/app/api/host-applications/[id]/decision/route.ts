import { withAdmin } from "@/lib/with-admin.server";
import {
  DECISION_TO_STATUS,
  isDecision,
  notificationOutcome,
  reasonRequired,
} from "@/lib/host-review";
import { notifyHostDecision } from "@/lib/host-notifications";

// hosts:decide commits a decision: it inserts the review row AND moves
// host_applications.status (via the service-role client — the client-role
// status trigger and RLS both refuse a direct-JWT status change). Approve /
// reject then fire the existing sync_host_account_from_application trigger.
export function POST(req: Request, { params }: { params: Promise<{ id: string }> }) {
  return withAdmin(
    "hosts:decide",
    async (ctx) => {
      const { id } = await params;
      const body = (await req.json().catch(() => null)) as
        | { decision?: string; note?: string; reasonCode?: string; checklist?: Record<string, unknown> }
        | null;

      const decision = body?.decision;
      const note = body?.note?.trim() || null;
      const reasonCode = body?.reasonCode?.trim() || null;
      const checklist = body?.checklist ?? {};

      if (!decision || !isDecision(decision)) {
        return Response.json({ error: "decision must be under_review | approve | reject | request_changes" }, { status: 400 });
      }
      if (reasonRequired(decision) && (!note || note.length < 3)) {
        return Response.json({ error: "a reason is required for this decision" }, { status: 400 });
      }

      const { data: app } = await ctx.db
        .from("host_applications")
        .select("id,user_id,status")
        .eq("id", id)
        .maybeSingle();
      if (!app) return Response.json({ error: "not found" }, { status: 404 });

      const toStatus = DECISION_TO_STATUS[decision];

      // status transition + reviewer stamp (service-role; the trigger allows it)
      const { error: upErr } = await ctx.db
        .from("host_applications")
        .update({
          status: toStatus,
          reviewer_id: ctx.actorUserId,
          reviewed_at: new Date().toISOString(),
          reviewer_note: note,
        })
        .eq("id", id);
      if (upErr) return Response.json({ error: upErr.message }, { status: 500 });

      const { data: row, error: revErr } = await ctx.db
        .from("host_application_reviews")
        .insert({
          application_id: id,
          reviewer_id: ctx.actorUserId,
          from_status: app.status,
          to_status: toStatus,
          decision,
          checklist,
          note,
          reason_code: reasonCode,
        })
        .select("id")
        .single();
      if (revErr) return Response.json({ error: revErr.message }, { status: 500 });

      ctx.audit({
        action: "host_application.decide",
        entityType: "host_applications",
        entityId: id,
        before: { status: app.status },
        after: { status: toStatus, decision, review_id: row.id },
        reason: note ?? undefined,
      });

      // ── notification path — no-ops until HOST_DECISION_COPY is filled ──
      const outcome = notificationOutcome(decision);
      let notified: { sent: boolean; reason?: string } = { sent: false, reason: "not_applicable" };
      if (outcome) {
        notified = await notifyHostDecision({
          db: ctx.db,
          userId: app.user_id,
          applicationId: id,
          outcome,
        });
      }

      return Response.json({ status: toStatus, reviewId: row.id, notified });
    },
    { mutating: true, action: "host_application.decide" },
  )(req);
}
