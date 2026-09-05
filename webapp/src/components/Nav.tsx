"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useAuth } from "@/lib/AuthProvider";
import { supabase } from "@/lib/supabase";
import { Logo } from "@/components/ui/Logo";
import { Icon } from "@/components/ui/Icon";
import { Button } from "@/components/ui/Button";

const NAV_ITEMS = [
  { href: "/", label: "Home", icon: "home" as const },
  { href: "/explore", label: "Explore", icon: "compass" as const },
  { href: "/plans", label: "Plans", icon: "calendar" as const },
  { href: "/saved", label: "Saved", icon: "bookmark" as const },
  { href: "/profile", label: "Profile", icon: "user" as const },
];

function isActive(pathname: string, href: string) {
  if (href === "/") return pathname === "/";
  return pathname.startsWith(href);
}

export function TopNav() {
  const pathname = usePathname();
  const { user, loading } = useAuth();

  return (
    <header className="sticky top-0 z-40 hidden border-b border-[var(--color-border-subtle)] bg-[var(--color-ivory)]/95 backdrop-blur lg:block">
      <div className="mx-auto flex max-w-[1280px] items-center gap-8 px-6 py-2.5">
        <Link href="/" aria-label="PLAN E home">
          <Logo />
          <p className="mt-0.5 flex items-center gap-1 text-xs font-medium text-[var(--color-ink)]/60">
            <Icon name="mapPin" size={11} />
            Nepal
          </p>
        </Link>

        <nav aria-label="Primary" className="flex items-center gap-1">
          {NAV_ITEMS.map((item) => {
            const active = isActive(pathname, item.href);
            return (
              <Link
                key={item.href}
                href={item.href}
                aria-current={active ? "page" : undefined}
                className={`flex items-center gap-1.5 rounded-full px-3.5 py-2 text-sm font-medium transition-colors ${
                  active ? "text-[var(--color-forest)]" : "text-[var(--color-ink)]/70 hover:bg-[var(--color-sage)]"
                }`}
              >
                <Icon name={item.icon} size={18} filled={active} />
                {item.label}
              </Link>
            );
          })}
        </nav>

        <div className="ml-auto flex items-center gap-3">
          <Link
            href="/search"
            aria-label="Search"
            className="flex h-9 w-9 items-center justify-center rounded-full text-[var(--color-ink)]/70 hover:bg-[var(--color-sage)]"
          >
            <Icon name="search" size={18} />
          </Link>
          {!loading && user && (
            <Link
              href="/notifications"
              aria-label="Notifications"
              className="flex h-9 w-9 items-center justify-center rounded-full text-[var(--color-ink)]/70 hover:bg-[var(--color-sage)]"
            >
              <Icon name="bell" size={18} />
            </Link>
          )}
          {!loading &&
            (user ? (
              <button
                onClick={() => supabase.auth.signOut()}
                className="text-sm font-medium text-[var(--color-ink)]/70 hover:text-[var(--color-forest)]"
              >
                Sign out
              </button>
            ) : (
              <>
                <Link
                  href="/notifications"
                  aria-label="Notifications"
                  className="flex h-9 w-9 items-center justify-center rounded-full text-[var(--color-ink)]/70 hover:bg-[var(--color-sage)]"
                >
                  <Icon name="bell" size={18} />
                </Link>
                <Link href="/auth/sign-up" className="text-sm font-medium text-[var(--color-ink)]/70 hover:text-[var(--color-forest)]">
                  Sign up
                </Link>
                <Link href="/auth/login">
                  <Button variant="primary" className="!min-h-0 !py-2 !px-5">
                    Sign in
                  </Button>
                </Link>
              </>
            ))}
        </div>
      </div>
    </header>
  );
}

export function BottomNav() {
  const pathname = usePathname();

  return (
    <nav
      aria-label="Primary"
      className="fixed inset-x-4 bottom-3 z-40 rounded-[30px] border border-[var(--color-border-subtle)] bg-white shadow-[0_4px_16px_rgba(1,37,28,0.09)] lg:hidden"
    >
      <ul className="flex h-[58px] items-center justify-around">
        {NAV_ITEMS.map((item) => {
          const active = isActive(pathname, item.href);
          return (
            <li key={item.href}>
              <Link
                href={item.href}
                aria-label={item.label}
                aria-current={active ? "page" : undefined}
                className={`flex h-12 w-12 items-center justify-center rounded-full ${
                  active ? "text-[var(--color-forest)]" : "text-[var(--color-ink)]/70"
                }`}
              >
                <Icon name={item.icon} size={24} filled={active} />
              </Link>
            </li>
          );
        })}
      </ul>
    </nav>
  );
}
