-- =============================================================================
-- seed_test.sql  —  deterministic fixtures for the automated test suite (P0.2)
-- =============================================================================
-- Loaded AFTER migrations + supabase/seed.sql, by scripts/test-all.sh, before
-- the SQL assertion files run. Never referenced by supabase/config.toml's
-- [db.seed]; it must not pollute `supabase db reset` for app development.
--
-- Everything here uses hard-coded UUIDs so assertions can reference rows by
-- constant. Re-running this file is a no-op (every write is upsert / guarded).
--
--   Profiles
--     11111111-1111-4111-8111-000000000001  traveler        traveler@planetest.local
--     11111111-1111-4111-8111-000000000002  host_applicant  applicant@planetest.local
--     11111111-1111-4111-8111-000000000003  host (approved)  host@planetest.local
--     11111111-1111-4111-8111-000000000004  admin           admin@planetest.local
--
--   host_applications
--     22222222-2222-4222-8222-000000000001  status = submitted  (by host_applicant)
--     22222222-2222-4222-8222-000000000002  status = approved   (by approved host)
--
--   experience / departure (owned by the approved host)
--     33333333-3333-4333-8333-000000000001  experiences   (published)
--     44444444-4444-4444-8444-000000000001  experience_departures (open)
--
--   bookings (all made by the traveler) + matching payments
--     55555555-5555-4555-8555-000000000001  booking pending    / payment 66..01 initiated
--     55555555-5555-4555-8555-000000000002  booking confirmed  / payment 66..02 paid
--     55555555-5555-4555-8555-000000000003  booking completed  / payment 66..03 failed
-- =============================================================================

do $$
declare
  v_traveler   constant uuid := '11111111-1111-4111-8111-000000000001';
  v_applicant  constant uuid := '11111111-1111-4111-8111-000000000002';
  v_host       constant uuid := '11111111-1111-4111-8111-000000000003';
  v_admin      constant uuid := '11111111-1111-4111-8111-000000000004';

  v_app_submitted constant uuid := '22222222-2222-4222-8222-000000000001';
  v_app_approved  constant uuid := '22222222-2222-4222-8222-000000000002';

  v_exp        constant uuid := '33333333-3333-4333-8333-000000000001';
  v_dep        constant uuid := '44444444-4444-4444-8444-000000000001';

  v_book_pending   constant uuid := '55555555-5555-4555-8555-000000000001';
  v_book_confirmed constant uuid := '55555555-5555-4555-8555-000000000002';
  v_book_completed constant uuid := '55555555-5555-4555-8555-000000000003';

  v_pay_initiated constant uuid := '66666666-6666-4666-8666-000000000001';
  v_pay_paid      constant uuid := '66666666-6666-4666-8666-000000000002';
  v_pay_failed    constant uuid := '66666666-6666-4666-8666-000000000003';

  v_category uuid;
  v_region   uuid;
