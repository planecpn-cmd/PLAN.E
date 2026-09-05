import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { getLegalDocument } from "@/lib/data/legal";
import { extractToc } from "@/lib/legal";
import { LegalMarkdown } from "@/components/legal/LegalMarkdown";
import { LegalToc } from "@/components/legal/LegalToc";

export const revalidate = 3600;

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<Metadata> {
  const { slug } = await params;
  const doc = await getLegalDocument(slug);
  if (!doc) return { title: "Not found — PLAN E" };
  const url = `https://planenepal.com/legal/${doc.slug}`;
  return {
    title: `${doc.title} — PLAN E`,
    description: `${doc.title} for PLAN E. Version ${doc.version}, effective ${new Date(
      doc.effective_at,
    ).toLocaleDateString("en-GB", { day: "numeric", month: "long", year: "numeric" })}.`,
    alternates: { canonical: url },
    openGraph: { title: doc.title, url, type: "article" },
  };
}

export default async function LegalDocumentPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const doc = await getLegalDocument(slug);
  if (!doc) notFound();

  const toc = extractToc(doc.body_md);
  const effective = new Date(doc.effective_at).toLocaleDateString("en-GB", {
    day: "numeric",
    month: "long",
    year: "numeric",
  });

  return (
    <div className="mx-auto max-w-[1100px] px-6 py-12">
      <div className="grid gap-10 lg:grid-cols-[1fr_240px] lg:items-start">
        <article className="max-w-[720px]">
          <p className="text-xs uppercase tracking-wide text-[var(--color-ink)]/55">
            PLAN E
          </p>
          <h1 className="mt-1 font-[family-name:var(--font-display)] text-3xl font-bold text-[var(--color-deep)]">
            {doc.title}
          </h1>
          <p className="mt-2 text-sm text-[var(--color-ink)]/60">
            Version {doc.version} · Effective {effective}
          </p>
          <hr className="my-6 border-[var(--color-border-subtle)]" />
          <LegalToc entries={toc} variant="inline" />
          <LegalMarkdown body={doc.body_md} />
        </article>

        <aside className="hidden lg:block">
          <LegalToc entries={toc} variant="sidebar" />
        </aside>
      </div>
    </div>
  );
}
