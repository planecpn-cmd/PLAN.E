-- =============================================================================
-- admin_rls.test.sql  —  admin / cross-tenant RLS regression net (P0.3)
-- =============================================================================
-- Runs in the same psql-transaction style as rls.test.sql: begin / fixtures /
-- assertions / rollback. Nothing here persists.
--
-- Two kinds of assertion:
--
--   [PERMANENT NEGATIVE]  a plain traveler can never read another user's rows.
--                         These must stay green in every phase, forever.
--
--   [ADMIN BASELINE — P1 STEP 2 FLIPS THESE]  today `is_admin()` grants no extra
--                         reach into business tables, so an admin sees exactly
--                         what any authenticated user sees (nothing that isn't
--                         theirs). P1 Step 2 adds `is_admin()` SELECT policies;
--                         when it does, every assertion in the ADMIN BASELINE
--                         section changes from "sees 0" to "sees the row", and
--                         the section header comment moves with it.
-- =============================================================================

begin;

do $$
declare
  v_admin    uuid := 'aa000000-0000-4000-8000-0000000000a1';
  v_owner    uuid := 'aa000000-0000-4000-8000-0000000000a2';  -- traveler who owns the rows
  v_other    uuid := 'aa000000-0000-4000-8000-0000000000a3';  -- unrelated traveler
  v_host     uuid := 'aa000000-0000-4000-8000-0000000000a4';
  v_cat      uuid := 'aa000000-0000-4000-8000-0000000000c1';
  v_reg      uuid := 'aa000000-0000-4000-8000-0000000000e1';
  v_exp_pub  uuid := 'aa000000-0000-4000-8000-0000000000b1';
  v_exp_draft uuid := 'aa000000-0000-4000-8000-0000000000b2';
  v_dep      uuid := 'aa000000-0000-4000-8000-0000000000d1';
  v_booking  uuid := 'aa000000-0000-4000-8000-0000000000f1';
  v_app      uuid := 'aa000000-0000-4000-8000-0000000000f2';
  v_doc      uuid := 'aa000000-0000-4000-8000-0000000000f3';
