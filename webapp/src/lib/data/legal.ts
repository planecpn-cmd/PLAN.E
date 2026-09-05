import { createClient } from "@/lib/supabase/server";
import { LEGAL_DOC_ORDER, type LegalDocument } from "@/lib/legal";

function sortByOrder(docs: LegalDocument[]): LegalDocument[] {
  const rank = (slug: string) => {
    const i = (LEGAL_DOC_ORDER as readonly string[]).indexOf(slug);
    return i === -1 ? LEGAL_DOC_ORDER.length : i;
  };
  return [...docs].sort(
    (a, b) => rank(a.slug) - rank(b.slug) || a.title.localeCompare(b.title),
  );
}

/** All current legal documents (locale `en`), in display order. */
export async function getCurrentLegalDocuments(): Promise<LegalDocument[]> {
  const supabase = await createClient();
  const { data } = await supabase
    .from("legal_documents")
    .select("*")
    .eq("is_current", true)
    .eq("locale", "en");
  return sortByOrder((data as LegalDocument[] | null) ?? []);
}

/** One current document by slug, or null when it is not published. */
export async function getLegalDocument(slug: string): Promise<LegalDocument | null> {
  const supabase = await createClient();
  const { data } = await supabase
    .from("legal_documents")
    .select("*")
    .eq("slug", slug)
    .eq("locale", "en")
    .eq("is_current", true)
    .maybeSingle();
  return (data as LegalDocument | null) ?? null;
}
