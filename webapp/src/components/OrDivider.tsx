export function OrDivider({ label = "OR" }: { label?: string }) {
  return (
    <div className="my-5 flex items-center gap-3 text-xs font-medium text-[var(--color-ink)]/50">
      <span className="h-px flex-1 bg-[var(--color-border)]" />
      {label}
      <span className="h-px flex-1 bg-[var(--color-border)]" />
    </div>
  );
}
