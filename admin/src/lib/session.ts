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
