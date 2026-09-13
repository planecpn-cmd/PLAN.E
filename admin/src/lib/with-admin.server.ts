import "server-only";
import type { SupabaseClient } from "@supabase/supabase-js";
import { serviceRoleClient } from "./service-role";
import { createAnonServerClient } from "./supabase/server";
import { makeWithAdmin, type WithAdminDeps } from "./with-admin";

// Real wiring for withAdmin. Route handlers import `withAdmin` from HERE.
// This is the one legitimate consumer of the service-role client. `ctx.db` is
// bound to a real SupabaseClient for callers.

const realDeps: WithAdminDeps<SupabaseClient> = {
  async getActor() {
    const supabase = await createAnonServerClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    return user ? { userId: user.id, email: user.email ?? null } : null;
  },
  async loadStaff(userId) {
    const { data } = await serviceRoleClient()
      .from("staff_members")
      .select("status,scopes")
      .eq("user_id", userId)
      .maybeSingle();
    if (!data) return null;
    return {
      status: data.status as "active" | "suspended",
      scopes: (data.scopes as string[] | null) ?? [],
    };
  },
  async writeAudit(row) {
    const { error } = await serviceRoleClient().from("admin_audit_log").insert(row);
    if (error) throw error;
  },
  db: () => serviceRoleClient(),
};

export const withAdmin = makeWithAdmin<SupabaseClient>(realDeps);