begin
  -- A migration / seed is a trusted administrative operation. Identify the
  -- transaction as service_role so the privilege-escalation guards on
  -- profiles.role / bookings.status / payments allow these writes.
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);

  select id into v_category from public.categories where slug = 'trekking' limit 1;
  select id into v_region   from public.regions    where slug = 'annapurna' limit 1;
  if v_category is null or v_region is null then
    raise exception 'seed_test.sql: base taxonomy (trekking / annapurna) missing — run supabase/seed.sql first';
  end if;

  -- ---- auth users (handle_new_user trigger seeds a matching profiles row) ----
  insert into auth.users (
    id, instance_id, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role, aud
  ) values
    (v_traveler,  '00000000-0000-0000-0000-000000000000', 'traveler@planetest.local',  'x', now(),
      '{"provider":"email","providers":["email"]}', '{"full_name":"Test Traveler"}',  now() - interval '40 days', now(), 'authenticated', 'authenticated'),
    (v_applicant, '00000000-0000-0000-0000-000000000000', 'applicant@planetest.local', 'x', now(),
      '{"provider":"email","providers":["email"]}', '{"full_name":"Test Applicant"}', now() - interval '30 days', now(), 'authenticated', 'authenticated'),
    (v_host,      '00000000-0000-0000-0000-000000000000', 'host@planetest.local',      'x', now(),
      '{"provider":"email","providers":["email"]}', '{"full_name":"Test Host"}',      now() - interval '60 days', now(), 'authenticated', 'authenticated'),
    (v_admin,     '00000000-0000-0000-0000-000000000000', 'admin@planetest.local',     'x', now(),
      '{"provider":"email","providers":["email"]}', '{"full_name":"Test Admin"}',     now() - interval '90 days', now(), 'authenticated', 'authenticated')
  on conflict (id) do nothing;

  -- ---- profiles: set the role each fixture needs (trigger defaulted traveler) ----
  insert into public.profiles (id, full_name, role, onboarding_complete, created_at, updated_at)
  values
    (v_traveler,  'Test Traveler',  'traveler'::public.user_role,       true, now() - interval '40 days', now()),
    (v_applicant, 'Test Applicant', 'host_applicant'::public.user_role, true, now() - interval '30 days', now()),
    (v_host,      'Test Host',      'host'::public.user_role,           true, now() - interval '60 days', now()),
    (v_admin,     'Test Admin',     'admin'::public.user_role,          true, now() - interval '90 days', now())
  on conflict (id) do update set
    full_name = excluded.full_name,
    role = excluded.role,
    onboarding_complete = true,
    updated_at = now();

  -- ---- host_applications: one submitted, one approved -----------------------
  -- Inserting the approved row fires sync_host_account_from_application, which
  -- creates the host_accounts row and (re)asserts profiles.role = 'host'.
  insert into public.host_applications (
    id, user_id, status, current_step, category_id, title, description,
    location, photos, application_data, submitted_at, reviewed_at, reviewer_note,
    created_at, updated_at
  ) values
    (v_app_submitted, v_applicant, 'submitted'::public.host_app_status, 8, v_category,
      'Test Applicant — trekking', 'Automated-test host application awaiting review.',
      'Pokhara, Nepal', array[]::text[],
      '{"hosting_type":"adventure","host_type":"individual","terms_accepted":true}'::jsonb,
      now() - interval '5 days', null, null,
      now() - interval '5 days', now()),
    (v_app_approved, v_host, 'approved'::public.host_app_status, 8, v_category,
      'Test Host — trekking', 'Automated-test host application, already approved.',
      'Pokhara, Nepal', array[]::text[],
      '{"hosting_type":"adventure","host_type":"individual","terms_accepted":true}'::jsonb,
      now() - interval '20 days', now() - interval '18 days', 'Automated test fixture: approved.',
      now() - interval '20 days', now())
  on conflict (user_id) do update set
    status = excluded.status,
    current_step = excluded.current_step,
    category_id = excluded.category_id,
    title = excluded.title,
    description = excluded.description,
    location = excluded.location,
    application_data = excluded.application_data,
    submitted_at = excluded.submitted_at,
    reviewed_at = excluded.reviewed_at,
    reviewer_note = excluded.reviewer_note,
    updated_at = now();

  -- ---- one published experience + open departure, owned by the approved host --
  insert into public.experiences (
    id, host_id, category_id, region_id, title, slug, summary, description,
    cover_image_url, location_name, meeting_point, duration_hours, difficulty,
    group_size_min, group_size_max, min_age, price_paisa, child_price_paisa,
    included, bring_list, status, created_at, updated_at
  ) values (
    v_exp, v_host, v_category, v_region,
    'Test Mardi Himal Trek', 'test-mardi-himal-trek',
    'Automated-test published experience.',
    'Automated-test experience used by the booking/payment fixtures.',
    'https://example.test/cover.webp', 'Kaski, Nepal', 'Lakeside, Pokhara',
    120, 'challenging'::public.difficulty_level,
    1, 8, 16, 1250000, 900000,
    array['Local guide','Accommodation'], array['Hiking boots','Warm layers'],
    'published'::public.experience_status,
    now() - interval '20 days', now()
  )
  on conflict (id) do update set
    host_id = excluded.host_id, status = excluded.status,
    price_paisa = excluded.price_paisa, updated_at = now();

  insert into public.experience_departures (
    id, experience_id, start_date, end_date, total_spots, spots_left, status, created_at
  ) values (
    v_dep, v_exp, current_date + 30, current_date + 34, 8, 6, 'open', now() - interval '20 days'
  )
  on conflict (id) do update set
    start_date = excluded.start_date, end_date = excluded.end_date,
    total_spots = excluded.total_spots, spots_left = excluded.spots_left,
    status = excluded.status;

  -- ---- bookings: pending / confirmed / completed --------------------------
  -- total_paisa must equal subtotal + addons + fees (bookings_total_paisa_consistent).
  insert into public.bookings (
    id, booking_ref, user_id, experience_id, departure_id, adults, children,
    contact_name, contact_phone, subtotal_paisa, addons_paisa, fees_paisa,
    total_paisa, status, quote_expires_at, is_draft, completed_at, created_at, updated_at
  ) values
    (v_book_pending, 'TEST-PENDING-0001', v_traveler, v_exp, v_dep, 2, 0,
      'Test Traveler', '9800000001', 2500000, 0, 125000, 2625000,
      'pending'::public.booking_status, now() + interval '10 minutes', false, null,
      now() - interval '10 minutes', now()),
    (v_book_confirmed, 'TEST-CONFIRMED-01', v_traveler, v_exp, v_dep, 1, 0,
      'Test Traveler', '9800000001', 1250000, 0, 62500, 1312500,
      'confirmed'::public.booking_status, null, false, null,
      now() - interval '6 days', now()),
    (v_book_completed, 'TEST-COMPLETED-01', v_traveler, v_exp, v_dep, 3, 0,
      'Test Traveler', '9800000001', 3750000, 0, 187500, 3937500,
      'completed'::public.booking_status, null, false, now() - interval '1 day',
      now() - interval '15 days', now())
  on conflict (id) do update set
    status = excluded.status, subtotal_paisa = excluded.subtotal_paisa,
    fees_paisa = excluded.fees_paisa, total_paisa = excluded.total_paisa,
    quote_expires_at = excluded.quote_expires_at, completed_at = excluded.completed_at,
    updated_at = now();

  -- ---- payments: initiated / paid / failed (one per booking) --------------
  insert into public.payments (
    id, booking_id, provider, provider_ref, idempotency_key, amount_paisa,
    status, raw_response, paid_at, created_at, updated_at
  ) values
    (v_pay_initiated, v_book_pending, 'khalti'::public.payment_provider, null,
      'test-idem-initiated-0001', 2625000, 'initiated'::public.payment_status,
      '{"pidx":"test-pidx-initiated"}'::jsonb, null,
      now() - interval '9 minutes', now()),
    (v_pay_paid, v_book_confirmed, 'khalti'::public.payment_provider, 'test-txn-paid-0001',
      'test-idem-paid-0001', 1312500, 'paid'::public.payment_status,
      '{"pidx":"test-pidx-paid","status":"Completed","total_amount":1312500}'::jsonb,
      now() - interval '6 days', now() - interval '6 days', now()),
    (v_pay_failed, v_book_completed, 'esewa'::public.payment_provider, null,
      'test-idem-failed-0001', 3937500, 'failed'::public.payment_status,
      '{"transaction_uuid":"test-uuid-failed","status":"CANCELED"}'::jsonb, null,
      now() - interval '15 days', now())
  on conflict (id) do update set
    status = excluded.status, provider_ref = excluded.provider_ref,
    raw_response = excluded.raw_response, paid_at = excluded.paid_at,
    updated_at = now();

  raise notice 'seed_test.sql: fixtures loaded (4 profiles, 2 host applications, 1 experience, 3 bookings, 3 payments)';
end $$;
