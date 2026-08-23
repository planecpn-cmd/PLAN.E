-- Focused Phase 6B granular receipt and privacy assertions.

begin;

do $$
declare
  v_host uuid := '96100000-0000-4000-8000-000000000001';
  v_traveler uuid := '96100000-0000-4000-8000-000000000002';
  v_outsider uuid := '96100000-0000-4000-8000-000000000003';
  v_category uuid := '96100000-0000-4000-8000-000000000004';
  v_region uuid := '96100000-0000-4000-8000-000000000005';
  v_experience uuid := '96100000-0000-4000-8000-000000000006';
  v_departure uuid := '96100000-0000-4000-8000-000000000007';
  v_booking uuid := '96100000-0000-4000-8000-000000000008';
begin
  insert into auth.users (
    id, instance_id, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role, aud
  ) values
    (v_host, '00000000-0000-0000-0000-000000000000', 'receipt-host@example.test', 'encrypted', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), 'authenticated', 'authenticated'),
    (v_traveler, '00000000-0000-0000-0000-000000000000', 'receipt-traveler@example.test', 'encrypted', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), 'authenticated', 'authenticated'),
    (v_outsider, '00000000-0000-0000-0000-000000000000', 'receipt-outsider@example.test', 'encrypted', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), 'authenticated', 'authenticated')
  on conflict (id) do nothing;
  insert into public.profiles (id, full_name, role) values
    (v_host, 'Receipt Host', 'traveler'),
    (v_traveler, 'Receipt Traveler', 'traveler'),
    (v_outsider, 'Receipt Outsider', 'traveler')
  on conflict (id) do nothing;
  insert into public.categories (id, slug, name_en, name_ne)
  values (v_category, 'receipt-test-category', 'Receipt Test', 'Receipt Test')
  on conflict (id) do nothing;
  insert into public.regions (id, slug, name_en, name_ne)
  values (v_region, 'receipt-test-region', 'Receipt Test', 'Receipt Test')
  on conflict (id) do nothing;
  insert into public.experiences (
    id, host_id, category_id, region_id, title, slug,
    cover_image_url, price_paisa, status
  ) values (
    v_experience, v_host, v_category, v_region, 'Receipt Test Experience',
    'receipt-test-experience', 'https://example.test/image.jpg', 10000, 'published'
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
    v_booking, 'RECEIPT-1', v_traveler, v_experience, v_departure, 1,
    'Receipt Traveler', '9800000000', 10000, 10000, 'pending'
  ) on conflict (id) do nothing;
end $$;

do $$
begin
  set local role authenticated;
  perform set_config('request.jwt.claims', '{"sub":"96100000-0000-4000-8000-000000000001","role":"authenticated"}', true);
  perform public.send_trip_message(
    '96100000-0000-4000-8000-000000000008',
    '96100000-0000-4000-8000-000000000009',
    'Receipt fixture'
  );
end $$;

reset role;
select set_config('request.jwt.claims', '{}', true);

do $$
begin
  if (select count(*) from public.trip_message_receipts
      where message_id = '96100000-0000-4000-8000-000000000009') <> 1 then
    raise exception 'FAIL: message insert did not create one recipient receipt';
  end if;
end $$;

do $$
declare
  v_count integer;
begin
  set local role authenticated;
  perform set_config('request.jwt.claims', '{"sub":"96100000-0000-4000-8000-000000000002","role":"authenticated"}', true);
  perform public.mark_trip_conversation_read(
    '96100000-0000-4000-8000-000000000008'
  );
  perform public.mark_trip_conversation_read(
    '96100000-0000-4000-8000-000000000008'
  );
  select count(*) into v_count
  from public.trip_message_receipts
  where message_id = '96100000-0000-4000-8000-000000000009'
    and recipient_id = auth.uid()
    and seen_at is not null;
  if v_count <> 1 then
    raise exception 'FAIL: recipient did not mark exactly one receipt seen';
  end if;
end $$;

do $$
declare
  v_count integer;
  v_marked boolean := false;
begin
  set local role authenticated;
  perform set_config('request.jwt.claims', '{"sub":"96100000-0000-4000-8000-000000000003","role":"authenticated"}', true);
  select count(*) into v_count from public.trip_message_receipts;
  begin
    perform public.mark_trip_conversation_read(
      '96100000-0000-4000-8000-000000000008'
    );
    v_marked := true;
  exception when others then
    v_marked := false;
  end;
  if v_count <> 0 or v_marked then
    raise exception 'FAIL: outsider accessed or changed receipt state';
  end if;
end $$;

do $$
declare
  v_count integer;
begin
  set local role authenticated;
  perform set_config('request.jwt.claims', '{"sub":"96100000-0000-4000-8000-000000000001","role":"authenticated"}', true);
  select count(*) into v_count
  from public.trip_message_receipts
  where message_id = '96100000-0000-4000-8000-000000000009'
    and seen_at is not null;
  if v_count <> 1 then
    raise exception 'FAIL: sender could not read aggregate receipt status';
  end if;
end $$;

rollback;
