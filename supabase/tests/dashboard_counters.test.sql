-- N6 dashboard shell: each counter query, against known self-contained
-- fixtures, asserting exact deltas -- not absolute totals, since seed.sql /
-- seed_test.sql already populate the tables with incidental state this file
-- doesn't control. Mirrors admin/src/app/api/dashboard/*/route.ts's queries
-- exactly; "today" uses the same Asia/Kathmandu calendar-day boundary as
-- lib/kathmandu-today.ts, expressed directly in SQL here.

begin;

do $$
declare
  v_user_today1 uuid := gen_random_uuid();
  v_user_today2 uuid := gen_random_uuid();
  v_user_old    uuid := gen_random_uuid();
  v_host_active_user uuid := gen_random_uuid();
  v_host_inactive_user uuid := gen_random_uuid();
  v_cat uuid; v_region uuid;
  v_app_active uuid; v_app_inactive uuid;
  v_exp_pub uuid; v_exp_pending uuid; v_exp_draft uuid;
  v_dep_future uuid; v_dep_past uuid;
  v_before_new_users bigint; v_after_new_users bigint;
  v_before_total_users bigint; v_after_total_users bigint;
  v_before_active_users bigint; v_after_active_users bigint;
  v_before_new_hosts bigint; v_after_new_hosts bigint;
  v_before_total_hosts bigint; v_after_total_hosts bigint;
  v_before_active_hosts bigint; v_after_active_hosts bigint;
  v_before_awaiting_hosts bigint; v_after_awaiting_hosts bigint;
  v_before_total_exp bigint; v_after_total_exp bigint;
  v_before_pub_exp bigint; v_after_pub_exp bigint;
  v_before_awaiting_exp bigint; v_after_awaiting_exp bigint;
  v_before_bookings_today bigint; v_after_bookings_today bigint;
  v_before_cancel_today bigint; v_after_cancel_today bigint;
  v_before_total_bookings bigint; v_after_total_bookings bigint;
  v_before_upcoming bigint; v_after_upcoming bigint;
  v_before_gross bigint; v_after_gross bigint;
