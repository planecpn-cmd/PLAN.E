// The scope vocabulary. This array is the single source of truth on the app
// side; it MUST stay identical to the staff_members_scopes_known CHECK
// constraint (defined in 20260908120000, widened since by later migrations --
// supabase/tests/scope_vocabulary_consistency.test.mjs checks the LIVE
// definition, not any one file) and to the founder bootstrap's v_all_scopes.
// Adding a scope means changing all three, in order: the constraint,
// this file, then the bootstrap.
export const ALL_SCOPES = [
  "hosts:review",
  "hosts:decide",
  "bookings:read",
  "payments:read",
  "payments:act",
  "finance:read",
  "content:manage",
  "content:decide",
  "users:manage",
  "staff:manage",
] as const;

export type Scope = (typeof ALL_SCOPES)[number];

export function isScope(value: string): value is Scope {
  return (ALL_SCOPES as readonly string[]).includes(value);
}
