import { withAdmin } from "@/lib/with-admin.server";

// User search. bookings:read (viewing a user's booking history is booking data).
// Per-user total spending + booking count are DERIVED. Country is NOT collected
// anywhere in the product today -> rendered absent, not invented.
export function GET(req: Request) {
  const term = new URL(req.url).searchParams.get("q")?.trim() ?? "";

  return withAdmin("bookings:read", async (ctx) => {
    let q = ctx.db
      .from("profiles")
      .select("id,full_name,phone,role,suspended_at,suspended_reason,created_at")
      .order("created_at", { ascending: false })
      .limit(50);
    if (term) q = q.or(`full_name.ilike.%${term}%,phone.ilike.%${term}%`);

    const { data: users, error } = await q;
    if (error) return Response.json({ error: error.message }, { status: 500 });

    const ids = (users ?? []).map((u) => u.id);
    const spend = new Map<string, { count: number; paisa: number }>();
    if (ids.length) {
      const { data: bookings } = await ctx.db
        .from("bookings")
        .select("user_id,total_paisa,status")
        .in("user_id", ids);
      for (const b of bookings ?? []) {
        const e = spend.get(b.user_id) ?? { count: 0, paisa: 0 };
        e.count += 1;
        if (b.status === "confirmed" || b.status === "completed") e.paisa += b.total_paisa ?? 0;
        spend.set(b.user_id, e);
      }
    }

    return Response.json({
      rows: (users ?? []).map((u) => ({
        id: u.id,
        name: u.full_name,
        phone: u.phone,
        role: u.role,
        country: null, // not collected — see REQUIREMENTS_DELTA N5
        suspendedAt: u.suspended_at,
        suspendedReason: u.suspended_reason,
        bookingCount: spend.get(u.id)?.count ?? 0,
        totalSpentNpr: Math.round((spend.get(u.id)?.paisa ?? 0) / 100),
        createdAt: u.created_at,
      })),
    });
  })(req);
}
