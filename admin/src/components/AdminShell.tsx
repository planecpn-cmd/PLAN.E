import type { Scope } from "@/lib/scopes";
import { AppChrome } from "@/components/AppChrome";

// Thin server-side wrapper so every page keeps importing { AdminShell } with
// the same props -- the interactive top bar + responsive sidebar/drawer live
// in AppChrome (client component; the mobile drawer needs open/close state).
export function AdminShell({
  scopes,
  email,
  children,
}: {
  scopes: Scope[];
  email: string | null;
  children: React.ReactNode;
}) {
  return (
    <AppChrome scopes={scopes} email={email}>
      {children}
    </AppChrome>
  );
}
