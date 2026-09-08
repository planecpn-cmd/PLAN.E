import Link from "next/link";
import type { Scope } from "@/lib/scopes";

// Nav is rendered from the session's scopes. A staff member without a scope
// never sees the link; hitting the URL directly is still refused by the page
// (requireScope) and by withAdmin for its API routes — both layers.
const NAV: { href: string; label: string; scope: Scope }[] = [
  { href: "/config", label: "Config & feature flags", scope: "content:manage" },
  // host review, bookings, payments, finance screens land in P2 / P3.
];

export function AdminShell({
  scopes,
  email,
  children,
}: {
  scopes: Scope[];
  email: string | null;
  children: React.ReactNode;
}) {
  const links = NAV.filter((n) => scopes.includes(n.scope));
  return (
    <div className="mx-auto flex min-h-full max-w-6xl gap-8 px-6 py-8">
      <aside className="w-56 shrink-0">
        <div className="text-lg font-bold text-[var(--color-forest)]">Plan E Admin</div>
        <div className="mt-1 truncate text-xs text-[var(--color-ink)]/60">{email}</div>
        <nav className="mt-6 flex flex-col gap-1">
          <Link href="/" className="rounded-md px-3 py-2 text-sm hover:bg-[var(--color-sage)]">
            Dashboard
          </Link>
          {links.map((n) => (
            <Link
              key={n.href}
              href={n.href}
              className="rounded-md px-3 py-2 text-sm hover:bg-[var(--color-sage)]"
            >
              {n.label}
            </Link>
          ))}
        </nav>
        <form action="/auth/signout" method="post" className="mt-8">
          <button className="text-xs text-[var(--color-error)] hover:underline" type="submit">
            Sign out
          </button>
        </form>
      </aside>
      <main className="min-w-0 flex-1">{children}</main>
    </div>
  );
}
