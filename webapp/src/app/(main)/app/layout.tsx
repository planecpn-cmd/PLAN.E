import type { Metadata } from "next";

// route/split P3: everything under /app/* is the authenticated app shell,
// not a public marketing or catalog page. Keep it out of search entirely.
export const metadata: Metadata = { robots: { index: false, follow: false } };

export default function AppShellLayout({ children }: { children: React.ReactNode }) {
  return children;
}
