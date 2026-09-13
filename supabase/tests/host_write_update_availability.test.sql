-- H1 core (2/4): public.host_update_experience_availability(uuid, date, date, int)
--
-- Targets the earliest open departure (creates one if none). Asserts:
--   owner can widen capacity + move dates on an unbooked departure;
--   capacity cannot drop below the booked count;
--   dates cannot move while the departure has active bookings;
--   a departure is created when the experience has none;
--   non-owner / suspended / bad range / bad capacity are refused.

begin;

do $$
declare
  v_owner  uuid := 'c2000000-0000-4000-8000-000000000001';
  v_other  uuid := 'c2000000-0000-4000-8000-000000000002';
  v_susp   uuid := 'c2000000-0000-4000-8000-000000000003';
  v_buyer  uuid := '11111111-1111-4111-8111-000000000001';  -- seed traveler
  v_cat    uuid;
  v_region uuid;
  v_exp_free uuid := 'c2e00000-0000-4000-8000-000000000001';  -- open departure, no bookings
  v_exp_bkd  uuid := 'c2e00000-0000-4000-8000-000000000002';  -- open departure, 2 booked
  v_exp_none uuid := 'c2e00000-0000-4000-8000-000000000003';  -- no departure at all
  v_dep_free uuid := 'c2d00000-0000-4000-8000-000000000001';
  v_dep_bkd  uuid := 'c2d00000-0000-4000-8000-000000000002';
  v_ret    uuid;
  v_raised boolean;
  v_start  date;
  v_end    date;
  v_total  int;
  v_left   int;
