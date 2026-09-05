import Link from "next/link";
import { Logo } from "@/components/ui/Logo";

/**
 * Standalone chrome for /legal — these pages must render for anonymous
 * visitors, search engines and app-store reviewers without the app nav.
 */
export default function LegalLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-full flex-col">
      <header className="border-b border-[var(--color-border-subtle)] bg-[var(--color-ivory)]">
        <div className="mx-auto flex max-w-[1100px] items-center justify-between px-6 py-4">
          <Link href="/" aria-label="PLAN E home">
            <Logo size={18} />
          </Link>
          <Link
            href="/legal"
            className="text-sm font-medium text-[var(--color-forest)] hover:underline"
          >
            All policies
          </Link>
        </div>
      </header>
      <main className="flex-1">{children}</main>
      <footer className="border-t border-[var(--color-border-subtle)] bg-[var(--color-card-alt)]">
        <div className="mx-auto max-w-[1100px] px-6 py-6 text-sm text-[var(--color-ink)]/70">
          &copy; {new Date().getFullYear()} PLAN E Nepal ·{" "}
          <Link href="/legal" className="hover:text-[var(--color-forest)]">
            Legal &amp; Policies
          </Link>
        </div>
      </footer>
    </div>
  );
}
