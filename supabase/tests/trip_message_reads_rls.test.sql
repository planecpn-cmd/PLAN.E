-- Focused Phase 1 messaging RLS assertions.
-- Run with psql -v ON_ERROR_STOP=1 after applying migrations.

begin;

do $$
declare
  v_host uuid := '91000000-0000-0000-0000-000000000001';
  v_traveler uuid := '91000000-0000-0000-0000-000000000002';
  v_outsider uuid := '91000000-0000-0000-0000-000000000003';
  v_category uuid := '91000000-0000-0000-0000-000000000004';
  v_region uuid := '91000000-0000-0000-0000-000000000005';
  v_experience uuid := '91000000-0000-0000-0000-000000000006';
  v_departure uuid := '91000000-0000-0000-0000-000000000007';
  v_booking uuid := '91000000-0000-0000-0000-000000000008';
  v_message uuid := '91000000-0000-0000-0000-000000000009';
begin
  insert into auth.users (
    id, instance_id, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role, aud
  ) values
    (v_host, '00000000-0000-0000-0000-000000000000', 'read-host@example.test', 'encrypted', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), 'authenticated', 'authenticated'),
    (v_traveler, '00000000-0000-0000-0000-000000000000', 'read-traveler@example.test', 'encrypted', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), 'authenticated', 'authenticated'),
    (v_outsider, '00000000-0000-0000-0000-000000000000', 'read-outsider@example.test', 'encrypted', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), 'authenticated', 'authenticated')
  on conflict (id) do nothing;

  insert into public.profiles (id, full_name, role) values
    (v_host, 'Read Host', 'traveler'),
    (v_traveler, 'Read Traveler', 'traveler'),
    (v_outsider, 'Read Outsider', 'traveler')
  on conflict (id) do nothing;

  insert into public.categories (id, slug, name_en, name_ne)
  values (v_category, 'read-test-category', 'Read Test', 'Read Test')
  on conflict (id) do nothing;
  insert into public.regions (id, slug, name_en, name_ne)
  values (v_region, 'read-test-region', 'Read Test', 'Read Test')
  on conflict (id) do nothing;
  insert into public.experiences (
    id, host_id, category_id, region_id, title, slug,
    cover_image_url, price_paisa, status
  ) values (
    v_experience, v_host, v_category, v_region, 'Read Test Experience',
    'read-test-experience', 'https://example.test/image.jpg', 10000, 'published'
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
    v_booking, 'READ-RLS-1', v_traveler, v_experience, v_departure, 1,
    'Read Traveler', '9800000000', 10000, 10000, 'pending'
  ) on conflict (id) do nothing;
  insert into public.trip_messages (id, booking_id, sender_id, body)
  values (v_message, v_booking, v_host, 'Private fixture message')
  on conflict (id) do nothing;
end $$;

-- The booking trigger shadow-writes one container and both private members.
do $$
declare
  v_conversation_count int;
  v_member_count int;
  v_drift_count int;
begin
  select count(*) into v_conversation_count
  from public.trip_conversations
  where booking_id = '91000000-0000-0000-0000-000000000008';
  select count(*) into v_member_count
  from public.trip_conversation_members membership
  join public.trip_conversations conversation
    on conversation.id = membership.conversation_id
  where conversation.booking_id = '91000000-0000-0000-0000-000000000008';
  select count(*) into v_drift_count
  from private.trip_conversation_shadow_drift
  where booking_id = '91000000-0000-0000-0000-000000000008';
  if v_conversation_count <> 1 or v_member_count <> 2 or v_drift_count <> 0 then
    raise exception 'FAIL: booking shadow-write is inconsistent';
  end if;
end $$;

-- A trip member can mark the conversation read and see only their row.
do $$
declare
  v_count int;
  v_membership_count int;
  v_invalid_attachment_registered boolean := false;
