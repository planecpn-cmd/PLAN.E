import { withAdmin } from "@/lib/with-admin.server";

// Mint a short-lived signed URL for one private host document, on demand.
// hosts:review. Not audited (read).
export function GET(
  req: Request,
  { params }: { params: Promise<{ id: string; docId: string }> },
) {
  return withAdmin("hosts:review", async (ctx) => {
    const { id, docId } = await params;
    const { data: doc } = await ctx.db
      .from("host_documents")
      .select("storage_path")
      .eq("id", docId)
      .eq("application_id", id)
      .maybeSingle();
    if (!doc) return Response.json({ error: "not found" }, { status: 404 });

    const { data, error } = await ctx.db.storage
      .from("host-documents")
      .createSignedUrl(doc.storage_path, 300);
    if (error || !data?.signedUrl) {
      return Response.json({ error: error?.message ?? "could not sign" }, { status: 500 });
    }
    return Response.json({ url: data.signedUrl });
  })(req);
}