begin
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);

  insert into auth.users (id, instance_id, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role, aud)
  values
    (v_admin, '00000000-0000-0000-0000-000000000000', 'admin.rls@test.local', 'x', now(),
      '{"provider":"email","providers":["email"]}', '{}', now(), now(), 'authenticated', 'authenticated'),
    (v_owner, '00000000-0000-0000-0000-000000000000', 'owner.rls@test.local', 'x', now(),
      '{"provider":"email","providers":["email"]}', '{}', now(), now(), 'authenticated', 'authenticated'),
    (v_other, '00000000-0000-0000-0000-000000000000', 'other.rls@test.local', 'x', now(),
      '{"provider":"email","providers":["email"]}', '{}', now(), now(), 'authenticated', 'authenticated'),
    (v_host,  '00000000-0000-0000-0000-000000000000', 'host.rls@test.local', 'x', now(),
      '{"provider":"email","providers":["email"]}', '{}', now(), now(), 'authenticated', 'authenticated')
  on conflict (id) do nothing;

  insert into public.profiles (id, full_name, phone, role)
  values
    (v_admin, 'RLS Admin', '9811100001', 'admin'::public.user_role),
    (v_owner, 'RLS Owner', '9811100002', 'traveler'::public.user_role),
    (v_other, 'RLS Other', '9811100003', 'traveler'::public.user_role),
    (v_host,  'RLS Host',  '9811100004', 'host'::public.user_role)
  on conflict (id) do update set role = excluded.role, phone = excluded.phone;

  insert into public.categories (id, slug, name_en, name_ne)
  values (v_cat, 'rls-test-cat', 'RLS Cat', 'क्षे')
  on conflict (id) do nothing;
  insert into public.regions (id, slug, name_en, name_ne)
  values (v_reg, 'rls-test-reg', 'RLS Reg', 'क्षे')
  on conflict (id) do nothing;

  insert into public.experiences (id, host_id, category_id, region_id, title, slug,
    cover_image_url, price_paisa, status)
  values
    (v_exp_pub,   v_host, v_cat, v_reg, 'RLS Published', 'rls-published',
      'http://example.com/i.jpg', 500000, 'published'::public.experience_status),
    (v_exp_draft, v_host, v_cat, v_reg, 'RLS Draft',     'rls-draft',
      'http://example.com/i.jpg', 500000, 'draft'::public.experience_status)
  on conflict (id) do nothing;

  insert into public.experience_departures (id, experience_id, start_date, end_date, total_spots, spots_left)
  values (v_dep, v_exp_pub, current_date + 10, current_date + 12, 10, 10)
  on conflict (id) do nothing;

  insert into public.bookings (id, booking_ref, user_id, experience_id, departure_id, adults,
    contact_name, contact_phone, subtotal_paisa, addons_paisa, fees_paisa, total_paisa, status)
  values (v_booking, 'RLS-OWNER-1', v_owner, v_exp_pub, v_dep, 1,
    'RLS Owner', '9811100002', 500000, 0, 25000, 525000, 'pending'::public.booking_status)
  on conflict (id) do nothing;

  insert into public.booking_participants (booking_id, full_name, is_lead)
  values (v_booking, 'RLS Owner Participant', true);

  insert into public.payments (booking_id, provider, idempotency_key, amount_paisa, status)
  values (v_booking, 'khalti'::public.payment_provider, 'rls-test-idem-1', 525000, 'initiated'::public.payment_status)
  on conflict (booking_id) do nothing;

  insert into public.host_applications (id, user_id, status, title)
  values (v_app, v_owner, 'submitted'::public.host_app_status, 'RLS Owner App')
  on conflict (id) do nothing;

  insert into public.legal_documents (id, slug, version, locale, title, body_md, effective_at, requires_acceptance, is_current)
  values (v_doc, 'rls-test-terms', '1.0', 'en', 'RLS Terms', '# terms', now(), true, true)
  on conflict (id) do nothing;
  insert into public.legal_acceptances (user_id, document_id, client)
  values (v_owner, v_doc, 'flutter')
  on conflict do nothing;
end $$;

-- Helper: run a count as a given user, treating "permission denied" as 0 visible.
create or replace function pg_temp.count_as(p_user uuid, p_sql text)
returns bigint language plpgsql as $$
declare v bigint;
begin
  set local role authenticated;
  perform set_config('request.jwt.claims',
    json_build_object('sub', p_user::text, 'role', 'authenticated')::text, true);
  begin
    execute p_sql into v;
  exception when insufficient_privilege then
    v := 0;
  end;
  reset role;
  return coalesce(v, 0);
end $$;

-- ---------------------------------------------------------------------------
-- [PERMANENT NEGATIVE]  another traveler can read none of the owner's rows.
-- ---------------------------------------------------------------------------
do $$
declare v_other uuid := 'aa000000-0000-4000-8000-0000000000a3';
begin
  if pg_temp.count_as(v_other, 'select count(*) from public.bookings where user_id = ''aa000000-0000-4000-8000-0000000000a2''') <> 0
     then raise exception 'FAIL: [neg] other traveler read owner bookings'; end if;
  if pg_temp.count_as(v_other, 'select count(*) from public.payments') <> 0
     then raise exception 'FAIL: [neg] other traveler read payments'; end if;
  if pg_temp.count_as(v_other, 'select count(*) from public.host_applications where user_id = ''aa000000-0000-4000-8000-0000000000a2''') <> 0
     then raise exception 'FAIL: [neg] other traveler read owner host_applications'; end if;
  if pg_temp.count_as(v_other, 'select count(*) from public.legal_acceptances where user_id = ''aa000000-0000-4000-8000-0000000000a2''') <> 0
     then raise exception 'FAIL: [neg] other traveler read owner legal_acceptances'; end if;
  if pg_temp.count_as(v_other, 'select count(*) from public.booking_participants where booking_id = ''aa000000-0000-4000-8000-0000000000f1''') <> 0
     then raise exception 'FAIL: [neg] other traveler read owner booking_participants'; end if;
  if pg_temp.count_as(v_other, 'select count(*) from public.experiences where id = ''aa000000-0000-4000-8000-0000000000b2''') <> 0
     then raise exception 'FAIL: [neg] other traveler read a draft experience'; end if;
  if pg_temp.count_as(v_other, 'select count(*) from public.host_accounts where user_id = ''aa000000-0000-4000-8000-0000000000a4''') <> 0
     then raise exception 'FAIL: [neg] other traveler read another host_account'; end if;
