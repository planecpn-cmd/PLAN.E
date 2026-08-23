-- Focused Phase 6D reporting, blocking, and moderation assertions.
begin;

do $$
declare
  h uuid := '96300000-0000-4000-8000-000000000001';
  t uuid := '96300000-0000-4000-8000-000000000002';
  o uuid := '96300000-0000-4000-8000-000000000003';
  a uuid := '96300000-0000-4000-8000-000000000004';
  c uuid := '96300000-0000-4000-8000-000000000005';
  r uuid := '96300000-0000-4000-8000-000000000006';
  e uuid := '96300000-0000-4000-8000-000000000007';
  d uuid := '96300000-0000-4000-8000-000000000008';
  b uuid := '96300000-0000-4000-8000-000000000009';
begin
  insert into auth.users (id, instance_id, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at,
    updated_at, role, aud) values
    (h, '00000000-0000-0000-0000-000000000000', 'safe-host@example.test', 'x', now(), '{}', '{}', now(), now(), 'authenticated', 'authenticated'),
    (t, '00000000-0000-0000-0000-000000000000', 'safe-traveler@example.test', 'x', now(), '{}', '{}', now(), now(), 'authenticated', 'authenticated'),
    (o, '00000000-0000-0000-8000-000000000000', 'safe-outsider@example.test', 'x', now(), '{}', '{}', now(), now(), 'authenticated', 'authenticated'),
    (a, '00000000-0000-0000-0000-000000000000', 'safe-admin@example.test', 'x', now(), '{}', '{}', now(), now(), 'authenticated', 'authenticated')
  on conflict (id) do nothing;
  insert into public.profiles (id, full_name, role) values
    (h, 'Safety Host', 'traveler'), (t, 'Safety Traveler', 'traveler'),
    (o, 'Safety Outsider', 'traveler'), (a, 'Safety Admin', 'admin')
  on conflict (id) do update set role = excluded.role;
  insert into public.categories (id, slug, name_en, name_ne)
    values (c, 'safety-test-category', 'Safety', 'Safety') on conflict do nothing;
  insert into public.regions (id, slug, name_en, name_ne)
    values (r, 'safety-test-region', 'Safety', 'Safety') on conflict do nothing;
  insert into public.experiences (id, host_id, category_id, region_id, title,
    slug, cover_image_url, price_paisa, status) values
    (e, h, c, r, 'Safety Experience', 'safety-experience',
     'https://example.test/x.jpg', 10000, 'published') on conflict do nothing;
  insert into public.experience_departures (id, experience_id, start_date,
    end_date, total_spots, spots_left) values
    (d, e, current_date + 1, current_date + 2, 2, 1) on conflict do nothing;
  insert into public.bookings (id, booking_ref, user_id, experience_id,
    departure_id, adults, contact_name, contact_phone, subtotal_paisa,
    total_paisa, status) values
    (b, 'SAFETY-1', t, e, d, 1, 'Safety Traveler', '9800000000',
     10000, 10000, 'pending') on conflict do nothing;
end $$;

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"96300000-0000-4000-8000-000000000001","role":"authenticated"}', true);
select public.send_trip_message(
  '96300000-0000-4000-8000-000000000009',
  '96300000-0000-4000-8000-000000000010', 'Reportable message');

select set_config('request.jwt.claims',
  '{"sub":"96300000-0000-4000-8000-000000000002","role":"authenticated"}', true);
select public.report_trip_message(
  '96300000-0000-4000-8000-000000000010', 'spam', 'test report');
select public.block_trip_participant(
  '96300000-0000-4000-8000-000000000009',
  '96300000-0000-4000-8000-000000000001');

do $$
declare allowed boolean := true; state record;
begin
  select * into state from public.get_trip_conversation_safety(
    '96300000-0000-4000-8000-000000000009');
  begin
    perform public.send_trip_message(
      '96300000-0000-4000-8000-000000000009',
      '96300000-0000-4000-8000-000000000011', 'blocked');
  exception when others then allowed := false;
  end;
  if allowed or not state.blocked_by_me or state.can_message then
    raise exception 'FAIL: block did not stop messaging';
  end if;
end $$;

select set_config('request.jwt.claims',
  '{"sub":"96300000-0000-4000-8000-000000000003","role":"authenticated"}', true);
do $$ declare allowed boolean := true; visible integer;
begin
  select count(*) into visible from public.trip_message_reports;
  begin
    perform public.report_trip_message(
      '96300000-0000-4000-8000-000000000010', 'spam', null);
  exception when others then allowed := false;
  end;
  if allowed or visible <> 0 then
    raise exception 'FAIL: outsider accessed reporting data';
  end if;
end $$;

select set_config('request.jwt.claims',
  '{"sub":"96300000-0000-4000-8000-000000000004","role":"authenticated"}', true);
do $$ declare report_id uuid;
begin
  select queue.report_id into report_id
  from public.get_trip_moderation_queue() queue limit 1;
  if report_id is null then raise exception 'FAIL: admin queue empty'; end if;
  perform public.review_trip_message_report(report_id, 'resolved', 'reviewed');
end $$;

select set_config('request.jwt.claims',
  '{"sub":"96300000-0000-4000-8000-000000000002","role":"authenticated"}', true);
select public.unblock_trip_participant(
  '96300000-0000-4000-8000-000000000001');
select public.send_trip_message(
  '96300000-0000-4000-8000-000000000009',
  '96300000-0000-4000-8000-000000000012', 'unblocked');

rollback;
