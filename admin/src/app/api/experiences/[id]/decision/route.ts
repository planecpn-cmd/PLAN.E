import { withAdmin } from "@/lib/with-admin.server";
import {
  DECISION_TO_STATUS,
  isDecision,
  isDifficulty,
  isPrivatePhotoPath,
  notificationOutcome,
  promotedGallery,
  reasonRequired,
} from "@/lib/experience-review";
import { notifyExperienceDecision } from "@/lib/host-notifications";

const PRIVATE_BUCKET = "experience-photos";
const PUBLIC_BUCKET = "experience-photos-public";

// content:decide commits a decision on a pending_review listing.
//   approve          -> promote photos to the public bucket, set the public
//                       cover/gallery, normalise taxonomy, status = published
//   reject           -> status = draft, reason mandatory, private originals kept
//   request_changes  -> status = draft, reason mandatory, private originals kept
//   under_review     -> status unchanged, just a reviewer stamp
// Review row + admin_audit_log row on every path; host notification on the
// terminal ones (gated on HOST_DECISION_COPY).
export function POST(req: Request, { params }: { params: Promise<{ id: string }> }) {
  return withAdmin(
    "content:decide",
    async (ctx) => {
      const { id } = await params;
      const body = (await req.json().catch(() => null)) as
        | {
            decision?: string;
            note?: string;
            reasonCode?: string;
            checklist?: Record<string, unknown>;
            categoryId?: string;
            regionId?: string;
            difficulty?: string;
          }
        | null;

      const decision = body?.decision;
      const note = body?.note?.trim() || null;
      const reasonCode = body?.reasonCode?.trim() || null;
      const checklist = body?.checklist ?? {};

      if (!decision || !isDecision(decision)) {
        return Response.json(
          { error: "decision must be under_review | approve | reject | request_changes" },
          { status: 400 },
        );
      }
      if (reasonRequired(decision) && (!note || note.length < 3)) {
        return Response.json({ error: "a reason is required for this decision" }, { status: 400 });
      }

      const { data: exp } = await ctx.db
        .from("experiences")
        .select("id,host_id,status,gallery,cover_image_url,revision_of")
        .eq("id", id)
        .maybeSingle();
      if (!exp) return Response.json({ error: "not found" }, { status: 404 });
      if (exp.status !== "pending_review") {
        return Response.json(
          { error: `only a pending_review listing can be decided (status is ${exp.status})` },
          { status: 409 },
        );
      }
      const isRevision = exp.revision_of != null;

      const toStatus = DECISION_TO_STATUS[decision];
      const update: Record<string, unknown> = {
        status: toStatus,
        reviewer_id: ctx.actorUserId,
        updated_at: new Date().toISOString(),
      };

      if (decision === "approve") {
        const categoryId = body?.categoryId?.trim();
        const regionId = body?.regionId?.trim();
        const difficulty = body?.difficulty?.trim();
        if (!categoryId || !regionId || !difficulty || !isDifficulty(difficulty)) {
          return Response.json(
            { error: "categoryId, regionId and a valid difficulty are required to approve" },
            { status: 400 },
          );
        }

        // copy-on-approve: private originals -> public bucket, same object path.
        const sourceGallery: string[] = Array.isArray(exp.gallery) ? exp.gallery : [];
        if (sourceGallery.length === 0) {
          return Response.json({ error: "cannot approve a listing with no photos" }, { status: 400 });
        }
        for (const path of sourceGallery) {
          if (!isPrivatePhotoPath(path)) continue;
          const { error: copyErr } = await ctx.db.storage
            .from(PRIVATE_BUCKET)
            .copy(path, path, { destinationBucket: PUBLIC_BUCKET });
          // "already exists" on a re-run is not fatal — take the public URL anyway.
          if (copyErr && !/exist/i.test(copyErr.message)) {
            return Response.json(
              { error: `photo promotion failed for ${path}: ${copyErr.message}` },
              { status: 500 },
            );
          }
        }
        const publicGallery = promotedGallery(
          sourceGallery,
          (p) => ctx.db.storage.from(PUBLIC_BUCKET).getPublicUrl(p).data.publicUrl,
        );

        // ── approving a REVISION: swap it into the live row atomically ──
        if (isRevision) {
          const { data: liveId, error: applyErr } = await ctx.db.rpc(
            "admin_apply_experience_revision",
            {
              p_revision_id: id,
              p_reviewer: ctx.actorUserId,
              p: {
                cover: publicGallery[0],
                gallery: publicGallery,
                category_id: categoryId,
                region_id: regionId,
                difficulty,
              },
            },
          );
          if (applyErr) return Response.json({ error: applyErr.message }, { status: 500 });

          ctx.audit({
            action: "experience.decide",
            entityType: "experiences",
            entityId: id,
            before: { status: exp.status, revision_of: exp.revision_of },
            after: { status: "archived", applied_to: liveId, decision },
            reason: note ?? undefined,
          });

          const notified = await notifyExperienceDecision({
            db: ctx.db,
            userId: exp.host_id as string,
            experienceId: liveId as string,
            outcome: "approved",
          });
          return Response.json({ status: "archived", appliedTo: liveId, notified });
        }

        update.category_id = categoryId;
        update.region_id = regionId;
        update.difficulty = difficulty;
        update.gallery = publicGallery;
        update.cover_image_url = publicGallery[0];
      }

      const { error: upErr } = await ctx.db.from("experiences").update(update).eq("id", id);
      if (upErr) return Response.json({ error: upErr.message }, { status: 500 });

      const { data: row, error: revErr } = await ctx.db
        .from("experience_reviews")
        .insert({
          experience_id: id,
          reviewer_id: ctx.actorUserId,
          from_status: exp.status,
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
        action: "experience.decide",
        entityType: "experiences",
        entityId: id,
        before: { status: exp.status },
        after: { status: toStatus, decision, review_id: row.id },
        reason: note ?? undefined,
      });

      const outcome = notificationOutcome(decision);
      let notified: { sent: boolean; reason?: string } = { sent: false, reason: "not_applicable" };
      if (outcome) {
        notified = await notifyExperienceDecision({
          db: ctx.db,
          userId: exp.host_id as string,
          experienceId: id,
          outcome,
        });
      }

      return Response.json({ status: toStatus, reviewId: row.id, notified });
    },
    { mutating: true, action: "experience.decide" },
  )(req);
}