end $$;

-- ---------------------------------------------------------------------------
-- [PERMANENT NEGATIVE]  private profile columns are not client-readable, not
-- even for an admin (column grants, unaffected by RLS row policies).
-- ---------------------------------------------------------------------------
do $$
declare v_admin uuid := 'aa000000-0000-4000-8000-0000000000a1'; v_denied boolean := false;
begin
  set local role authenticated;
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_admin::text, 'role', 'authenticated')::text, true);
  begin
    perform phone from public.profiles where id = 'aa000000-0000-4000-8000-0000000000a2';
  exception when insufficient_privilege then
    v_denied := true;
  end;
  reset role;
  if not v_denied then
    raise exception 'FAIL: [neg] admin directly selected profiles.phone';
  end if;
end $$;

-- ===========================================================================
-- ADMIN BASELINE — P1 STEP 2 FLIPS EVERY ASSERTION IN THIS SECTION (0 -> 1).
-- Today: no is_admin() SELECT policy exists on these tables, so an admin sees
-- none of another user's rows. After P1 Step 2 adds those policies, each of
-- these must instead assert the admin DOES see the row, and this header
-- comment is rewritten to say so.
-- ===========================================================================
do $$
declare v_admin uuid := 'aa000000-0000-4000-8000-0000000000a1';
begin
  if pg_temp.count_as(v_admin, 'select count(*) from public.bookings where user_id = ''aa000000-0000-4000-8000-0000000000a2''') <> 0
     then raise exception 'FAIL: [admin-baseline] admin already reads other bookings — update this suite alongside the P1 Step 2 migration'; end if;
  if pg_temp.count_as(v_admin, 'select count(*) from public.payments') <> 0
     then raise exception 'FAIL: [admin-baseline] admin already reads payments — update this suite alongside the P1 Step 2 migration'; end if;
  if pg_temp.count_as(v_admin, 'select count(*) from public.host_applications where user_id = ''aa000000-0000-4000-8000-0000000000a2''') <> 0
     then raise exception 'FAIL: [admin-baseline] admin already reads other host_applications — update this suite alongside the P1 Step 2 migration'; end if;
  if pg_temp.count_as(v_admin, 'select count(*) from public.host_accounts where user_id = ''aa000000-0000-4000-8000-0000000000a4''') <> 0
     then raise exception 'FAIL: [admin-baseline] admin already reads host_accounts — update this suite alongside the P1 Step 2 migration'; end if;
  if pg_temp.count_as(v_admin, 'select count(*) from public.experiences where id = ''aa000000-0000-4000-8000-0000000000b2''') <> 0
     then raise exception 'FAIL: [admin-baseline] admin already reads draft experiences — update this suite alongside the P1 Step 2 migration'; end if;
  if pg_temp.count_as(v_admin, 'select count(*) from public.reviews') <> 0
     then raise exception 'FAIL: [admin-baseline] admin already reads all reviews — update this suite alongside the P1 Step 2 migration'; end if;
  if pg_temp.count_as(v_admin, 'select count(*) from public.booking_participants where booking_id = ''aa000000-0000-4000-8000-0000000000f1''') <> 0
     then raise exception 'FAIL: [admin-baseline] admin already reads other booking_participants — update this suite alongside the P1 Step 2 migration'; end if;
  if pg_temp.count_as(v_admin, 'select count(*) from public.legal_acceptances where user_id = ''aa000000-0000-4000-8000-0000000000a2''') <> 0
     then raise exception 'FAIL: [admin-baseline] admin already reads other legal_acceptances — update this suite alongside the P1 Step 2 migration'; end if;
end $$;

rollback;
