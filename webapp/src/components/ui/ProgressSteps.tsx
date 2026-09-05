export function ProgressSteps({ steps, currentStep }: { steps: string[]; currentStep: number }) {
  return (
    <ol className="flex items-center">
      {steps.map((step, i) => (
        <li key={step} className="flex flex-1 items-center last:flex-none">
          <div className="flex flex-col items-center gap-1">
            <span
              className={`flex h-7 w-7 shrink-0 items-center justify-center rounded-full text-xs font-semibold ${
                i < currentStep
                  ? "bg-[var(--color-forest)] text-white"
                  : i === currentStep
                    ? "border-2 border-[var(--color-forest)] text-[var(--color-forest)]"
                    : "border border-[var(--color-border)] text-[var(--color-ink)]/70"
              }`}
            >
              {i < currentStep ? "✓" : i + 1}
            </span>
            <span className="whitespace-nowrap text-[11px] text-[var(--color-ink)]/70">{step}</span>
          </div>
          {i < steps.length - 1 && (
            <div className={`mx-2 h-px flex-1 ${i < currentStep ? "bg-[var(--color-forest)]" : "bg-[var(--color-border)]"}`} />
          )}
        </li>
      ))}
    </ol>
  );
}
