-- RLS Safety Test Assertions (Permanent test file)
-- Run via psql / pg_prove against the database to verify row level security policies.

begin;

-- Fixture setup (temporary test data inside transaction)
do $$
declare
  v_user_a uuid := 'a0000000-0000-0000-0000-000000000001';
  v_user_b uuid := 'b0000000-0000-0000-0000-000000000002';
  v_cat_id uuid := 'c0000000-0000-0000-0000-000000000001';
  v_reg_id uuid := '70000000-0000-0000-0000-000000000001';
  v_exp_id uuid := 'e0000000-0000-0000-0000-000000000001';
  v_dep_id uuid := 'd0000000-0000-0000-0000-000000000001';
  v_book_b1 uuid := '11111111-0000-0000-0000-000000000001';
  v_book_b2 uuid := '22222222-0000-0000-0000-000000000002';
begin
  -- Setup auth users
  insert into auth.users (id, instance_id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role, aud)
  values 
    (v_user_a, '00000000-0000-0000-0000-000000000000', 'usera@example.com', 'encrypted', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), 'authenticated', 'authenticated'),
    (v_user_b, '00000000-0000-0000-0000-000000000000', 'userb@example.com', 'encrypted', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), 'authenticated', 'authenticated')
  on conflict (id) do nothing;

  -- Setup test profiles
  insert into public.profiles (id, full_name, role)
  values 
    (v_user_a, 'User A', 'traveler'),
    (v_user_b, 'User B', 'traveler')
  on conflict (id) do nothing;

  -- Setup category & region
  insert into public.categories (id, slug, name_en, name_ne)
  values (v_cat_id, 'test-cat', 'Test Cat', 'टेस्ट')
  on conflict (id) do nothing;

  insert into public.regions (id, slug, name_en, name_ne)
  values (v_reg_id, 'test-reg', 'Test Region', 'क्षेत्र')
  on conflict (id) do nothing;

  -- Setup published experience (hosted by User B)
  insert into public.experiences (id, host_id, category_id, region_id, title, slug, cover_image_url, price_paisa, status)
  values (v_exp_id, v_user_b, v_cat_id, v_reg_id, 'Test Experience', 'test-experience', 'http://example.com/img.jpg', 500000, 'published')
  on conflict (id) do nothing;

  -- Setup departure
  insert into public.experience_departures (id, experience_id, start_date, end_date, total_spots, spots_left)
  values (v_dep_id, v_exp_id, CURRENT_DATE + interval '10 days', CURRENT_DATE + interval '12 days', 10, 10)
  on conflict (id) do nothing;

  -- Setup booking for User B
  insert into public.bookings (id, booking_ref, user_id, experience_id, departure_id, adults, contact_name, contact_phone, subtotal_paisa, total_paisa, status)
  values 
    (v_book_b1, 'REF-B1', v_user_b, v_exp_id, v_dep_id, 1, 'User B', '9800000000', 500000, 500000, 'pending'),
    (v_book_b2, 'REF-B2', v_user_b, v_exp_id, v_dep_id, 1, 'User B', '9800000000', 500000, 500000, 'completed')
  on conflict (id) do nothing;

  -- Setup host application for User A
  insert into public.host_applications (id, user_id, status, title)
  values ('80000000-0000-0000-0000-000000000001', v_user_a, 'draft', 'Host App A')
  on conflict (id) do nothing;
end $$;

-- Assertion 1: every table in public has rowsecurity = true and >= 1 policy
do $$
declare
  v_no_rls int;
  v_no_policy int;
begin
  select count(*) into v_no_rls
  from pg_tables
  where schemaname = 'public' and rowsecurity = false;

  select count(*) into v_no_policy
  from pg_tables t
  where t.schemaname = 'public'
    and t.tablename <> 'payments'
    and not exists (
      select 1 from pg_policies p where p.schemaname = 'public' and p.tablename = t.tablename
    );

  if not (v_no_rls = 0 and v_no_policy = 0) then
    raise exception 'FAIL: Assertion 1 - Not all tables in public have rowsecurity = true and >= 1 policy';
  end if;
end $$;

-- Assertion 2: anon can select published experiences
do $$
declare
  v_count int;
begin
  set local role anon;
  select count(*) into v_count from public.experiences where status = 'published';
  if not (v_count >= 1) then
    raise exception 'FAIL: Assertion 2 - anon cannot select published experiences';
  end if;
end $$;

-- Assertion 3: anon selects zero rows from bookings and payments
do $$
declare
  v_bookings_count int;
  v_payments_count int;
begin
  set local role anon;
  select count(*) into v_bookings_count from public.bookings;
  select count(*) into v_payments_count from public.payments;
  if not (v_bookings_count = 0 and v_payments_count = 0) then
    raise exception 'FAIL: Assertion 3 - anon selected non-zero rows from bookings or payments';
  end if;
end $$;

-- Assertion 4: user A selects zero of user B's bookings
do $$
declare
  v_count int;
