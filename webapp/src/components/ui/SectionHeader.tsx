import Link from "next/link";

export function SectionHeader({
  title,
  subtitle,
  actionLabel,
  actionHref,
}: {
  title: string;
  subtitle?: string;
  actionLabel?: string;
  actionHref?: string;
}) {
  return (
    <div className="flex items-end justify-between gap-4">
      <div>
        <h2 className="font-[family-name:var(--font-display)] text-xl font-semibold text-[var(--color-ink)] lg:text-2xl">
          {title}
        </h2>
        {subtitle && <p className="mt-1 text-sm text-[var(--color-ink)]/70">{subtitle}</p>}
      </div>
      {actionLabel && actionHref && (
        <Link href={actionHref} className="shrink-0 text-sm font-semibold text-[var(--color-forest)] hover:underline">
          {actionLabel}
        </Link>
      )}
    </div>
  );
}
