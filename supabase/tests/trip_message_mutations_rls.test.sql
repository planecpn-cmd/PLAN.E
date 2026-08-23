-- Focused Phase 6C edit/soft-delete audit and privacy assertions.

begin;

do $$
declare
  h uuid := '96200000-0000-4000-8000-000000000001';
  t uuid := '96200000-0000-4000-8000-000000000002';
  o uuid := '96200000-0000-4000-8000-000000000003';
  c uuid := '96200000-0000-4000-8000-000000000004';
  r uuid := '96200000-0000-4000-8000-000000000005';
  e uuid := '96200000-0000-4000-8000-000000000006';
  d uuid := '96200000-0000-4000-8000-000000000007';
  b uuid := '96200000-0000-4000-8000-000000000008';
begin
  insert into auth.users (
    id, instance_id, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role, aud
  ) values
    (h, '00000000-0000-0000-0000-000000000000', 'mutation-host@example.test', 'encrypted', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), 'authenticated', 'authenticated'),
    (t, '00000000-0000-0000-0000-000000000000', 'mutation-traveler@example.test', 'encrypted', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), 'authenticated', 'authenticated'),
    (o, '00000000-0000-0000-0000-000000000000', 'mutation-outsider@example.test', 'encrypted', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), 'authenticated', 'authenticated')
  on conflict (id) do nothing;
  insert into public.profiles (id, full_name, role) values
    (h, 'Mutation Host', 'traveler'), (t, 'Mutation Traveler', 'traveler'),
    (o, 'Mutation Outsider', 'traveler') on conflict (id) do nothing;
  insert into public.categories (id, slug, name_en, name_ne)
  values (c, 'mutation-test-category', 'Mutation Test', 'Mutation Test')
  on conflict (id) do nothing;
  insert into public.regions (id, slug, name_en, name_ne)
  values (r, 'mutation-test-region', 'Mutation Test', 'Mutation Test')
  on conflict (id) do nothing;
  insert into public.experiences (
    id, host_id, category_id, region_id, title, slug,
    cover_image_url, price_paisa, status
  ) values (
    e, h, c, r, 'Mutation Test Experience', 'mutation-test-experience',
    'https://example.test/image.jpg', 10000, 'published'
  ) on conflict (id) do nothing;
  insert into public.experience_departures (
    id, experience_id, start_date, end_date, total_spots, spots_left
  ) values (d, e, current_date + 1, current_date + 2, 2, 1)
  on conflict (id) do nothing;
  insert into public.bookings (
    id, booking_ref, user_id, experience_id, departure_id, adults,
    contact_name, contact_phone, subtotal_paisa, total_paisa, status
  ) values (
    b, 'MUTATION-1', t, e, d, 1, 'Mutation Traveler', '9800000000',
    10000, 10000, 'pending'
  ) on conflict (id) do nothing;
end $$;

do $$
declare
  v_audit_readable boolean := false;
begin
  set local role authenticated;
  perform set_config('request.jwt.claims', '{"sub":"96200000-0000-4000-8000-000000000001","role":"authenticated"}', true);
  perform public.send_trip_message(
    '96200000-0000-4000-8000-000000000008',
    '96200000-0000-4000-8000-000000000009',
    'Original immutable body'
  );
  perform public.edit_trip_message(
    '96200000-0000-4000-8000-000000000009',
    'Edited participant view'
  );
  begin
    perform count(*) from public.trip_message_edits;
    v_audit_readable := true;
  exception when insufficient_privilege then
    v_audit_readable := false;
  end;
  if v_audit_readable then
    raise exception 'FAIL: sender could read private edit audit history';
  end if;
end $$;

do $$
declare
  v_count integer;
  v_edited boolean := false;
begin
  set local role authenticated;
  perform set_config('request.jwt.claims', '{"sub":"96200000-0000-4000-8000-000000000002","role":"authenticated"}', true);
  select count(*) into v_count
  from public.trip_message_mutations
  where message_id = '96200000-0000-4000-8000-000000000009'
    and effective_body = 'Edited participant view';
  begin
    perform public.edit_trip_message(
      '96200000-0000-4000-8000-000000000009', 'Unauthorized edit'
    );
    v_edited := true;
  exception when others then
    v_edited := false;
  end;
  if v_count <> 1 or v_edited then
    raise exception 'FAIL: participant projection or sender-only edit failed';
  end if;
end $$;

do $$
declare
  v_count integer;
begin
  set local role authenticated;
  perform set_config('request.jwt.claims', '{"sub":"96200000-0000-4000-8000-000000000003","role":"authenticated"}', true);
  select count(*) into v_count from public.trip_message_mutations;
  if v_count <> 0 then
    raise exception 'FAIL: outsider read message mutation projection';
  end if;
end $$;

do $$
declare
  v_edit_after_delete boolean := false;
begin
  set local role authenticated;
  perform set_config('request.jwt.claims', '{"sub":"96200000-0000-4000-8000-000000000001","role":"authenticated"}', true);
  perform public.delete_trip_message('96200000-0000-4000-8000-000000000009');
  perform public.delete_trip_message('96200000-0000-4000-8000-000000000009');
  begin
    perform public.edit_trip_message(
      '96200000-0000-4000-8000-000000000009', 'Should fail'
    );
    v_edit_after_delete := true;
  exception when others then
    v_edit_after_delete := false;
  end;
  if v_edit_after_delete then
    raise exception 'FAIL: deleted message was editable';
  end if;
end $$;

reset role;
select set_config('request.jwt.claims', '{}', true);

do $$
begin
  if (select body from public.trip_messages
      where id = '96200000-0000-4000-8000-000000000009') <> 'Original immutable body'
    or (select count(*) from public.trip_message_edits
        where message_id = '96200000-0000-4000-8000-000000000009') <> 1
    or (select count(*) from public.trip_message_deletions
        where message_id = '96200000-0000-4000-8000-000000000009') <> 1
    or not exists (
      select 1 from public.trip_message_mutations
      where message_id = '96200000-0000-4000-8000-000000000009'
        and effective_body is null and deleted_at is not null
    ) then
    raise exception 'FAIL: soft-delete audit integrity failed';
  end if;
end $$;

rollback;
