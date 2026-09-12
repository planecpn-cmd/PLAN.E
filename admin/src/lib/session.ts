import "server-only";
import { redirect } from "next/navigation";
import { createAnonServerClient } from "./supabase/server";
import type { Scope } from "./scopes";

// Page/layout-side session. Uses ONLY the anon session client. staff_members
// has a self-read RLS policy (user_id = auth.uid(), from 20260908140000), so a
// staff member reads their own row and their own scopes without needing
// profiles.role = 'admin'. The service-role client never enters the rendering
// tree — it lives only in with-admin.server.ts for API routes.

export interface AdminSession {
  userId: string;
  email: string | null;
  scopes: Scope[];
}

export async function getAdminSession(): Promise<AdminSession | null> {
  const supabase = await createAnonServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return null;

  const { data } = await supabase
    .from("staff_members")
    .select("status,scopes")
    .eq("user_id", user.id)
    .maybeSingle();

  if (!data || data.status !== "active") return null;
  return {
    userId: user.id,
    email: user.email ?? null,
    scopes: ((data.scopes as string[] | null) ?? []) as Scope[],
  };
}

export async function requireAdmin(): Promise<AdminSession> {
  const session = await getAdminSession();
  if (!session) redirect("/not-authorized");
  return session;
}

export async function requireScope(scope: Scope): Promise<AdminSession> {
  const session = await requireAdmin();
  if (!session.scopes.includes(scope)) redirect("/not-authorized");
  return session;
}

// For a page shared by a read/manage/review scope and its paired
// decide/act scope (content:manage + content:decide, hosts:review +
// hosts:decide, payments:read + payments:act): either one alone is enough
// to open the page. The page's own business-table reads still go through
// the anon session client, so the matching RLS SELECT policy must also
// accept both scopes (see 20260912090000_decide_scopes_can_read_their_queue.sql)
// or a decide/act-only session will pass this gate but see empty data.
// Which controls render (recommend vs. decide) is a separate check the
// page makes against session.scopes itself — this only decides whether the
// page opens at all.
export async function requireAnyScope(scopes: Scope[]): Promise<AdminSession> {
  const session = await requireAdmin();
  if (!scopes.some((s) => session.scopes.includes(s))) redirect("/not-authorized");
  return session;
}
