-- Focused Phase 6 private Presence authorization assertions.

begin;

do $$
declare
  v_host uuid := '96000000-0000-4000-8000-000000000001';
  v_traveler uuid := '96000000-0000-4000-8000-000000000002';
  v_outsider uuid := '96000000-0000-4000-8000-000000000003';
  v_category uuid := '96000000-0000-4000-8000-000000000004';
  v_region uuid := '96000000-0000-4000-8000-000000000005';
  v_experience uuid := '96000000-0000-4000-8000-000000000006';
  v_departure uuid := '96000000-0000-4000-8000-000000000007';
  v_booking uuid := '96000000-0000-4000-8000-000000000008';
begin
  insert into auth.users (
    id, instance_id, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role, aud
  ) values
    (v_host, '00000000-0000-0000-0000-000000000000', 'presence-host@example.test', 'encrypted', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), 'authenticated', 'authenticated'),
    (v_traveler, '00000000-0000-0000-0000-000000000000', 'presence-traveler@example.test', 'encrypted', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), 'authenticated', 'authenticated'),
    (v_outsider, '00000000-0000-0000-0000-000000000000', 'presence-outsider@example.test', 'encrypted', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), 'authenticated', 'authenticated')
  on conflict (id) do nothing;

  insert into public.profiles (id, full_name, role) values
    (v_host, 'Presence Host', 'traveler'),
    (v_traveler, 'Presence Traveler', 'traveler'),
    (v_outsider, 'Presence Outsider', 'traveler')
  on conflict (id) do nothing;
  insert into public.categories (id, slug, name_en, name_ne)
  values (v_category, 'presence-test-category', 'Presence Test', 'Presence Test')
  on conflict (id) do nothing;
  insert into public.regions (id, slug, name_en, name_ne)
  values (v_region, 'presence-test-region', 'Presence Test', 'Presence Test')
  on conflict (id) do nothing;
  insert into public.experiences (
    id, host_id, category_id, region_id, title, slug,
    cover_image_url, price_paisa, status
  ) values (
    v_experience, v_host, v_category, v_region, 'Presence Test Experience',
    'presence-test-experience', 'https://example.test/image.jpg', 10000, 'published'
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
    v_booking, 'PRES-RLS-1', v_traveler, v_experience, v_departure, 1,
    'Presence Traveler', '9800000000', 10000, 10000, 'pending'
  ) on conflict (id) do nothing;
end $$;

-- A booking participant can publish and receive Presence on the exact private
-- trip topic. The row is only a transaction-local authorization probe.
do $$
declare
  v_count integer;
begin
  set local role authenticated;
  perform set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', '96000000-0000-4000-8000-000000000002',
      'role', 'authenticated'
    )::text,
    true
  );
  perform set_config(
    'realtime.topic',
    'trip-presence:96000000-0000-4000-8000-000000000008',
    true
  );
  insert into realtime.messages (topic, extension, private, payload)
  values (
    'trip-presence:96000000-0000-4000-8000-000000000008',
    'presence',
    true,
    '{"typing":true}'::jsonb
  );
  select count(*) into v_count
  from realtime.messages
  where topic = 'trip-presence:96000000-0000-4000-8000-000000000008'
    and extension = 'presence';
  if v_count <> 1 then
    raise exception 'FAIL: trip member could not use private Presence';
  end if;
end $$;

-- An unrelated authenticated user can neither receive nor publish on the
-- booking topic, even when the UUID is known.
do $$
declare
  v_count integer;
  v_inserted boolean := false;
begin
  set local role authenticated;
  perform set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', '96000000-0000-4000-8000-000000000003',
      'role', 'authenticated'
    )::text,
    true
  );
  perform set_config(
    'realtime.topic',
    'trip-presence:96000000-0000-4000-8000-000000000008',
    true
  );
  select count(*) into v_count
  from realtime.messages
  where topic = 'trip-presence:96000000-0000-4000-8000-000000000008'
    and extension = 'presence';
  begin
    insert into realtime.messages (topic, extension, private, payload)
    values (
      'trip-presence:96000000-0000-4000-8000-000000000008',
      'presence',
      true,
      '{"typing":true}'::jsonb
    );
    v_inserted := true;
  exception when insufficient_privilege then
    v_inserted := false;
  end;
  if v_count <> 0 or v_inserted then
    raise exception 'FAIL: outsider accessed private trip Presence';
  end if;
end $$;

reset role;
select set_config('request.jwt.claims', '{}', true);
select set_config('realtime.topic', '', true);

do $$
begin
  if private.can_join_trip_presence(
    'trip-presence:not-a-uuid',
    '96000000-0000-4000-8000-000000000002'
  ) then
    raise exception 'FAIL: malformed Presence topic was authorized';
  end if;
end $$;

rollback;
