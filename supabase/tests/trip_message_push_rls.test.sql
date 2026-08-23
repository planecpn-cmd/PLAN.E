-- Focused Phase 5 push privacy and event-queue assertions.
-- Run with psql -v ON_ERROR_STOP=1 after applying migrations.

begin;

do $$
declare
  v_host uuid := '95000000-0000-0000-0000-000000000001';
  v_traveler uuid := '95000000-0000-0000-0000-000000000002';
  v_outsider uuid := '95000000-0000-0000-0000-000000000003';
  v_category uuid := '95000000-0000-0000-0000-000000000004';
  v_region uuid := '95000000-0000-0000-0000-000000000005';
  v_experience uuid := '95000000-0000-0000-0000-000000000006';
  v_departure uuid := '95000000-0000-0000-0000-000000000007';
  v_booking uuid := '95000000-0000-0000-0000-000000000008';
begin
  insert into auth.users (
    id, instance_id, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role, aud
  ) values
    (v_host, '00000000-0000-0000-0000-000000000000', 'push-host@example.test', 'encrypted', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), 'authenticated', 'authenticated'),
    (v_traveler, '00000000-0000-0000-0000-000000000000', 'push-traveler@example.test', 'encrypted', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), 'authenticated', 'authenticated'),
    (v_outsider, '00000000-0000-0000-0000-000000000000', 'push-outsider@example.test', 'encrypted', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), 'authenticated', 'authenticated')
  on conflict (id) do nothing;

  insert into public.profiles (id, full_name, role) values
    (v_host, 'Push Host', 'traveler'),
    (v_traveler, 'Push Traveler', 'traveler'),
    (v_outsider, 'Push Outsider', 'traveler')
  on conflict (id) do nothing;

  insert into public.categories (id, slug, name_en, name_ne)
  values (v_category, 'push-test-category', 'Push Test', 'Push Test')
  on conflict (id) do nothing;
  insert into public.regions (id, slug, name_en, name_ne)
  values (v_region, 'push-test-region', 'Push Test', 'Push Test')
  on conflict (id) do nothing;
  insert into public.experiences (
    id, host_id, category_id, region_id, title, slug,
    cover_image_url, price_paisa, status
  ) values (
    v_experience, v_host, v_category, v_region, 'Push Test Experience',
    'push-test-experience', 'https://example.test/image.jpg', 10000, 'published'
  ) on conflict (id) do nothing;
  insert into public.experience_departures (
    id, experience_id, start_date, end_date, total_spots, spots_left
  ) values (
    v_departure, v_experience, current_date + 1, current_date + 2, 2, 1
  ) on conflict (id) do nothing;
  insert into public.bookings (
    id, booking_ref, user_id, experience_id, departure_id, adults,
    contact_name, contact_phone, subtotal_paisa, total_paisa, status
  ) values (
    v_booking, 'PUSH-RLS-1', v_traveler, v_experience, v_departure, 1,
    'Push Traveler', '9800000000', 10000, 10000, 'pending'
  ) on conflict (id) do nothing;
end $$;

-- A user can register a device through the narrow RPC but cannot read either
-- raw tokens or delivery internals directly.
do $$
declare
  v_raw_token_readable boolean := false;
  v_deliveries_readable boolean := false;
begin
  set local role authenticated;
  perform set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', '95000000-0000-0000-0000-000000000002',
      'role', 'authenticated'
    )::text,
    true
  );
  perform public.register_trip_push_device(
    'fcm-registration-token-that-is-long-enough-for-testing',
    'android',
    'fcm'
  );

  begin
    perform count(*) from public.trip_push_device_tokens;
    v_raw_token_readable := true;
  exception when insufficient_privilege then
    v_raw_token_readable := false;
  end;
  begin
    perform count(*) from public.trip_push_deliveries;
    v_deliveries_readable := true;
  exception when insufficient_privilege then
    v_deliveries_readable := false;
  end;

  if v_raw_token_readable or v_deliveries_readable then
    raise exception 'FAIL: client could enumerate private push state';
  end if;
end $$;

-- The host message write succeeds even with no webhook Vault configuration,
-- and it creates exactly one content-free delivery for the traveler.
do $$
begin
  set local role authenticated;
  perform set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', '95000000-0000-0000-0000-000000000001',
      'role', 'authenticated'
    )::text,
    true
  );
  perform public.send_trip_message(
    '95000000-0000-0000-0000-000000000008',
    '95000000-0000-0000-0000-000000000009',
    'This private body must never be copied into the push queue'
  );
end $$;

reset role;
select set_config('request.jwt.claims', '{}', true);

do $$
declare
  v_token_count integer;
  v_delivery_count integer;
  v_has_body_column boolean;
begin
  select count(*) into v_token_count
  from public.trip_push_device_tokens
  where user_id = '95000000-0000-0000-0000-000000000002'
    and is_active;
  select count(*) into v_delivery_count
  from public.trip_push_deliveries
  where message_id = '95000000-0000-0000-0000-000000000009'
    and recipient_id = '95000000-0000-0000-0000-000000000002'
    and target_route = '/chat/95000000-0000-0000-0000-000000000008';
  select exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'trip_push_deliveries'
      and column_name in ('body', 'message_body', 'content')
  ) into v_has_body_column;

  if v_token_count <> 1 or v_delivery_count <> 1 or v_has_body_column then
    raise exception 'FAIL: push registry/queue integrity check failed';
  end if;
end $$;

-- An outsider cannot disable another user's token or claim service work.
do $$
declare
  v_claimed boolean := false;
begin
  set local role authenticated;
  perform set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', '95000000-0000-0000-0000-000000000003',
      'role', 'authenticated'
    )::text,
    true
  );
  perform public.unregister_trip_push_device(
    'fcm-registration-token-that-is-long-enough-for-testing',
    'fcm'
  );
  begin
    perform public.claim_trip_push_deliveries(
      '95000000-0000-0000-0000-000000000009'
    );
    v_claimed := true;
  exception when insufficient_privilege then
    v_claimed := false;
  end;
  if v_claimed then
    raise exception 'FAIL: outsider claimed service-only push work';
  end if;
end $$;

reset role;
select set_config('request.jwt.claims', '{}', true);

do $$
begin
  if not exists (
    select 1 from public.trip_push_device_tokens
    where user_id = '95000000-0000-0000-0000-000000000002'
      and is_active
  ) then
    raise exception 'FAIL: outsider disabled another user device';
  end if;
end $$;

-- Service work is claimed atomically; a duplicate webhook cannot claim the
-- same delivery again while the first invocation owns its lease.
do $$
declare
  v_first_claim integer;
  v_second_claim integer;
begin
  select count(*) into v_first_claim
  from public.claim_trip_push_deliveries(
    '95000000-0000-0000-0000-000000000009'
  );
  select count(*) into v_second_claim
  from public.claim_trip_push_deliveries(
    '95000000-0000-0000-0000-000000000009'
  );
  if v_first_claim <> 1 or v_second_claim <> 0 then
    raise exception 'FAIL: push delivery claim was not idempotent';
  end if;
end $$;

rollback;
