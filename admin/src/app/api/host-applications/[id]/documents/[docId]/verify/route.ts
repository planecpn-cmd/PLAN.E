import { withAdmin } from "@/lib/with-admin.server";

// Mark one document verified or rejected. This is review work, not the final
// decision — hosts:review.
export function POST(
  req: Request,
  { params }: { params: Promise<{ id: string; docId: string }> },
) {
  return withAdmin(
    "hosts:review",
    async (ctx) => {
      const { id, docId } = await params;
      const body = (await req.json().catch(() => null)) as
        | { verified?: boolean; rejectionReason?: string }
        | null;

      if (typeof body?.verified !== "boolean") {
        return Response.json({ error: "verified (boolean) is required" }, { status: 400 });
      }
      const rejectionReason = body.rejectionReason?.trim() || null;
      if (!body.verified && (!rejectionReason || rejectionReason.length < 3)) {
        return Response.json({ error: "a rejection reason is required" }, { status: 400 });
      }

      const { data: doc } = await ctx.db
        .from("host_documents")
        .select("id,application_id,verified_at,rejection_reason")
        .eq("id", docId)
        .eq("application_id", id)
        .maybeSingle();
      if (!doc) return Response.json({ error: "not found" }, { status: 404 });

      const { error } = await ctx.db
        .from("host_documents")
        .update({
          verified_by: body.verified ? ctx.actorUserId : null,
          verified_at: body.verified ? new Date().toISOString() : null,
          rejection_reason: body.verified ? null : rejectionReason,
        })
        .eq("id", docId);
      if (error) return Response.json({ error: error.message }, { status: 500 });

      ctx.audit({
        action: "host_document.verify",
        entityType: "host_documents",
        entityId: docId,
        before: { verified_at: doc.verified_at, rejection_reason: doc.rejection_reason },
        after: { verified: body.verified, rejection_reason: rejectionReason },
        reason: rejectionReason ?? undefined,
      });
      return Response.json({ ok: true });
    },
    { mutating: true, action: "host_document.verify" },
  )(req);
}
