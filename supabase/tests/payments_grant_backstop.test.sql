-- =============================================================================
-- payments_grant_backstop.test.sql  —  PERMANENT
-- =============================================================================
-- 20260908110000 added `grant select on public.payments to authenticated` so
-- the `is_admin()` SELECT policy on payments is reachable. That removed the
-- grant-level backstop: `is_admin()` in that one policy is now the ONLY thing
-- keeping every payment row out of a signed-in user's reach.
--
-- This file locks that down and fails loudly if it ever regresses:
--   1. a non-admin authenticated caller selects ZERO payment rows -- even for a
--      booking they own -- because there is no non-admin payment-read policy.
--   2. anon is denied outright (never granted).
--   3. payments has exactly ONE SELECT-permitting policy and its qual is the
--      has_scope('payments:read') check (20260908140000 replaced is_admin()
--      here). Adding any broader SELECT policy to payments fails this.
-- =============================================================================

begin;

do $$
declare
  v_user uuid := 'ac000000-0000-4000-8000-000000000001';
  v_cat  uuid := 'ac000000-0000-4000-8000-0000000000c1';
  v_reg  uuid := 'ac000000-0000-4000-8000-0000000000e1';
  v_exp  uuid := 'ac000000-0000-4000-8000-0000000000b1';
  v_dep  uuid := 'ac000000-0000-4000-8000-0000000000d1';
  v_book uuid := 'ac000000-0000-4000-8000-0000000000f1';
begin
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);

  insert into auth.users (id, instance_id, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role, aud)
  values (v_user, '00000000-0000-0000-0000-000000000000', 'payments.backstop@test.local', 'x', now(),
    '{"provider":"email","providers":["email"]}', '{}', now(), now(), 'authenticated', 'authenticated')
  on conflict (id) do nothing;
  insert into public.profiles (id, full_name, role)
  values (v_user, 'Payments Backstop', 'traveler'::public.user_role)
  on conflict (id) do update set role = 'traveler';

  insert into public.categories (id, slug, name_en, name_ne)
  values (v_cat, 'pay-backstop-cat', 'c', 'c') on conflict (id) do nothing;
  insert into public.regions (id, slug, name_en, name_ne)
  values (v_reg, 'pay-backstop-reg', 'r', 'r') on conflict (id) do nothing;
  insert into public.experiences (id, host_id, category_id, region_id, title, slug, cover_image_url, price_paisa, status)
  values (v_exp, null, v_cat, v_reg, 'Pay Backstop', 'pay-backstop', 'http://e/i.jpg', 500000, 'published'::public.experience_status)
  on conflict (id) do nothing;
  insert into public.experience_departures (id, experience_id, start_date, end_date, total_spots, spots_left)
  values (v_dep, v_exp, current_date + 10, current_date + 12, 10, 10) on conflict (id) do nothing;
  insert into public.bookings (id, booking_ref, user_id, experience_id, departure_id, adults,
    contact_name, contact_phone, subtotal_paisa, addons_paisa, fees_paisa, total_paisa, status)
  values (v_book, 'PAY-BACKSTOP-1', v_user, v_exp, v_dep, 1, 'x', '9800000000', 500000, 0, 25000, 525000, 'confirmed'::public.booking_status)
  on conflict (id) do nothing;
  insert into public.payments (booking_id, provider, idempotency_key, amount_paisa, status)
  values (v_book, 'khalti'::public.payment_provider, 'pay-backstop-idem', 525000, 'paid'::public.payment_status)
  on conflict (booking_id) do nothing;
end $$;

-- 1. non-admin authenticated caller: zero rows, INCLUDING their own booking's payment
do $$
declare v_count bigint;
begin
  set local role authenticated;
  perform set_config('request.jwt.claims',
    json_build_object('sub', 'ac000000-0000-4000-8000-000000000001', 'role', 'authenticated')::text, true);
  select count(*) into v_count from public.payments;
  reset role;
  if v_count <> 0 then
    raise exception 'FAIL: a non-admin authenticated caller read % payment row(s) -- a non-admin payment-read policy exists', v_count;
  end if;
end $$;

-- 2. anon: denied at the grant level
do $$
declare v_denied boolean := false;
begin
  set local role anon;
  begin
    perform 1 from public.payments limit 1;
  exception when insufficient_privilege then
    v_denied := true;
  end;
  reset role;
  if not v_denied then
    raise exception 'FAIL: anon was able to query public.payments';
  end if;
end $$;

-- 3. exactly one SELECT-permitting policy on payments, gated by has_scope('payments:read')
do $$
declare
  v_select_policies int;
  v_ungated int;
begin
  select count(*) into v_select_policies
  from pg_policies
  where schemaname = 'public' and tablename = 'payments'
    and cmd in ('SELECT', 'ALL');

  select count(*) into v_ungated
  from pg_policies
  where schemaname = 'public' and tablename = 'payments'
    and cmd in ('SELECT', 'ALL')
    and coalesce(qual, '') not like '%has_scope(''payments:read''%';

  if v_select_policies <> 1 or v_ungated <> 0 then
    raise exception 'FAIL: payments has % SELECT/ALL policy(ies), % not gated on has_scope(''payments:read'') -- expected exactly 1, that scope only', v_select_policies, v_ungated;
  end if;
end $$;

rollback;
