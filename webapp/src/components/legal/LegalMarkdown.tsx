import Link from "next/link";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import { slugifyHeading } from "@/lib/legal";

/** Extracts the plain-text content of a React node tree (for heading ids). */
function nodeText(node: React.ReactNode): string {
  if (typeof node === "string" || typeof node === "number") return String(node);
  if (Array.isArray(node)) return node.map(nodeText).join("");
  if (node && typeof node === "object" && "props" in node) {
    // @ts-expect-error - runtime shape from react-markdown children
    return nodeText(node.props?.children);
  }
  return "";
}

/**
 * Server-rendered Markdown for legal documents. Styled with the PLAN E tokens —
 * serif (Playfair) headings, sans (Inter) body. H2s get slug ids so the
 * table-of-contents can link to them. Internal `/legal/...` links use next/link.
 */
export function LegalMarkdown({ body }: { body: string }) {
  return (
    <div className="legal-prose">
      <ReactMarkdown
        remarkPlugins={[remarkGfm]}
        components={{
          h1: ({ children }) => (
            <h1 className="mt-8 mb-3 font-[family-name:var(--font-display)] text-[28px] font-bold text-[var(--color-deep)]">
              {children}
            </h1>
          ),
          h2: ({ children }) => {
            const id = slugifyHeading(nodeText(children));
            return (
              <h2
                id={id}
                className="mt-10 mb-3 scroll-mt-24 font-[family-name:var(--font-display)] text-xl font-semibold text-[var(--color-forest)]"
              >
                {children}
              </h2>
            );
          },
          h3: ({ children }) => (
            <h3 className="mt-6 mb-2 font-[family-name:var(--font-display)] text-base font-bold text-[var(--color-forest)]">
              {children}
            </h3>
          ),
          p: ({ children }) => (
            <p className="my-3 text-[16px] leading-[1.7] text-[var(--color-ink)]">{children}</p>
          ),
          ul: ({ children }) => <ul className="my-3 list-disc space-y-1.5 pl-6">{children}</ul>,
          ol: ({ children }) => <ol className="my-3 list-decimal space-y-1.5 pl-6">{children}</ol>,
          li: ({ children }) => <li className="text-[16px] leading-[1.7]">{children}</li>,
          blockquote: ({ children }) => (
            <blockquote className="my-4 rounded-[var(--radius-sm)] border-l-[3px] border-[var(--color-gold)] bg-[var(--color-sage)] px-4 py-2 text-[15px]">
              {children}
            </blockquote>
          ),
          a: ({ href, children }) => {
            const isInternal = href?.startsWith("/") ?? false;
            if (isInternal) {
              return (
                <Link
                  href={href!}
                  className="font-medium text-[var(--color-gold)] underline underline-offset-2"
                >
                  {children}
                </Link>
              );
            }
            return (
              <a
                href={href}
                className="font-medium text-[var(--color-gold)] underline underline-offset-2"
                {...(href?.startsWith("http")
                  ? { target: "_blank", rel: "noopener noreferrer" }
                  : {})}
              >
                {children}
              </a>
            );
          },
          hr: () => <hr className="my-8 border-[var(--color-border-subtle)]" />,
          table: ({ children }) => (
            <div className="my-5 overflow-x-auto">
              <table className="w-full border-collapse text-[14px]">{children}</table>
            </div>
          ),
          thead: ({ children }) => <thead className="bg-[var(--color-sage)]">{children}</thead>,
          th: ({ children }) => (
            <th className="border border-[var(--color-border)] px-3 py-2 text-left font-semibold">
              {children}
            </th>
          ),
          td: ({ children }) => (
            <td className="border border-[var(--color-border)] px-3 py-2 align-top">{children}</td>
          ),
        }}
      >
        {body}
      </ReactMarkdown>
    </div>
  );
}
