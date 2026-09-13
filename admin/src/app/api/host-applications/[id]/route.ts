import { withAdmin } from "@/lib/with-admin.server";

// Application detail: the row, its documents (with short-lived signed URLs), and
// the full recommendation/decision history. hosts:review.
export function GET(req: Request, { params }: { params: Promise<{ id: string }> }) {
  return withAdmin("hosts:review", async (ctx) => {
    const { id } = await params;

    const { data: app, error } = await ctx.db
      .from("host_applications")
      .select("*")
      .eq("id", id)
      .maybeSingle();
    if (error) return Response.json({ error: error.message }, { status: 500 });
    if (!app) return Response.json({ error: "not found" }, { status: 404 });

    const { data: documents } = await ctx.db
      .from("host_documents")
      .select("id,kind,storage_path,mime,size_bytes,verified_by,verified_at,rejection_reason,uploaded_at")
      .eq("application_id", id)
      .order("kind");

    // signed URLs generated server-side; the host-documents bucket is private.
    const signed: Record<string, string | null> = {};
    for (const d of documents ?? []) {
      const { data } = await ctx.db.storage
        .from("host-documents")
        .createSignedUrl(d.storage_path, 300);
      signed[d.id] = data?.signedUrl ?? null;
    }

    const { data: reviews } = await ctx.db
      .from("host_application_reviews")
      .select("id,reviewer_id,from_status,to_status,decision,note,reason_code,checklist,created_at")
      .eq("application_id", id)
      .order("created_at", { ascending: false });

    return Response.json({
      application: app,
      documents: (documents ?? []).map((d) => ({ ...d, signedUrl: signed[d.id] ?? null })),
      reviews: reviews ?? [],
    });
  })(req);
}
