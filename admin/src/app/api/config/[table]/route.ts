import { withAdmin } from "@/lib/with-admin.server";

// Config read/write for the four remote-config tables. These already have
// is_admin() RLS and a config_audit_log trigger (context §9.6), so a PATCH here
// lands in BOTH config_audit_log (DB trigger) and admin_audit_log (withAdmin).

const TABLES = ["feature_flags", "app_config", "remote_content", "app_versions"] as const;
type ConfigTable = (typeof TABLES)[number];
const KEY_COLUMN: Record<ConfigTable, string> = {
  feature_flags: "key",
  app_config: "key",
  remote_content: "slot",
  app_versions: "platform",
};

function isTable(v: string): v is ConfigTable {
  return (TABLES as readonly string[]).includes(v);
}

export async function GET(req: Request, { params }: { params: Promise<{ table: string }> }) {
  const { table } = await params;
  if (!isTable(table)) return Response.json({ error: "unknown table" }, { status: 404 });

  return withAdmin("content:manage", async (ctx) => {
    const { data, error } = await ctx.db.from(table).select("*").order(KEY_COLUMN[table]);
    if (error) return Response.json({ error: error.message }, { status: 500 });
    return Response.json({ rows: data ?? [] });
  })(req);
}

export async function PATCH(req: Request, { params }: { params: Promise<{ table: string }> }) {
  const { table } = await params;
  if (!isTable(table)) return Response.json({ error: "unknown table" }, { status: 404 });
  const keyCol = KEY_COLUMN[table];

  return withAdmin(
    "content:manage",
    async (ctx) => {
      const body = (await req.json().catch(() => null)) as
        | { key?: string; patch?: Record<string, unknown>; reason?: string }
        | null;

      const key = body?.key?.trim();
      const patch = body?.patch;
      const reason = body?.reason?.trim();

      if (!key || !patch || typeof patch !== "object") {
        return Response.json({ error: "key and patch are required" }, { status: 400 });
      }
      if (!reason || reason.length < 3) {
        return Response.json({ error: "a reason is required" }, { status: 400 });
      }
      // never let the caller move the row identity
      if (keyCol in patch) {
        return Response.json({ error: `cannot change ${keyCol}` }, { status: 400 });
      }

      const { data: before } = await ctx.db.from(table).select("*").eq(keyCol, key).maybeSingle();
      if (!before) return Response.json({ error: "row not found" }, { status: 404 });

      const { data: after, error } = await ctx.db
        .from(table)
        .update(patch)
        .eq(keyCol, key)
        .select("*")
        .single();
      if (error) return Response.json({ error: error.message }, { status: 500 });

      ctx.audit({
        action: "config.update",
        entityType: table,
        entityId: key,
        before,
        after,
        reason,
      });
      return Response.json({ row: after });
    },
    { mutating: true, action: "config.update" },
  )(req);
}
