import { requireScope } from "@/lib/session";
import { createAnonServerClient } from "@/lib/supabase/server";
import { AdminShell } from "@/components/AdminShell";
import { ConfigEditor, type Flag } from "@/components/ConfigEditor";

// content:manage. The gate is BOTH layers: this page redirects an under-scoped
// account, and the /api/config/* routes refuse it via withAdmin.
//
// feature_flags is world-readable (RLS `using (true)`), so the initial list is
// fetched here with the anon session client. Writes go through /api/config/*.
export default async function ConfigPage() {
  const session = await requireScope("content:manage");
  const supabase = await createAnonServerClient();
  const { data } = await supabase
    .from("feature_flags")
    .select("key,enabled,rollout_percent,platforms,description")
    .order("key");

  return (
    <AdminShell scopes={session.scopes} email={session.email}>
      <h1 className="text-xl font-bold text-[var(--color-forest)]">Config &amp; feature flags</h1>
      <p className="mt-1 text-sm text-[var(--color-ink)]/60">
        Every change is recorded — in the config audit log and the admin audit log.
        A reason is required.
      </p>
      <ConfigEditor initialFlags={(data ?? []) as Flag[]} />
    </AdminShell>
  );
}
