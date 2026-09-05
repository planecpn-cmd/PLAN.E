import type { ReactNode } from "react";

export function EmptyState({
  title,
  description,
  action,
}: {
  title: string;
  description?: string;
  action?: ReactNode;
}) {
  return (
    <div className="flex flex-col items-center gap-2 rounded-[var(--radius-md)] border border-dashed border-[var(--color-border)] px-6 py-16 text-center">
      <p className="font-[family-name:var(--font-display)] text-lg font-semibold">{title}</p>
      {description && <p className="max-w-sm text-sm text-[var(--color-ink)]/70">{description}</p>}
      {action}
    </div>
  );
}
