import "server-only";
import { createClient, type SupabaseClient } from "@supabase/supabase-js";

// ─────────────────────────────────────────────────────────────────────────────
// THE ONLY MODULE IN THIS APP THAT TOUCHES SUPABASE_SERVICE_ROLE_KEY.
//
// The service-role client bypasses RLS entirely. From the moment this panel
// exists, RLS is no longer the last line of defence for admin traffic — one
// missing authorization check in one route handler equals full cross-tenant
// exposure. So this client is reachable from exactly one place:
// src/lib/with-admin.ts (the withAdmin wrapper), which runs session +
// staff-record + scope checks and writes an audit row before handing it over.
//
// Enforced two ways:
//   - eslint no-restricted-imports (see eslint.config.mjs) — a tripwire
//   - src/lib/no-service-role-import.test.ts — the load-bearing check; a test,
//     so it cannot be silenced with an inline eslint-disable comment.
// `import "server-only"` additionally makes a client-component import a build
// error.
// ─────────────────────────────────────────────────────────────────────────────

let cached: SupabaseClient | null = null;

export function serviceRoleClient(): SupabaseClient {
  if (cached) return cached;

  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !key) {
    throw new Error(
      "service-role client not configured: NEXT_PUBLIC_SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required",
    );
  }

  cached = createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  return cached;
}
