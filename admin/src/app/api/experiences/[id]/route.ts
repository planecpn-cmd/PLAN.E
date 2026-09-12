import { withAdmin } from "@/lib/with-admin.server";
import { isPrivatePhotoPath } from "@/lib/experience-review";

// Experience detail: the row as the host submitted it, its departure + itinerary,
// short-lived signed URLs for the private photos, and the review history.
// content:manage.
export function GET(req: Request, { params }: { params: Promise<{ id: string }> }) {
  return withAdmin("content:manage", async (ctx) => {
    const { id } = await params;

    const { data: exp, error } = await ctx.db
      .from("experiences")
      .select("*")
      .eq("id", id)
      .maybeSingle();
    if (error) return Response.json({ error: error.message }, { status: 500 });
    if (!exp) return Response.json({ error: "not found" }, { status: 404 });

    const { data: departures } = await ctx.db
      .from("experience_departures")
      .select("id,start_date,end_date,total_spots,spots_left,status")
      .eq("experience_id", id)
      .order("start_date");

    const { data: itinerary } = await ctx.db
      .from("itinerary_items")
      .select("day_number,title,description,sort_order")
      .eq("experience_id", id)
      .order("day_number");

    const gallery: string[] = Array.isArray(exp.gallery) ? exp.gallery : [];
    const photos: { path: string; url: string | null; promoted: boolean }[] = [];
    for (const path of gallery) {
      if (!isPrivatePhotoPath(path)) {
        photos.push({ path, url: path, promoted: true });
        continue;
      }
      const { data } = await ctx.db.storage
        .from("experience-photos")
        .createSignedUrl(path, 600);
      photos.push({ path, url: data?.signedUrl ?? null, promoted: false });
    }

    const { data: reviews } = await ctx.db
      .from("experience_reviews")
      .select("id,reviewer_id,from_status,to_status,decision,note,reason_code,checklist,created_at")
      .eq("experience_id", id)
      .order("created_at", { ascending: false });

    return Response.json({ experience: exp, departures: departures ?? [], itinerary: itinerary ?? [], photos, reviews: reviews ?? [] });
  })(req);
}
