export function ErrorState({ message = "Something went wrong" }: { message?: string }) {
  return (
    <div className="flex flex-col items-center gap-2 rounded-[var(--radius-md)] border border-[var(--color-error-container)] bg-[var(--color-error-container)]/40 px-6 py-16 text-center">
      <p className="font-[family-name:var(--font-display)] text-lg font-semibold text-[var(--color-error)]">
        Something went wrong
      </p>
      <p className="max-w-sm text-sm text-[var(--color-ink)]/70">{message}</p>
    </div>
  );
}