begin
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  select id into v_cat from public.categories order by created_at limit 1;
  select id into v_region from public.regions order by created_at limit 1;

  -- ── baseline, before any fixture ──────────────────────────────────────
  select count(*) into v_before_new_users from public.profiles
    where (created_at at time zone 'Asia/Kathmandu')::date = (now() at time zone 'Asia/Kathmandu')::date;
  select count(*) into v_before_total_users from public.profiles;
  select count(distinct user_id) into v_before_active_users from public.bookings where created_at >= now() - interval '30 days';
  select count(*) into v_before_new_hosts from public.host_accounts
    where (created_at at time zone 'Asia/Kathmandu')::date = (now() at time zone 'Asia/Kathmandu')::date;
  select count(*) into v_before_total_hosts from public.host_accounts;
  select count(*) into v_before_active_hosts from public.host_accounts where is_active = true;
  select count(*) into v_before_awaiting_hosts from public.host_applications where status in ('submitted','under_review');
  select count(*) into v_before_total_exp from public.experiences;
  select count(*) into v_before_pub_exp from public.experiences where status = 'published';
  select count(*) into v_before_awaiting_exp from public.experiences where status = 'pending_review';
  select count(*) into v_before_bookings_today from public.bookings
    where (created_at at time zone 'Asia/Kathmandu')::date = (now() at time zone 'Asia/Kathmandu')::date;
  select count(*) into v_before_cancel_today from public.bookings
    where status = 'cancelled' and (cancelled_at at time zone 'Asia/Kathmandu')::date = (now() at time zone 'Asia/Kathmandu')::date;
  select count(*) into v_before_total_bookings from public.bookings;
  select count(*) into v_before_upcoming from public.bookings b
    join public.experience_departures d on d.id = b.departure_id
    where d.start_date >= (now() at time zone 'Asia/Kathmandu')::date and b.status in ('pending','confirmed');
  select coalesce(sum(total_paisa), 0) into v_before_gross from public.bookings where status in ('confirmed','completed');

  -- ── fixtures ─────────────────────────────────────────────────────────
  insert into auth.users (id, instance_id, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role, aud)
  select u, '00000000-0000-0000-0000-000000000000', u::text || '@dashcount.test', 'x', now(),
    '{"provider":"email","providers":["email"]}', '{}', now(), now(), 'authenticated', 'authenticated'
  from unnest(array[v_user_today1, v_user_today2, v_user_old, v_host_active_user, v_host_inactive_user]) u
  on conflict (id) do nothing;

  -- handle_new_user() (0003) already auto-created a profiles row (created_at
  -- = now()) as a side effect of the auth.users insert above -- the upsert
  -- must overwrite created_at explicitly, not just role, or every row keeps
  -- the trigger's "today" timestamp regardless of what's inserted here.
  insert into public.profiles (id, full_name, role, created_at)
  values
    (v_user_today1, 'Dash Today 1', 'traveler', now()),
    (v_user_today2, 'Dash Today 2', 'traveler', now()),
    (v_user_old, 'Dash Old', 'traveler', now() - interval '10 days'),
    (v_host_active_user, 'Dash Host Active', 'traveler', now() - interval '10 days'),
    (v_host_inactive_user, 'Dash Host Inactive', 'traveler', now() - interval '10 days')
  on conflict (id) do update set role = excluded.role, created_at = excluded.created_at;

  -- host applications: 2 approved -- private.sync_host_account_from_application
  -- (20260813090000) fires on insert with status='approved' and creates the
  -- host_accounts row itself; inserting one manually here would collide with
  -- it. 2 more genuinely awaiting review.
  insert into public.host_applications (id, user_id, status, current_step, category_id, title)
  values
    (gen_random_uuid(), v_host_active_user, 'approved', 4, v_cat, 'Approved App A') returning id into v_app_active;
  insert into public.host_applications (id, user_id, status, current_step, category_id, title)
  values
    (gen_random_uuid(), v_host_inactive_user, 'approved', 4, v_cat, 'Approved App B') returning id into v_app_inactive;
  insert into public.host_applications (user_id, status, current_step, category_id, title)
  values
    (v_user_today1, 'submitted', 4, v_cat, 'Awaiting A'),
    (v_user_today2, 'under_review', 4, v_cat, 'Awaiting B');

  -- v_host_active_user's row: trigger already set is_active=true, created_at
  -- defaults to now() -- exactly what "new active host today" needs, nothing
  -- more to do. v_host_inactive_user's row: back-date it and flip inactive.
  update public.host_accounts
     set is_active = false, created_at = now() - interval '10 days'
   where user_id = v_host_inactive_user;

  -- experiences: published, pending_review, draft
  insert into public.experiences (id, host_id, category_id, region_id, title, slug, cover_image_url, price_paisa, status)
  values (gen_random_uuid(), v_host_active_user, v_cat, v_region, 'Dash Exp Published', 'dash-exp-pub-' || gen_random_uuid(), 'https://e.test/c.webp', 500000, 'published')
  returning id into v_exp_pub;
  insert into public.experiences (id, host_id, category_id, region_id, title, slug, cover_image_url, price_paisa, status)
  values (gen_random_uuid(), v_host_active_user, v_cat, v_region, 'Dash Exp Pending', 'dash-exp-pend-' || gen_random_uuid(), 'https://e.test/c.webp', 500000, 'pending_review')
  returning id into v_exp_pending;
  insert into public.experiences (id, host_id, category_id, region_id, title, slug, cover_image_url, price_paisa, status)
  values (gen_random_uuid(), v_host_active_user, v_cat, v_region, 'Dash Exp Draft', 'dash-exp-draft-' || gen_random_uuid(), 'https://e.test/c.webp', 500000, 'draft')
  returning id into v_exp_draft;

  insert into public.experience_departures (id, experience_id, start_date, end_date, total_spots, spots_left, status)
  values (gen_random_uuid(), v_exp_pub, current_date + 30, current_date + 32, 10, 10, 'open') returning id into v_dep_future;
  insert into public.experience_departures (id, experience_id, start_date, end_date, total_spots, spots_left, status)
  values (gen_random_uuid(), v_exp_pub, current_date - 30, current_date - 28, 10, 10, 'closed') returning id into v_dep_past;

  -- bookings: today+confirmed (counts bookingsToday, upcoming, gross),
  -- today+cancelled (counts bookingsToday, cancellationsToday),
  -- old+pending against a future departure (counts upcoming only),
  -- old+completed against a past departure (counts gross only)
  insert into public.bookings (id, booking_ref, user_id, experience_id, departure_id, adults, children,
    contact_name, contact_phone, subtotal_paisa, addons_paisa, fees_paisa, total_paisa, status, created_at)
  values (gen_random_uuid(), 'DASH-BK-0001', v_user_today1, v_exp_pub, v_dep_future, 1, 0, 'Buyer', '98000000',
    500000, 0, 0, 500000, 'confirmed', now());
  insert into public.bookings (id, booking_ref, user_id, experience_id, departure_id, adults, children,
    contact_name, contact_phone, subtotal_paisa, addons_paisa, fees_paisa, total_paisa, status, created_at, cancelled_at)
  values (gen_random_uuid(), 'DASH-BK-0002', v_user_today1, v_exp_pub, v_dep_future, 1, 0, 'Buyer', '98000000',
    200000, 0, 0, 200000, 'cancelled', now(), now());
  insert into public.bookings (id, booking_ref, user_id, experience_id, departure_id, adults, children,
    contact_name, contact_phone, subtotal_paisa, addons_paisa, fees_paisa, total_paisa, status, created_at)
  values (gen_random_uuid(), 'DASH-BK-0003', v_user_old, v_exp_pub, v_dep_future, 1, 0, 'Buyer', '98000000',
    150000, 0, 0, 150000, 'pending', now() - interval '10 days');
  insert into public.bookings (id, booking_ref, user_id, experience_id, departure_id, adults, children,
    contact_name, contact_phone, subtotal_paisa, addons_paisa, fees_paisa, total_paisa, status, created_at)
  values (gen_random_uuid(), 'DASH-BK-0004', v_user_old, v_exp_pub, v_dep_past, 1, 0, 'Buyer', '98000000',
    300000, 0, 0, 300000, 'completed', now() - interval '10 days');

  -- ── after fixtures ───────────────────────────────────────────────────
  select count(*) into v_after_new_users from public.profiles
    where (created_at at time zone 'Asia/Kathmandu')::date = (now() at time zone 'Asia/Kathmandu')::date;
  select count(*) into v_after_total_users from public.profiles;
  select count(distinct user_id) into v_after_active_users from public.bookings where created_at >= now() - interval '30 days';
  select count(*) into v_after_new_hosts from public.host_accounts
    where (created_at at time zone 'Asia/Kathmandu')::date = (now() at time zone 'Asia/Kathmandu')::date;
  select count(*) into v_after_total_hosts from public.host_accounts;
  select count(*) into v_after_active_hosts from public.host_accounts where is_active = true;
  select count(*) into v_after_awaiting_hosts from public.host_applications where status in ('submitted','under_review');
  select count(*) into v_after_total_exp from public.experiences;
  select count(*) into v_after_pub_exp from public.experiences where status = 'published';
  select count(*) into v_after_awaiting_exp from public.experiences where status = 'pending_review';
  select count(*) into v_after_bookings_today from public.bookings
    where (created_at at time zone 'Asia/Kathmandu')::date = (now() at time zone 'Asia/Kathmandu')::date;
  select count(*) into v_after_cancel_today from public.bookings
    where status = 'cancelled' and (cancelled_at at time zone 'Asia/Kathmandu')::date = (now() at time zone 'Asia/Kathmandu')::date;
  select count(*) into v_after_total_bookings from public.bookings;
  select count(*) into v_after_upcoming from public.bookings b
    join public.experience_departures d on d.id = b.departure_id
    where d.start_date >= (now() at time zone 'Asia/Kathmandu')::date and b.status in ('pending','confirmed');
  select coalesce(sum(total_paisa), 0) into v_after_gross from public.bookings where status in ('confirmed','completed');

  -- ── assert exact deltas ──────────────────────────────────────────────
  if v_after_new_users - v_before_new_users <> 2 then
    raise exception 'FAIL: newUsersToday delta expected 2, got %', v_after_new_users - v_before_new_users;
  end if;
  if v_after_total_users - v_before_total_users <> 5 then
    raise exception 'FAIL: totalUsers delta expected 5, got %', v_after_total_users - v_before_total_users;
  end if;
  if v_after_active_users - v_before_active_users <> 2 then
    raise exception 'FAIL: activeUsers delta expected 2 (v_user_today1, v_user_old both booked), got %', v_after_active_users - v_before_active_users;
  end if;
  if v_after_new_hosts - v_before_new_hosts <> 1 then
    raise exception 'FAIL: newHostsToday delta expected 1, got %', v_after_new_hosts - v_before_new_hosts;
  end if;
  if v_after_total_hosts - v_before_total_hosts <> 2 then
    raise exception 'FAIL: totalHosts delta expected 2, got %', v_after_total_hosts - v_before_total_hosts;
  end if;
  if v_after_active_hosts - v_before_active_hosts <> 1 then
    raise exception 'FAIL: activeHosts delta expected 1, got %', v_after_active_hosts - v_before_active_hosts;
  end if;
  if v_after_awaiting_hosts - v_before_awaiting_hosts <> 2 then
    raise exception 'FAIL: hostApplicationsAwaitingReview delta expected 2, got %', v_after_awaiting_hosts - v_before_awaiting_hosts;
  end if;
  if v_after_total_exp - v_before_total_exp <> 3 then
    raise exception 'FAIL: totalExperiences delta expected 3, got %', v_after_total_exp - v_before_total_exp;
  end if;
  if v_after_pub_exp - v_before_pub_exp <> 1 then
    raise exception 'FAIL: publishedExperiences delta expected 1, got %', v_after_pub_exp - v_before_pub_exp;
  end if;
  if v_after_awaiting_exp - v_before_awaiting_exp <> 1 then
    raise exception 'FAIL: experiencesAwaitingReview delta expected 1, got %', v_after_awaiting_exp - v_before_awaiting_exp;
  end if;
  if v_after_bookings_today - v_before_bookings_today <> 2 then
    raise exception 'FAIL: bookingsToday delta expected 2, got %', v_after_bookings_today - v_before_bookings_today;
  end if;
  if v_after_cancel_today - v_before_cancel_today <> 1 then
    raise exception 'FAIL: cancellationsToday delta expected 1, got %', v_after_cancel_today - v_before_cancel_today;
  end if;
  if v_after_total_bookings - v_before_total_bookings <> 4 then
    raise exception 'FAIL: totalBookings delta expected 4, got %', v_after_total_bookings - v_before_total_bookings;
  end if;
  if v_after_upcoming - v_before_upcoming <> 2 then
    raise exception 'FAIL: upcomingBookings delta expected 2 (confirmed-today + pending-old, both future departure), got %', v_after_upcoming - v_before_upcoming;
  end if;
  if v_after_gross - v_before_gross <> 800000 then
    raise exception 'FAIL: grossBookingValue delta expected 800000 paisa (confirmed 500000 + completed 300000, cancelled/pending excluded), got %', v_after_gross - v_before_gross;
  end if;

  raise notice 'OK: all 13 dashboard counter deltas match expected values against known fixtures';
end $$;

rollback;