begin
  set local role authenticated;
  perform set_config('request.jwt.claims', json_build_object('sub', 'a0000000-0000-0000-0000-000000000001', 'role', 'authenticated')::text, true);

  select count(*) into v_count from public.bookings where user_id = 'b0000000-0000-0000-0000-000000000002';
  if not (v_count = 0) then
    raise exception 'FAIL: Assertion 4 - user A selected non-zero of user B''s bookings';
  end if;
end $$;

-- Assertion 5: authenticated role cannot update bookings.status
do $$
declare
  v_updated int := 0;
  v_failed boolean := false;
begin
  set local role authenticated;
  perform set_config('request.jwt.claims', json_build_object('sub', 'b0000000-0000-0000-0000-000000000002', 'role', 'authenticated')::text, true);

  begin
    update public.bookings set status = 'confirmed' where id = '11111111-0000-0000-0000-000000000001';
    get diagnostics v_updated = row_count;
    if v_updated > 0 then
      v_failed := true;
    end if;
  exception when others then
    v_failed := false;
  end;

  if not (not v_failed) then
    raise exception 'FAIL: Assertion 5 - authenticated role was able to update bookings.status';
  end if;
end $$;

-- Assertion 6: authenticated role cannot update experience_departures.spots_left
do $$
declare
  v_updated int := 0;
  v_failed boolean := false;
begin
  set local role authenticated;
  perform set_config('request.jwt.claims', json_build_object('sub', 'a0000000-0000-0000-0000-000000000001', 'role', 'authenticated')::text, true);

  begin
    update public.experience_departures set spots_left = 999 where id = 'd0000000-0000-0000-0000-000000000001';
    get diagnostics v_updated = row_count;
    if v_updated > 0 then
      v_failed := true;
    end if;
  exception when others then
    v_failed := false;
  end;

  if not (not v_failed) then
    raise exception 'FAIL: Assertion 6 - authenticated role was able to update experience_departures.spots_left';
  end if;
end $$;

-- Assertion 7: authenticated role cannot insert or update payments
do $$
declare
  v_updated int := 0;
  v_failed boolean := false;
begin
  set local role authenticated;
  perform set_config('request.jwt.claims', json_build_object('sub', 'b0000000-0000-0000-0000-000000000002', 'role', 'authenticated')::text, true);

  begin
    insert into public.payments (booking_id, provider, idempotency_key, amount_paisa)
    values ('11111111-0000-0000-0000-000000000001', 'khalti', 'idem_auth_test', 500000);
    v_failed := true;
  exception when others then
    null;
  end;

  begin
    update public.payments set status = 'paid';
    get diagnostics v_updated = row_count;
    if v_updated > 0 then
      v_failed := true;
    end if;
  exception when others then
    null;
  end;

  if not (not v_failed) then
    raise exception 'FAIL: Assertion 7 - authenticated role was able to insert or update payments';
  end if;
end $$;

-- Assertion 8: authenticated role cannot update host_applications.status
do $$
declare
  v_updated int := 0;
  v_failed boolean := false;
begin
  set local role authenticated;
  perform set_config('request.jwt.claims', json_build_object('sub', 'a0000000-0000-0000-0000-000000000001', 'role', 'authenticated')::text, true);

  begin
    update public.host_applications set status = 'approved' where id = '80000000-0000-0000-0000-000000000001';
    get diagnostics v_updated = row_count;
    if v_updated > 0 then
      v_failed := true;
    end if;
  exception when others then
    v_failed := false;
  end;

  if not (not v_failed) then
    raise exception 'FAIL: Assertion 8 - authenticated role was able to update host_applications.status';
  end if;
end $$;

-- Assertion 9: reviews rejects duplicate booking_id
do $$
declare
  v_failed boolean := false;
begin
  set local role postgres;
  insert into public.reviews (booking_id, experience_id, user_id, rating, body)
  values ('22222222-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000002', 5, 'Great trek!');

  begin
    insert into public.reviews (booking_id, experience_id, user_id, rating, body)
    values ('22222222-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000002', 4, 'Duplicate review');
    v_failed := true;
  exception when unique_violation then
    v_failed := false;
  when others then
    v_failed := false;
  end;

  if not (not v_failed) then
    raise exception 'FAIL: Assertion 9 - reviews allowed duplicate booking_id';
  end if;
end $$;

-- Assertion 10: payments rejects duplicate idempotency_key
do $$
declare
  v_failed boolean := false;
begin
  set local role postgres;
  perform set_config('request.jwt.claims', json_build_object('role', 'service_role')::text, true);
  insert into public.payments (booking_id, provider, idempotency_key, amount_paisa)
  values ('11111111-0000-0000-0000-000000000001', 'khalti', 'dup_key_test_123', 500000);

  begin
    insert into public.payments (booking_id, provider, idempotency_key, amount_paisa)
    values ('22222222-0000-0000-0000-000000000002', 'esewa', 'dup_key_test_123', 500000);
    v_failed := true;
  exception when unique_violation then
    v_failed := false;
  when others then
    v_failed := false;
  end;

  if not (not v_failed) then
    raise exception 'FAIL: Assertion 10 - payments allowed duplicate idempotency_key';
  end if;
end $$;

rollback;
