import { withAdmin } from "@/lib/with-admin.server";

// Experience review queue. content:manage. Oldest first.
export function GET(req: Request) {
  const url = new URL(req.url);
  const status = url.searchParams.get("status") ?? "pending_review";

  return withAdmin("content:manage", async (ctx) => {
    let q = ctx.db
      .from("experiences")
      .select(
        "id,host_id,title,slug,status,location_name,category_id,region_id,difficulty,price_paisa,created_at,updated_at,reviewer_id",
      )
      .order("updated_at", { ascending: true });
    if (status !== "all") q = q.eq("status", status);

    const { data: rows, error } = await q;
    if (error) return Response.json({ error: error.message }, { status: 500 });

    return Response.json({
      rows: (rows ?? []).map((r) => ({
        id: r.id,
        hostId: r.host_id,
        title: r.title,
        slug: r.slug,
        status: r.status,
        location: r.location_name,
        priceNpr: Math.round((r.price_paisa ?? 0) / 100),
        categoryId: r.category_id,
        regionId: r.region_id,
        difficulty: r.difficulty,
        reviewerId: r.reviewer_id,
        submittedAt: r.updated_at,
        createdAt: r.created_at,
      })),
    });
  })(req);
}
