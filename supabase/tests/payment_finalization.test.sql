begin;

do $$
declare
  v_user uuid := 'fa000000-0000-4000-8000-000000000001';
  v_category uuid := 'fa000000-0000-4000-8000-000000000002';
  v_region uuid := 'fa000000-0000-4000-8000-000000000003';
  v_experience uuid := 'fa000000-0000-4000-8000-000000000004';
  v_departure uuid := 'fa000000-0000-4000-8000-000000000005';
  v_booking uuid := 'fa000000-0000-4000-8000-000000000006';
  v_payment uuid := 'fa000000-0000-4000-8000-000000000007';
  v_first_already_processed boolean;
  v_second_already_processed boolean;
  v_spots integer;
  v_participants integer;
  v_gear integer;
begin
  insert into auth.users (
    id, instance_id, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role, aud
  ) values (
    v_user,
    '00000000-0000-0000-0000-000000000000',
    'payment-finalization@example.test',
    'encrypted',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{}',
    now(),
    now(),
    'authenticated',
    'authenticated'
  ) on conflict (id) do nothing;

  insert into public.profiles (id, full_name, role)
  values (v_user, 'Payment Test User', 'traveler')
  on conflict (id) do nothing;

  insert into public.categories (id, slug, name_en, name_ne)
  values (v_category, 'payment-test', 'Payment Test', 'Payment Test')
  on conflict (id) do nothing;

  insert into public.regions (id, slug, name_en, name_ne)
  values (v_region, 'payment-test', 'Payment Test', 'Payment Test')
  on conflict (id) do nothing;

  insert into public.experiences (
    id, category_id, region_id, title, slug, cover_image_url,
    price_paisa, bring_list, status
  ) values (
    v_experience, v_category, v_region, 'Payment Test Experience',
    'payment-test-experience', 'https://example.test/image.jpg',
    500000, array['Test item one', 'Test item two'], 'published'
  ) on conflict (id) do nothing;

  insert into public.experience_departures (
    id, experience_id, start_date, end_date, total_spots, spots_left, status
  ) values (
    v_departure, v_experience, current_date + 10, current_date + 11, 10, 10, 'open'
  ) on conflict (id) do nothing;

  insert into public.bookings (
    id, booking_ref, user_id, experience_id, departure_id, adults, children,
    contact_name, contact_phone, subtotal_paisa, total_paisa, status, quote_expires_at
  ) values (
    v_booking, 'FINALIZE-TEST', v_user, v_experience, v_departure, 2, 0,
    'Payment Test User', '9800000000', 500000, 500000, 'pending', now() + interval '15 minutes'
  ) on conflict (id) do nothing;

  insert into public.payments (
    id, booking_id, provider, idempotency_key, amount_paisa, status
  ) values (
    v_payment, v_booking, 'khalti', 'finalize-test-idempotency', 500000, 'initiated'
  ) on conflict (id) do nothing;

  begin
    update public.bookings set total_paisa = subtotal_paisa + 1 where id = v_booking;
    raise exception 'FAIL: inconsistent booking total was accepted';
  exception
    when check_violation then null;
  end;

  begin
    update public.experiences set price_paisa = 10000000001 where id = v_experience;
    raise exception 'FAIL: oversized experience price was accepted';
  exception
    when check_violation then null;
  end;

  begin
    update public.payments set amount_paisa = 210000000001 where id = v_payment;
    raise exception 'FAIL: oversized payment amount was accepted';
  exception
    when check_violation then null;
  end;

  update public.payments set amount_paisa = 1 where id = v_payment;
  begin
    perform public.finalize_verified_payment(
      v_booking,
      v_payment,
      'khalti',
      'finalize-test-provider-ref',
      '{"status":"Completed"}'
    );
    raise exception 'FAIL: mismatched payment amount was finalized';
  exception
    when others then
      if sqlerrm = 'FAIL: mismatched payment amount was finalized' then
        raise;
      end if;
  end;
  update public.payments set amount_paisa = 500000 where id = v_payment;

  select already_processed into v_first_already_processed
  from public.finalize_verified_payment(
    v_booking, v_payment, 'khalti', 'finalize-test-provider-ref', '{"status":"Completed"}'
  );

  select already_processed into v_second_already_processed
  from public.finalize_verified_payment(
    v_booking, v_payment, 'khalti', 'finalize-test-provider-ref', '{"status":"Completed"}'
  );

  select spots_left into v_spots
  from public.experience_departures where id = v_departure;
  select count(*) into v_participants
  from public.booking_participants where booking_id = v_booking;
  select count(*) into v_gear
  from public.gear_checklist_items where booking_id = v_booking;

  if v_first_already_processed or not v_second_already_processed then
    raise exception 'FAIL: payment finalization was not idempotent';
  end if;
  if v_spots <> 8 then
    raise exception 'FAIL: departure capacity changed more or less than once';
  end if;
  if v_participants <> 1 or v_gear <> 2 then
    raise exception 'FAIL: dependent booking records were duplicated or missing';
  end if;
  if not exists (
    select 1 from public.payments
    where id = v_payment and status = 'paid' and provider_ref = 'finalize-test-provider-ref'
  ) or not exists (
    select 1 from public.bookings where id = v_booking and status = 'confirmed'
  ) then
    raise exception 'FAIL: payment and booking were not finalized together';
  end if;
end $$;

rollback;
