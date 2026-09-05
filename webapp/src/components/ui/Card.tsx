import type { HTMLAttributes } from "react";

export interface CardProps extends HTMLAttributes<HTMLDivElement> {
  padded?: boolean;
  hoverable?: boolean;
}

export function Card({ padded = true, hoverable, className = "", children, ...rest }: CardProps) {
  return (
    <div
      className={`rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-card)] ${
        padded ? "p-4" : ""
      } ${hoverable ? "transition-shadow duration-200 hover:shadow-[0_8px_24px_rgba(1,37,28,0.08)]" : ""} ${className}`}
      {...rest}
    >
      {children}
    </div>
  );
}
