"use client";

import { forwardRef, useId, useState } from "react";
import type { InputHTMLAttributes } from "react";
import { Icon, type IconName } from "@/components/ui/Icon";

export interface TextFieldProps extends InputHTMLAttributes<HTMLInputElement> {
  label: string;
  icon?: IconName;
  error?: string;
}

export const TextField = forwardRef<HTMLInputElement, TextFieldProps>(function TextField(
  { label, icon, error, type = "text", id, className = "", ...rest },
  ref,
) {
  const generatedId = useId();
  const inputId = id ?? generatedId;
  const errorId = `${inputId}-error`;
  const [visible, setVisible] = useState(false);
  const isPassword = type === "password";

  return (
    <div>
      <label htmlFor={inputId} className="mb-1.5 block text-sm font-medium text-[var(--color-ink)]">
        {label}
      </label>
      <div className="relative flex items-center">
        {icon && <Icon name={icon} className="pointer-events-none absolute left-3.5 text-[var(--color-ink)]/70" />}
        <input
          ref={ref}
          id={inputId}
          type={isPassword && visible ? "text" : type}
          aria-invalid={!!error}
          aria-describedby={error ? errorId : undefined}
          className={`w-full rounded-[var(--radius-sm)] border border-[var(--color-border)] bg-white py-3 text-[var(--color-ink)] outline-none focus:border-[var(--color-forest)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-1 focus-visible:outline-[var(--color-gold)] ${
            icon ? "pl-11" : "pl-3.5"
          } ${isPassword ? "pr-11" : "pr-3.5"} ${className}`}
          {...rest}
        />
        {isPassword && (
          <button
            type="button"
            onClick={() => setVisible((v) => !v)}
            aria-label={visible ? "Hide password" : "Show password"}
            className="absolute right-3.5 text-[var(--color-ink)]/70 hover:text-[var(--color-ink)]"
          >
            <Icon name={visible ? "eyeOff" : "eye"} size={18} />
          </button>
        )}
      </div>
      {error && (
        <p id={errorId} className="mt-1.5 text-sm text-[var(--color-error)]">
          {error}
        </p>
      )}
    </div>
  );
});
