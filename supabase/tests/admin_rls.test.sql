-- =============================================================================
-- admin_rls.test.sql  —  scope-aware admin / cross-tenant RLS regression net
-- =============================================================================
-- psql-transaction style: begin / fixtures / assertions / rollback.
--
--   [PERMANENT NEGATIVE]  a plain traveler and anon read none of another user's
--                         rows; nobody reads private profile columns via the
--                         user JWT.
--
--   [SCOPE MATRIX]         20260908140000 replaced bare is_admin() on the ten
--                         business tables with has_scope(<the matching scope>).
--                         A staff member reads a table iff their active scopes
--                         include that table's scope. Suspended staff read
--                         nothing. Staff read their own staff_members row but
--                         not another's (unless is_admin() or staff:manage).
--                         A founder holds every scope, so full access still
--                         works.
-- =============================================================================

begin;

do $$
declare
  v_founder   uuid := 'aa000000-0000-4000-8000-0000000000a1';  -- role=admin + all 8 scopes
  v_owner     uuid := 'aa000000-0000-4000-8000-0000000000a2';  -- traveler, owns the data rows
  v_other     uuid := 'aa000000-0000-4000-8000-0000000000a3';  -- unrelated traveler, no staff row
  v_host      uuid := 'aa000000-0000-4000-8000-0000000000a4';  -- approved host
  v_reviewer  uuid := 'aa000000-0000-4000-8000-0000000000a5';  -- staff, scopes = {hosts:review}
  v_payer     uuid := 'aa000000-0000-4000-8000-0000000000a6';  -- staff, scopes = {payments:read}
  v_suspended uuid := 'aa000000-0000-4000-8000-0000000000a7';  -- staff, SUSPENDED, broad scopes
  v_booker    uuid := 'aa000000-0000-4000-8000-0000000000a8';  -- staff, scopes = {bookings:read}
  v_cat  uuid := 'aa000000-0000-4000-8000-0000000000c1';
  v_reg  uuid := 'aa000000-0000-4000-8000-0000000000e1';
  v_exp_pub  uuid := 'aa000000-0000-4000-8000-0000000000b1';
  v_exp_draft uuid := 'aa000000-0000-4000-8000-0000000000b2';
  v_dep  uuid := 'aa000000-0000-4000-8000-0000000000d1';
  v_book uuid := 'aa000000-0000-4000-8000-0000000000f1';
  v_app  uuid := 'aa000000-0000-4000-8000-0000000000f2';
  v_doc  uuid := 'aa000000-0000-4000-8000-0000000000f3';
