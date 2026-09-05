export function CounterField({
  label,
  value,
  onChange,
  min = 0,
  max = 20,
}: {
  label: string;
  value: number;
  onChange: (value: number) => void;
  min?: number;
  max?: number;
}) {
  return (
    <div className="flex items-center justify-between">
      <span className="text-sm font-medium">{label}</span>
      <div className="flex items-center gap-3 rounded-[var(--radius-pill)] border border-[var(--color-border)] px-1 py-1">
        <button
          type="button"
          aria-label={`Decrease ${label}`}
          onClick={() => onChange(Math.max(min, value - 1))}
          disabled={value <= min}
          className="flex h-8 w-8 items-center justify-center rounded-full text-lg font-semibold text-[var(--color-forest)] hover:bg-[var(--color-sage)] disabled:opacity-30"
        >
          −
        </button>
        <span className="w-6 text-center text-sm font-semibold">{value}</span>
        <button
          type="button"
          aria-label={`Increase ${label}`}
          onClick={() => onChange(Math.min(max, value + 1))}
          disabled={value >= max}
          className="flex h-8 w-8 items-center justify-center rounded-full text-lg font-semibold text-[var(--color-forest)] hover:bg-[var(--color-sage)] disabled:opacity-30"
        >
          +
        </button>
      </div>
    </div>
  );
}
