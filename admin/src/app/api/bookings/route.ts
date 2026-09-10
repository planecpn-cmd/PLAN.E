import { withAdmin } from "@/lib/with-admin.server";

// Bookings list. bookings:read. Filters: status, experience, from/to (created_at).
export function GET(req: Request) {
  const url = new URL(req.url);
  return withAdmin("bookings:read", async (ctx) => {
    let q = ctx.db
      .from("bookings")
      .select(
        "id,booking_ref,user_id,experience_id,status,adults,children,total_paisa,contact_name,contact_phone,created_at,cancelled_at,completed_at",
      )
      .order("created_at", { ascending: false })
      .limit(200);

    const status = url.searchParams.get("status");
    const experience = url.searchParams.get("experience");
    const from = url.searchParams.get("from");
    const to = url.searchParams.get("to");
    if (status) q = q.eq("status", status);
    if (experience) q = q.eq("experience_id", experience);
    if (from) q = q.gte("created_at", from);
    if (to) q = q.lte("created_at", to);

    const { data, error } = await q;
    if (error) return Response.json({ error: error.message }, { status: 500 });
    return Response.json({
      rows: (data ?? []).map((b) => ({
        id: b.id,
        ref: b.booking_ref,
        userId: b.user_id,
        experienceId: b.experience_id,
        status: b.status,
        people: (b.adults ?? 0) + (b.children ?? 0),
        totalNpr: Math.round((b.total_paisa ?? 0) / 100),
        contactName: b.contact_name,
        contactPhone: b.contact_phone,
        createdAt: b.created_at,
        cancelledAt: b.cancelled_at,
        completedAt: b.completed_at,
      })),
    });
  })(req);
}