begin
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  select id into v_cat    from public.categories order by created_at limit 1;
  select id into v_region from public.regions    order by created_at limit 1;

  insert into auth.users (id, instance_id, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role, aud)
  select u, '00000000-0000-0000-0000-000000000000', u::text || '@hw2.test', 'x', now(),
    '{"provider":"email","providers":["email"]}', '{}', now(), now(), 'authenticated', 'authenticated'
  from unnest(array[v_owner, v_other, v_susp]) u
  on conflict (id) do nothing;

  insert into public.profiles (id, full_name, role)
  values (v_owner, 'HW2 Owner', 'traveler'), (v_other, 'HW2 Other', 'traveler'),
         (v_susp, 'HW2 Susp', 'traveler')
  on conflict (id) do update set role = excluded.role;

  insert into public.host_applications (id, user_id, status, current_step, application_data)
  values
    (gen_random_uuid(), v_owner, 'approved', 8, '{}'::jsonb),
    (gen_random_uuid(), v_other, 'approved', 8, '{}'::jsonb),
    (gen_random_uuid(), v_susp,  'approved', 8, '{}'::jsonb)
  on conflict (user_id) do nothing;
  update public.host_accounts set is_active = false, suspended_at = now()
  where user_id = v_susp;

  insert into public.experiences
    (id, host_id, category_id, region_id, title, slug, cover_image_url, price_paisa, status)
  values
    (v_exp_free, v_owner, v_cat, v_region, 'HW2 Free', 'hw2-free', null, 500000, 'draft'),
    (v_exp_bkd,  v_owner, v_cat, v_region, 'HW2 Bkd',  'hw2-bkd',  'https://e.test/c.webp', 500000, 'published'),
    (v_exp_none, v_owner, v_cat, v_region, 'HW2 None', 'hw2-none', null, 500000, 'draft');

  insert into public.experience_departures
    (id, experience_id, start_date, end_date, total_spots, spots_left, status)
  values
    (v_dep_free, v_exp_free, date '2026-10-01', date '2026-10-05', 8, 8, 'open'),
    (v_dep_bkd,  v_exp_bkd,  date '2026-11-01', date '2026-11-05', 8, 6, 'open');

  insert into public.bookings
    (booking_ref, user_id, experience_id, departure_id, adults, children,
     contact_name, contact_phone, subtotal_paisa, addons_paisa, fees_paisa,
     total_paisa, status)
  values
    ('HW2-BK-0001', v_buyer, v_exp_bkd, v_dep_bkd, 2, 0,
     'Buyer', '98000000', 1000000, 0, 50000, 1050000, 'confirmed');

  ----------------------------------------------------------------------------
  -- 1. owner widens capacity + moves dates on an unbooked departure
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_owner, 'role', 'authenticated')::text, true);
  v_ret := public.host_update_experience_availability(
    v_exp_free, date '2026-10-03', date '2026-10-08', 10);
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);

  select start_date, end_date, total_spots, spots_left
    into v_start, v_end, v_total, v_left
  from public.experience_departures where id = v_dep_free;
  if v_ret is distinct from v_dep_free
     or v_start <> date '2026-10-03' or v_end <> date '2026-10-08'
     or v_total <> 10 or v_left <> 10 then
    raise exception 'FAIL: owner update of an unbooked departure did not apply (% % % %)',
      v_start, v_end, v_total, v_left;
  end if;

  -- 2. capacity cannot drop below the booked count (2 booked on v_dep_bkd)
  v_raised := false;
  begin
    perform set_config('request.jwt.claims',
      json_build_object('sub', v_owner, 'role', 'authenticated')::text, true);
    perform public.host_update_experience_availability(
      v_exp_bkd, date '2026-11-01', date '2026-11-05', 1);
  exception when others then v_raised := true;
  end;
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  if not v_raised then
    raise exception 'FAIL: capacity was allowed below the booked count';
  end if;

  -- 3. dates cannot move while the departure has an active booking
  v_raised := false;
  begin
    perform set_config('request.jwt.claims',
      json_build_object('sub', v_owner, 'role', 'authenticated')::text, true);
    perform public.host_update_experience_availability(
      v_exp_bkd, date '2026-12-01', date '2026-12-05', 8);
  exception when others then v_raised := true;
  end;
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  if not v_raised then
    raise exception 'FAIL: departure dates moved with an active booking present';
  end if;

  -- 3b. same-dates capacity bump on a booked departure IS allowed
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_owner, 'role', 'authenticated')::text, true);
  perform public.host_update_experience_availability(
    v_exp_bkd, date '2026-11-01', date '2026-11-05', 12);
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  select total_spots, spots_left into v_total, v_left
  from public.experience_departures where id = v_dep_bkd;
  if v_total <> 12 or v_left <> 10 then  -- 12 - 2 booked
    raise exception 'FAIL: capacity bump on a booked departure wrong (% left %)',
      v_total, v_left;
  end if;

  -- 4. an experience with no departure gets one created
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_owner, 'role', 'authenticated')::text, true);
  v_ret := public.host_update_experience_availability(
    v_exp_none, date '2027-01-10', date '2027-01-14', 6);
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  if not exists (
    select 1 from public.experience_departures
    where id = v_ret and experience_id = v_exp_none
      and start_date = date '2027-01-10' and total_spots = 6 and spots_left = 6
  ) then
    raise exception 'FAIL: no departure was created for an experience that had none';
  end if;

  -- 5. non-owner approved host refused
  v_raised := false;
  begin
    perform set_config('request.jwt.claims',
      json_build_object('sub', v_other, 'role', 'authenticated')::text, true);
    perform public.host_update_experience_availability(
      v_exp_free, date '2026-10-03', date '2026-10-08', 9);
  exception when others then v_raised := true;
  end;
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  if not v_raised then
    raise exception 'FAIL: a non-owner host edited another host''s availability';
  end if;

  -- 6. suspended host refused
  v_raised := false;
  begin
    perform set_config('request.jwt.claims',
      json_build_object('sub', v_susp, 'role', 'authenticated')::text, true);
    perform public.host_update_experience_availability(
      v_exp_free, date '2026-10-03', date '2026-10-08', 9);
  exception when others then v_raised := true;
  end;
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  if not v_raised then
    raise exception 'FAIL: a suspended host edited availability';
  end if;

  -- 7. bad range / bad capacity refused
  v_raised := false;
  begin
    perform set_config('request.jwt.claims',
      json_build_object('sub', v_owner, 'role', 'authenticated')::text, true);
    perform public.host_update_experience_availability(
      v_exp_free, date '2026-10-10', date '2026-10-01', 8);
  exception when others then v_raised := true;
  end;
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  if not v_raised then raise exception 'FAIL: end < start accepted'; end if;

  v_raised := false;
  begin
    perform set_config('request.jwt.claims',
      json_build_object('sub', v_owner, 'role', 'authenticated')::text, true);
    perform public.host_update_experience_availability(
      v_exp_free, date '2026-10-01', date '2026-10-05', 0);
  exception when others then v_raised := true;
  end;
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  if not v_raised then raise exception 'FAIL: capacity 0 accepted'; end if;

  raise notice 'OK: host_update_experience_availability enforces ownership + booking conflicts';
end $$;

rollback;