begin
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);

  insert into auth.users (id, instance_id, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role, aud)
  select u, '00000000-0000-0000-0000-000000000000', u::text || '@rls.test', 'x', now(),
    '{"provider":"email","providers":["email"]}', '{}', now(), now(), 'authenticated', 'authenticated'
  from unnest(array[v_founder, v_owner, v_other, v_host, v_reviewer, v_payer, v_suspended, v_booker]) u
  on conflict (id) do nothing;

  insert into public.profiles (id, full_name, phone, role)
  values
    (v_founder,   'RLS Founder',   '9811100001', 'admin'::public.user_role),
    (v_owner,     'RLS Owner',     '9811100002', 'traveler'::public.user_role),
    (v_other,     'RLS Other',     '9811100003', 'traveler'::public.user_role),
    (v_host,      'RLS Host',      '9811100004', 'host'::public.user_role),
    (v_reviewer,  'RLS Reviewer',  '9811100005', 'traveler'::public.user_role),
    (v_payer,     'RLS Payer',     '9811100006', 'traveler'::public.user_role),
    (v_suspended, 'RLS Suspended', '9811100007', 'traveler'::public.user_role),
    (v_booker,    'RLS Booker',    '9811100008', 'traveler'::public.user_role)
  on conflict (id) do update set role = excluded.role, phone = excluded.phone;

  insert into public.staff_members (user_id, status, scopes)
  values
    (v_founder, 'active', array['hosts:review','hosts:decide','bookings:read','payments:read',
                                'payments:act','finance:read','content:manage','staff:manage']),
    (v_reviewer,  'active',    array['hosts:review']),
    (v_payer,     'active',    array['payments:read']),
    (v_booker,    'active',    array['bookings:read']),
    (v_suspended, 'suspended', array['hosts:review','payments:read','bookings:read'])
  on conflict (user_id) do update set status = excluded.status, scopes = excluded.scopes;

  insert into public.categories (id, slug, name_en, name_ne)
  values (v_cat, 'rls-test-cat', 'RLS Cat', 'क्षे') on conflict (id) do nothing;
  insert into public.regions (id, slug, name_en, name_ne)
  values (v_reg, 'rls-test-reg', 'RLS Reg', 'क्षे') on conflict (id) do nothing;

  insert into public.experiences (id, host_id, category_id, region_id, title, slug,
    cover_image_url, price_paisa, status)
  values
    (v_exp_pub,   v_host, v_cat, v_reg, 'RLS Published', 'rls-published',
      'http://example.com/i.jpg', 500000, 'published'::public.experience_status),
    (v_exp_draft, v_host, v_cat, v_reg, 'RLS Draft',     'rls-draft',
      'http://example.com/i.jpg', 500000, 'draft'::public.experience_status)
  on conflict (id) do nothing;

  insert into public.experience_departures (id, experience_id, start_date, end_date, total_spots, spots_left)
  values (v_dep, v_exp_pub, current_date + 10, current_date + 12, 10, 10) on conflict (id) do nothing;

  insert into public.bookings (id, booking_ref, user_id, experience_id, departure_id, adults,
    contact_name, contact_phone, subtotal_paisa, addons_paisa, fees_paisa, total_paisa, status)
  values (v_book, 'RLS-OWNER-1', v_owner, v_exp_pub, v_dep, 1,
    'RLS Owner', '9811100002', 500000, 0, 25000, 525000, 'completed'::public.booking_status)
  on conflict (id) do nothing;

  insert into public.booking_participants (booking_id, full_name, is_lead)
  values (v_book, 'RLS Owner Participant', true);

  insert into public.payments (booking_id, provider, idempotency_key, amount_paisa, status)
  values (v_book, 'khalti'::public.payment_provider, 'rls-test-idem-1', 525000, 'paid'::public.payment_status)
  on conflict (booking_id) do nothing;

  insert into public.reviews (booking_id, experience_id, user_id, rating, title, body)
  values (v_book, v_exp_pub, v_owner, 5, 'RLS review', 'fixture') on conflict (booking_id) do nothing;

  insert into public.host_applications (id, user_id, status, title)
  values (v_app, v_owner, 'submitted'::public.host_app_status, 'RLS Owner App')
  on conflict (id) do nothing;
  insert into public.host_applications (id, user_id, status, title)
  values ('aa000000-0000-4000-8000-0000000000f4', v_host, 'approved'::public.host_app_status, 'RLS Host App')
  on conflict (id) do nothing;  -- sync trigger creates host_accounts for v_host

  insert into public.legal_documents (id, slug, version, locale, title, body_md, effective_at, requires_acceptance, is_current)
  values (v_doc, 'rls-test-terms', '1.0', 'en', 'RLS Terms', '# terms', now(), true, true)
  on conflict (id) do nothing;
  insert into public.legal_acceptances (user_id, document_id, client)
  values (v_owner, v_doc, 'flutter') on conflict do nothing;
end $$;

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

create or replace function pg_temp.count_as_anon(p_sql text)
returns bigint language plpgsql as $$
declare v bigint;
begin
  set local role anon;
  begin
    execute p_sql into v;
  exception when insufficient_privilege then
    v := 0;
  end;
  reset role;
  return coalesce(v, 0);
end $$;

