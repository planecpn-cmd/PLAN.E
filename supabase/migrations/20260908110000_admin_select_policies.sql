-- P1 Step 2 — admin read access to business tables (context doc §9.1, plan §2.2
-- mitigation 2). SELECT only. No admin INSERT/UPDATE/DELETE policy anywhere:
-- admin writes go through the service-role backend with an audit record, never
-- through client-side RLS. Additive — existing policies are untouched.
--
-- `public.is_admin()` = profiles.role = 'admin' for auth.uid() (SECURITY
-- DEFINER, from 0021_remote_config.sql). Non-admins match none of these
-- policies, so their row visibility is unchanged.

-- payments: RLS is enabled with zero policies today and `authenticated` has no
-- grant. A policy without a grant is dead, so grant SELECT to authenticated
-- here; RLS (is_admin() only) is what actually gates it, and a non-admin still
-- sees zero rows. anon is deliberately NOT granted.
grant select on table public.payments to authenticated;

create policy "Admins can read all bookings"
  on public.bookings for select to authenticated
  using (public.is_admin());

create policy "Admins can read all payments"
  on public.payments for select to authenticated
  using (public.is_admin());

create policy "Admins can read all host applications"
  on public.host_applications for select to authenticated
  using (public.is_admin());

create policy "Admins can read all host accounts"
  on public.host_accounts for select to authenticated
  using (public.is_admin());

create policy "Admins can read all experiences"
  on public.experiences for select to authenticated
  using (public.is_admin());

create policy "Admins can read all reviews"
  on public.reviews for select to authenticated
  using (public.is_admin());

create policy "Admins can read all booking participants"
  on public.booking_participants for select to authenticated
  using (public.is_admin());

create policy "Admins can read all departures"
  on public.experience_departures for select to authenticated
  using (public.is_admin());

create policy "Admins can read all legal acceptances"
  on public.legal_acceptances for select to authenticated
  using (public.is_admin());

-- profiles: the grant to authenticated is column-limited to
-- (id, full_name, avatar_url) and that is unchanged here, so this policy adds
-- no practical reach today (an authenticated user already reads those three
-- columns for every row via "Public profile identities are readable"). It is
-- added for consistency and so a future admin-only column grant has a row
-- policy to sit behind. Full admin profile reads (phone, role, points, ...)
-- go through the service-role backend, not the user JWT.
create policy "Admins can read all profiles"
  on public.profiles for select to authenticated
  using (public.is_admin());
