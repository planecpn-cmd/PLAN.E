-- P1 correction — scope-aware admin RLS.
--
-- 20260908110000 gated 10 business tables on bare is_admin() (profiles.role =
-- 'admin'). For a staff member to read their own staff_members row and log in
-- to the panel, they also needed role = 'admin' — which then let a
-- hosts:review-only moderator hit the Supabase REST API with their own JWT and
-- read every payment and booking. Scopes were enforced only inside withAdmin().
--
-- This migration:
--   1. adds public.has_scope(text),
--   2. decouples staff login from profiles.role: a staff member can read their
--      own staff_members row; reading other staff rows needs is_admin() or the
--      staff:manage scope,
--   3. replaces is_admin() in the 10 admin SELECT policies with the matching
--      scope check.
--
-- Founders keep profiles.role = 'admin' AND all 8 scopes (the bootstrap sets
-- both), so has_scope() covers them everywhere. Moderators get a staff_members
-- row with a subset of scopes and NO role = 'admin'. Keeping an is_admin()
-- OR-branch on the business tables would re-open the exact bypass this closes,
-- and nothing needs it (a founder already has every scope), so it is dropped.

-- ── 1. has_scope() ──────────────────────────────────────────────────────────
-- SECURITY DEFINER so it can read staff_members regardless of the caller's RLS.
-- Same ACL discipline as P0.6 / the other RLS helpers: not public/anon.
create or replace function public.has_scope(p_scope text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.staff_members sm
    where sm.user_id = auth.uid()
      and sm.status = 'active'
      and p_scope = any (sm.scopes)
  );
$$;

revoke execute on function public.has_scope(text) from public, anon;
grant execute on function public.has_scope(text) to authenticated;

comment on function public.has_scope(text) is
  'True when the current user is an active staff member whose scopes include p_scope. RLS helper; authenticated-callable — a caller only learns their own scope grants, which they could already infer from which queries succeed.';

-- ── 2. staff_members: self-read + scoped others-read ───────────────────────
drop policy if exists "Admins can read staff members" on public.staff_members;

create policy "Staff can read their own staff row"
  on public.staff_members for select to authenticated
  using (user_id = auth.uid());

create policy "Staff managers and admins can read all staff rows"
  on public.staff_members for select to authenticated
  using (public.is_admin() or public.has_scope('staff:manage'));

-- ── 3. scope-gated business-table reads (replace bare is_admin()) ──────────
drop policy if exists "Admins can read all bookings" on public.bookings;
create policy "Booking readers can read all bookings"
  on public.bookings for select to authenticated
  using (public.has_scope('bookings:read'));

drop policy if exists "Admins can read all booking participants" on public.booking_participants;
create policy "Booking readers can read all booking participants"
  on public.booking_participants for select to authenticated
  using (public.has_scope('bookings:read'));

drop policy if exists "Admins can read all departures" on public.experience_departures;
create policy "Booking readers can read all departures"
  on public.experience_departures for select to authenticated
  using (public.has_scope('bookings:read'));

drop policy if exists "Admins can read all payments" on public.payments;
create policy "Payment readers can read all payments"
  on public.payments for select to authenticated
  using (public.has_scope('payments:read'));

drop policy if exists "Admins can read all host applications" on public.host_applications;
create policy "Host reviewers can read all host applications"
  on public.host_applications for select to authenticated
  using (public.has_scope('hosts:review'));

drop policy if exists "Admins can read all host accounts" on public.host_accounts;
create policy "Host reviewers can read all host accounts"
  on public.host_accounts for select to authenticated
  using (public.has_scope('hosts:review'));

drop policy if exists "Admins can read all experiences" on public.experiences;
create policy "Content managers can read all experiences"
  on public.experiences for select to authenticated
  using (public.has_scope('content:manage'));

drop policy if exists "Admins can read all reviews" on public.reviews;
create policy "Content managers can read all reviews"
  on public.reviews for select to authenticated
  using (public.has_scope('content:manage'));

drop policy if exists "Admins can read all legal acceptances" on public.legal_acceptances;
create policy "Booking readers can read all legal acceptances"
  on public.legal_acceptances for select to authenticated
  using (public.has_scope('bookings:read'));

-- Deliberately untouched:
--   profiles      — its "Admins can read all profiles" policy is a near-no-op
--                   (the grant stays column-limited to id/full_name/avatar_url)
--                   and is not in the correction list.
--   admin_audit_log — stays is_admin()-only. It carries before/after PII and
--                   actor emails; reading it is a founder action, not a
--                   per-scope one.
--   app_config / feature_flags / remote_content / app_versions / config_audit_log
--                 — their is_admin() write/read policies are unchanged. The
--                   panel writes them through the service-role path in
--                   /api/config/[table] (RLS bypassed there), and a direct-JWT
--                   write by a non-founder is correctly still refused.