create or replace function pg_temp.expect(p_label text, p_got bigint, p_op text, p_want bigint)
returns void language plpgsql as $$
begin
  if (p_op = '=' and p_got <> p_want)
     or (p_op = '>=' and p_got < p_want) then
    raise exception 'FAIL: % — got %, expected % %', p_label, p_got, p_op, p_want;
  end if;
end $$;

do $$
declare
  founder   uuid := 'aa000000-0000-4000-8000-0000000000a1';
  other     uuid := 'aa000000-0000-4000-8000-0000000000a3';
  reviewer  uuid := 'aa000000-0000-4000-8000-0000000000a5';
  payer     uuid := 'aa000000-0000-4000-8000-0000000000a6';
  suspended uuid := 'aa000000-0000-4000-8000-0000000000a7';
  booker    uuid := 'aa000000-0000-4000-8000-0000000000a8';
  q_book    text := 'select count(*) from public.bookings where user_id = ''aa000000-0000-4000-8000-0000000000a2''';
  q_pay     text := 'select count(*) from public.payments';
  q_app     text := 'select count(*) from public.host_applications where user_id = ''aa000000-0000-4000-8000-0000000000a2''';
  q_hacct   text := 'select count(*) from public.host_accounts where user_id = ''aa000000-0000-4000-8000-0000000000a4''';
  q_part    text := 'select count(*) from public.booking_participants where booking_id = ''aa000000-0000-4000-8000-0000000000f1''';
  q_dep     text := 'select count(*) from public.experience_departures where id = ''aa000000-0000-4000-8000-0000000000d1''';
  q_draft   text := 'select count(*) from public.experiences where id = ''aa000000-0000-4000-8000-0000000000b2''';
  q_rev     text := 'select count(*) from public.reviews';
  q_legal   text := 'select count(*) from public.legal_acceptances where user_id = ''aa000000-0000-4000-8000-0000000000a2''';
