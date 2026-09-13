import { withAdmin } from "@/lib/with-admin.server";
import { isPrivatePhotoPath } from "@/lib/experience-review";

// On-demand short-lived signed URL for one private experience photo.
// content:manage. Verifies the path belongs to the experience.
export function GET(req: Request, { params }: { params: Promise<{ id: string }> }) {
  return withAdmin("content:manage", async (ctx) => {
    const { id } = await params;
    const path = new URL(req.url).searchParams.get("path");
    if (!path) return Response.json({ error: "path required" }, { status: 400 });

    const { data: exp } = await ctx.db
      .from("experiences")
      .select("gallery,cover_image_url")
      .eq("id", id)
      .maybeSingle();
    if (!exp) return Response.json({ error: "not found" }, { status: 404 });

    const gallery: string[] = Array.isArray(exp.gallery) ? exp.gallery : [];
    if (path !== exp.cover_image_url && !gallery.includes(path)) {
      return Response.json({ error: "path not part of this experience" }, { status: 400 });
    }
    if (!isPrivatePhotoPath(path)) {
      return Response.json({ url: path });
    }

    const { data, error } = await ctx.db.storage
      .from("experience-photos")
      .createSignedUrl(path, 600);
    if (error) return Response.json({ error: error.message }, { status: 500 });
    return Response.json({ url: data.signedUrl });
  })(req);
}
