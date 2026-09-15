"use client";

import { useState } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import type { Scope } from "@/lib/scopes";

// Nav is rendered from the session's scopes. A staff member without a scope
// never sees the link; hitting the URL directly is still refused by the page
// (requireScope) and by withAdmin for its API routes -- both layers.
// Only items with a real backing screen -- Reviews/Enquiries/Reports have no
// table or page yet (REQUIREMENTS_DELTA N4/N6), a dead link is worse than an
// absent one.
const NAV: { href: string; label: string; scope: Scope | null }[] = [
  { href: "/", label: "Dashboard", scope: null },
  { href: "/users", label: "Users", scope: "users:manage" },
  { href: "/host-applications", label: "Hosts", scope: "hosts:review" },
  { href: "/experiences", label: "Experiences", scope: "content:manage" },
  { href: "/bookings", label: "Bookings", scope: "bookings:read" },
  { href: "/payments", label: "Payments", scope: "payments:read" },
  { href: "/config", label: "Settings", scope: "content:manage" },
];

function NavLinks({ scopes, onNavigate }: { scopes: Scope[]; onNavigate?: () => void }) {
  const pathname = usePathname();
  const links = NAV.filter((n) => n.scope === null || scopes.includes(n.scope));
  return (
    <nav className="flex flex-col gap-1">
      {links.map((n) => {
        const active = n.href === "/" ? pathname === "/" : pathname.startsWith(n.href);
        return (
          <Link
            key={n.href}
            href={n.href}
            onClick={onNavigate}
            className={`rounded-md px-3 py-2 text-sm ${
              active
                ? "bg-[var(--color-forest)] text-white"
                : "hover:bg-[var(--color-sage)] text-[var(--color-ink)]"
            }`}
          >
            {n.label}
          </Link>
        );
      })}
    </nav>
  );
}

export function AppChrome({
  scopes,
  email,
  children,
}: {
  scopes: Scope[];
  email: string | null;
  children: React.ReactNode;
}) {
  const [drawerOpen, setDrawerOpen] = useState(false);

  return (
    <div className="flex min-h-full flex-col">
      <header className="sticky top-0 z-20 flex h-14 shrink-0 items-center gap-3 border-b border-[var(--color-border-subtle)] bg-white px-4">
        <button
          type="button"
          aria-label="Toggle navigation"
          aria-expanded={drawerOpen}
          onClick={() => setDrawerOpen((v) => !v)}
          className="rounded-md p-2 hover:bg-[var(--color-sage)] md:hidden"
        >
          <span className="sr-only">Menu</span>
          <svg width="20" height="20" viewBox="0 0 20 20" fill="none" aria-hidden="true">
            <path d="M2 5h16M2 10h16M2 15h16" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
          </svg>
        </button>
        <span className="text-base font-bold text-[var(--color-forest)]">Plan E Admin</span>
        <div className="ml-auto flex items-center gap-3">
          <span className="hidden truncate text-xs text-[var(--color-ink)]/60 sm:inline">{email}</span>
          <form action="/auth/signout" method="post">
            <button className="text-xs text-[var(--color-error)] hover:underline" type="submit">
              Sign out
            </button>
          </form>
        </div>
      </header>

      <div className="relative flex min-h-0 flex-1">
        {/* Desktop: persistent sidebar */}
        <aside className="hidden w-56 shrink-0 border-r border-[var(--color-border-subtle)] px-3 py-6 md:block">
          <NavLinks scopes={scopes} />
        </aside>

        {/* Mobile: drawer overlay */}
        {drawerOpen && (
          <div className="fixed inset-0 z-30 md:hidden">
            <button
              type="button"
              aria-label="Close navigation"
              className="absolute inset-0 bg-black/40"
              onClick={() => setDrawerOpen(false)}
            />
            <aside className="absolute inset-y-0 left-0 w-64 max-w-[80vw] overflow-y-auto bg-white px-3 py-6 shadow-xl">
              <NavLinks scopes={scopes} onNavigate={() => setDrawerOpen(false)} />
            </aside>
          </div>
        )}

        <main className="min-w-0 flex-1 overflow-x-hidden px-4 py-6 md:px-8">{children}</main>
      </div>
    </div>
  );
}
