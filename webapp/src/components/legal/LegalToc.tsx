type TocEntry = { id: string; text: string };

function List({ entries }: { entries: TocEntry[] }) {
  return (
    <ul className="space-y-1.5 text-sm">
      {entries.map((e) => (
        <li key={e.id}>
          <a
            href={`#${e.id}`}
            className="block text-[var(--color-ink)]/70 hover:text-[var(--color-forest)]"
          >
            {e.text}
          </a>
        </li>
      ))}
    </ul>
  );
}

/**
 * Section index for a legal document.
 *  - `variant="inline"`  → collapsible `<details>`, shown only below `lg`.
 *  - `variant="sidebar"` → sticky nav, shown only at `lg` (place in the aside).
 */
export function LegalToc({
  entries,
  variant,
}: {
  entries: TocEntry[];
  variant: "inline" | "sidebar";
}) {
  if (entries.length < 2) return null;

  if (variant === "inline") {
    return (
      <details className="mb-6 rounded-[var(--radius-sm)] border border-[var(--color-border-subtle)] p-3 lg:hidden">
        <summary className="cursor-pointer text-sm font-semibold text-[var(--color-forest)]">
          On this page
        </summary>
        <nav className="mt-3" aria-label="On this page">
          <List entries={entries} />
        </nav>
      </details>
    );
  }

  return (
    <nav
      className="sticky top-24 max-h-[calc(100vh-8rem)] overflow-y-auto"
      aria-label="On this page"
    >
      <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-[var(--color-ink)]/60">
        On this page
      </p>
      <List entries={entries} />
    </nav>
  );
}
