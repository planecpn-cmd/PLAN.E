import { withAdmin } from "@/lib/with-admin.server";

// Reactivate a suspended user account. users:manage.
export function POST(req: Request, { params }: { params: Promise<{ id: string }> }) {
  return withAdmin(
    "users:manage",
    async (ctx) => {
      const { id } = await params;
      const reason =
        ((await req.json().catch(() => null)) as { reason?: string } | null)?.reason?.trim() || undefined;
      const { error } = await ctx.db.rpc("admin_reactivate_user", {
        p_user_id: id,
        p_actor: ctx.actorUserId,
      });
      if (error) return Response.json({ error: error.message }, { status: 400 });

      ctx.audit({
        action: "user.reactivate",
        entityType: "profiles",
        entityId: id,
        after: { suspended: false },
        reason,
      });
      return Response.json({ suspended: false });
    },
    { mutating: true, action: "user.reactivate" },
  )(req);
}
