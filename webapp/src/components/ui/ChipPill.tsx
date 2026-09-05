import type { ButtonHTMLAttributes } from "react";

export interface ChipPillProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  active?: boolean;
}

export function ChipPill({ active, className = "", children, ...rest }: ChipPillProps) {
  return (
    <button
      type="button"
      aria-pressed={active}
      className={`inline-flex shrink-0 items-center gap-1.5 rounded-[var(--radius-pill)] border px-4 py-2 text-sm font-medium transition-colors duration-150 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-gold)] ${
        active
          ? "border-[var(--color-forest)] bg-[var(--color-forest)] text-white"
          : "border-[var(--color-border)] bg-white text-[var(--color-ink)] hover:bg-[var(--color-sage)]"
      } ${className}`}
      {...rest}
    >
      {children}
    </button>
  );
}