begin
  -- ── hosts:review reviewer ───────────────────────────────────────────────
  perform pg_temp.expect('reviewer reads host_applications', pg_temp.count_as(reviewer, q_app), '>=', 1);
  perform pg_temp.expect('reviewer reads host_accounts',     pg_temp.count_as(reviewer, q_hacct), '>=', 1);
  perform pg_temp.expect('reviewer reads payments == 0',     pg_temp.count_as(reviewer, q_pay), '=', 0);
  perform pg_temp.expect('reviewer reads bookings == 0',     pg_temp.count_as(reviewer, q_book), '=', 0);
  perform pg_temp.expect('reviewer reads booking_participants == 0', pg_temp.count_as(reviewer, q_part), '=', 0);
  perform pg_temp.expect('reviewer reads draft experience == 0', pg_temp.count_as(reviewer, q_draft), '=', 0);

  -- ── payments:read payer ────────────────────────────────────────────────
  perform pg_temp.expect('payer reads payments', pg_temp.count_as(payer, q_pay), '>=', 1);
  perform pg_temp.expect('payer reads host_applications == 0', pg_temp.count_as(payer, q_app), '=', 0);
  perform pg_temp.expect('payer reads bookings == 0', pg_temp.count_as(payer, q_book), '=', 0);

  -- ── bookings:read booker ──────────────────────────────────────────────
  perform pg_temp.expect('booker reads bookings', pg_temp.count_as(booker, q_book), '>=', 1);
  perform pg_temp.expect('booker reads booking_participants', pg_temp.count_as(booker, q_part), '>=', 1);
  perform pg_temp.expect('booker reads departures', pg_temp.count_as(booker, q_dep), '>=', 1);
  perform pg_temp.expect('booker reads legal_acceptances', pg_temp.count_as(booker, q_legal), '>=', 1);
  perform pg_temp.expect('booker reads payments == 0', pg_temp.count_as(booker, q_pay), '=', 0);

  -- ── suspended staff: nothing, everywhere ─────────────────────────────
  perform pg_temp.expect('suspended reads host_applications == 0', pg_temp.count_as(suspended, q_app), '=', 0);
  perform pg_temp.expect('suspended reads payments == 0', pg_temp.count_as(suspended, q_pay), '=', 0);
  perform pg_temp.expect('suspended reads bookings == 0', pg_temp.count_as(suspended, q_book), '=', 0);

  -- ── founder: all scopes -> full access still works ──────────────────
  perform pg_temp.expect('founder reads bookings',          pg_temp.count_as(founder, q_book), '>=', 1);
  perform pg_temp.expect('founder reads payments',          pg_temp.count_as(founder, q_pay), '>=', 1);
  perform pg_temp.expect('founder reads host_applications', pg_temp.count_as(founder, q_app), '>=', 1);
  perform pg_temp.expect('founder reads reviews',           pg_temp.count_as(founder, q_rev), '>=', 1);
  perform pg_temp.expect('founder reads draft experience',  pg_temp.count_as(founder, q_draft), '>=', 1);
  perform pg_temp.expect('founder reads legal_acceptances', pg_temp.count_as(founder, q_legal), '>=', 1);

  -- ── staff_members visibility ───────────────────────────────────────
  perform pg_temp.expect('reviewer reads OWN staff row',
    pg_temp.count_as(reviewer, 'select count(*) from public.staff_members where user_id = ''aa000000-0000-4000-8000-0000000000a5'''), '=', 1);
  perform pg_temp.expect('reviewer reads ANOTHER staff row == 0',
    pg_temp.count_as(reviewer, 'select count(*) from public.staff_members where user_id = ''aa000000-0000-4000-8000-0000000000a6'''), '=', 0);
  perform pg_temp.expect('reviewer total staff rows visible == 1',
    pg_temp.count_as(reviewer, 'select count(*) from public.staff_members'), '=', 1);
  perform pg_temp.expect('founder reads all staff rows (>=5)',
    pg_temp.count_as(founder, 'select count(*) from public.staff_members'), '>=', 5);

  -- ── PERMANENT NEGATIVE: plain traveler, no staff row ───────────────
  perform pg_temp.expect('other traveler bookings == 0',   pg_temp.count_as(other, q_book), '=', 0);
  perform pg_temp.expect('other traveler payments == 0',   pg_temp.count_as(other, q_pay), '=', 0);
  perform pg_temp.expect('other traveler host_apps == 0',  pg_temp.count_as(other, q_app), '=', 0);
  perform pg_temp.expect('other traveler staff_members == 0', pg_temp.count_as(other, 'select count(*) from public.staff_members'), '=', 0);
  perform pg_temp.expect('other traveler admin_audit_log == 0', pg_temp.count_as(other, 'select count(*) from public.admin_audit_log'), '=', 0);
  perform pg_temp.expect('other traveler legal_acceptances == 0', pg_temp.count_as(other, q_legal), '=', 0);
end $$;

-- anon reads nothing from the scoped tables (whether by grant denial or RLS)
do $$
begin
  perform pg_temp.expect('anon reads bookings == 0',
    pg_temp.count_as_anon('select count(*) from public.bookings'), '=', 0);
  perform pg_temp.expect('anon reads payments == 0',
    pg_temp.count_as_anon('select count(*) from public.payments'), '=', 0);
  perform pg_temp.expect('anon reads host_applications == 0',
    pg_temp.count_as_anon('select count(*) from public.host_applications'), '=', 0);
  perform pg_temp.expect('anon reads staff_members == 0',
    pg_temp.count_as_anon('select count(*) from public.staff_members'), '=', 0);
end $$;

-- private profile columns are not client-readable, not even for a founder
do $$
declare v_denied boolean := false;
begin
  set local role authenticated;
  perform set_config('request.jwt.claims',
    json_build_object('sub', 'aa000000-0000-4000-8000-0000000000a1', 'role', 'authenticated')::text, true);
  begin
    perform phone from public.profiles where id = 'aa000000-0000-4000-8000-0000000000a2';
  exception when insufficient_privilege then
    v_denied := true;
  end;
  reset role;
  if not v_denied then raise exception 'FAIL: founder directly selected profiles.phone'; end if;
end $$;

rollback;
