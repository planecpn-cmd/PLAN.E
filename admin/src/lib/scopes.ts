// The scope vocabulary. This array is the single source of truth on the app
// side; it MUST stay identical to the CHECK constraint in
// supabase/migrations/20260908120000_staff_members_and_admin_audit_log.sql
// (staff_members_scopes_known). Adding a scope means changing both.
export const ALL_SCOPES = [
  "hosts:review",
  "hosts:decide",
  "bookings:read",
  "payments:read",
  "payments:act",
  "finance:read",
  "content:manage",
  "content:decide",
  "staff:manage",
] as const;

export type Scope = (typeof ALL_SCOPES)[number];

export function isScope(value: string): value is Scope {
  return (ALL_SCOPES as readonly string[]).includes(value);
}
