import { withAdmin } from "@/lib/with-admin.server";

// Queue list. hosts:review. Oldest submitted first.
export function GET(req: Request) {
  const url = new URL(req.url);
  const status = url.searchParams.get("status");

  return withAdmin("hosts:review", async (ctx) => {
    let q = ctx.db
      .from("host_applications")
      .select("id,user_id,status,title,location,category_id,submitted_at,created_at,reviewer_id,application_data")
      .order("submitted_at", { ascending: true, nullsFirst: false });
    if (status) q = q.eq("status", status);

    const { data: apps, error } = await q;
    if (error) return Response.json({ error: error.message }, { status: 500 });

    const ids = (apps ?? []).map((a) => a.id);
    const counts: Record<string, number> = {};
    if (ids.length) {
      const { data: docs } = await ctx.db
        .from("host_documents")
        .select("application_id")
        .in("application_id", ids);
      for (const d of docs ?? []) counts[d.application_id] = (counts[d.application_id] ?? 0) + 1;
    }

    return Response.json({
      rows: (apps ?? []).map((a) => ({
        id: a.id,
        status: a.status,
        title: a.title,
        location: a.location,
        hostingType: (a.application_data as Record<string, unknown> | null)?.hosting_type ?? null,
        fullName: (a.application_data as Record<string, unknown> | null)?.full_name ?? null,
        submittedAt: a.submitted_at,
        createdAt: a.created_at,
        reviewerId: a.reviewer_id,
        documentCount: counts[a.id] ?? 0,
      })),
    });
  })(req);
}
