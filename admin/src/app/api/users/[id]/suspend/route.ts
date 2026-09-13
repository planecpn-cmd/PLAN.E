import { withAdmin } from "@/lib/with-admin.server";

// Suspend a user account (traveler or host). users:manage. One action —
// "block" vs "suspend" is founder question 7, unanswered. Named action +
// mandatory reason -> admin_audit_log.
export function POST(req: Request, { params }: { params: Promise<{ id: string }> }) {
  return withAdmin(
    "users:manage",
    async (ctx) => {
      const { id } = await params;
      const reason = ((await req.json().catch(() => null)) as { reason?: string } | null)?.reason?.trim();
      if (!reason || reason.length < 3) {
        return Response.json({ error: "a suspension reason is required" }, { status: 400 });
      }
      const { error } = await ctx.db.rpc("admin_suspend_user", {
        p_user_id: id,
        p_actor: ctx.actorUserId,
        p_reason: reason,
      });
      if (error) return Response.json({ error: error.message }, { status: 400 });

      ctx.audit({
        action: "user.suspend",
        entityType: "profiles",
        entityId: id,
        after: { suspended: true },
        reason,
      });
      return Response.json({ suspended: true });
    },
    { mutating: true, action: "user.suspend" },
  )(req);
}