begin
  set local role authenticated;
  perform set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', '91000000-0000-0000-0000-000000000002',
      'role', 'authenticated'
    )::text,
    true
  );
  perform public.mark_trip_conversation_read(
    '91000000-0000-0000-0000-000000000008'
  );
  perform public.send_trip_message(
    '91000000-0000-0000-0000-000000000008',
    '91000000-0000-0000-0000-000000000010',
    'Idempotent outbox fixture'
  );
  insert into storage.objects (id, bucket_id, name, owner, metadata)
  values (
    gen_random_uuid(),
    'trip-attachments',
    '91000000-0000-0000-0000-000000000008/91000000-0000-0000-0000-000000000002/91000000-0000-0000-0000-000000000010.jpg',
    '91000000-0000-0000-0000-000000000002',
    '{"mimetype":"image/jpeg","size":1024}'::jsonb
  );
  perform public.register_trip_message_attachment(
    '91000000-0000-0000-0000-000000000010',
    '91000000-0000-0000-0000-000000000008/91000000-0000-0000-0000-000000000002/91000000-0000-0000-0000-000000000010.jpg',
    'image/jpeg',
    1024
  );
  begin
    perform public.register_trip_message_attachment(
      '91000000-0000-0000-0000-000000000010',
      '91000000-0000-0000-0000-000000000008/91000000-0000-0000-0000-000000000002/91000000-0000-0000-0000-000000000010.jpg',
      'application/octet-stream',
      20971520
    );
    v_invalid_attachment_registered := true;
  exception when others then
    v_invalid_attachment_registered := false;
  end;
  perform public.send_trip_message(
    '91000000-0000-0000-0000-000000000008',
    '91000000-0000-0000-0000-000000000010',
    'Idempotent outbox fixture'
  );
  select count(*) into v_count
  from public.trip_message_reads
  where conversation_id = '91000000-0000-0000-0000-000000000008';
  if v_count <> 1 then
    raise exception 'FAIL: trip member could not create/read own read state';
  end if;
  select count(*) into v_count
  from public.trip_conversations
  where booking_id = '91000000-0000-0000-0000-000000000008';
  select count(*) into v_membership_count
  from public.trip_conversation_members;
  if v_count <> 1 or v_membership_count <> 1 then
    raise exception 'FAIL: traveler conversation membership privacy failed';
  end if;
  select count(*) into v_count
  from public.trip_messages
  where client_message_id = '91000000-0000-0000-0000-000000000010';
  if v_count <> 1 then
    raise exception 'FAIL: client_message_id retry created duplicate messages';
  end if;
  select count(*) into v_count
  from public.trip_message_attachments
  where message_id = '91000000-0000-0000-0000-000000000010';
  if v_count <> 1 or v_invalid_attachment_registered then
    raise exception 'FAIL: attachment registration validation failed';
  end if;
end $$;

-- An unrelated authenticated user can neither see nor insert read state.
do $$
declare
  v_count int;
  v_conversation_count int;
  v_membership_count int;
  v_attachment_count int;
  v_storage_count int;
  v_inserted boolean := false;
begin
  set local role authenticated;
  perform set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', '91000000-0000-0000-0000-000000000003',
      'role', 'authenticated'
    )::text,
    true
  );
  select count(*) into v_count
  from public.trip_message_reads
  where conversation_id = '91000000-0000-0000-0000-000000000008';
  select count(*) into v_conversation_count from public.trip_conversations;
  select count(*) into v_membership_count
  from public.trip_conversation_members;
  select count(*) into v_attachment_count
  from public.trip_message_attachments;
  select count(*) into v_storage_count
  from storage.objects
  where bucket_id = 'trip-attachments';
  begin
    insert into public.trip_message_reads (conversation_id, user_id)
    values (
      '91000000-0000-0000-0000-000000000008',
      '91000000-0000-0000-0000-000000000003'
    );
    v_inserted := true;
  exception when others then
    v_inserted := false;
  end;
  if v_count <> 0 or v_conversation_count <> 0 or
      v_membership_count <> 0 or v_attachment_count <> 0 or
      v_storage_count <> 0 or v_inserted then
    raise exception 'FAIL: outsider accessed private trip read state';
  end if;
end $$;

rollback;
