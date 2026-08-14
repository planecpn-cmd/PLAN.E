-- DEVELOPMENT / DEMONSTRATION DATA ONLY.
--
-- Approves the single confirmed test account below and gives it deterministic
-- Host Mode records for device testing. This is intentionally scoped to one
-- explicit auth user and must not be reused as production authorization logic.

do $$
declare
  v_host_id constant uuid := '25ffe805-82b2-4a43-9fc1-203b080e197b';
  v_application_id constant uuid := 'a1000000-0000-4000-8000-000000000001';
  v_traveler_id uuid;
  v_category_id uuid;
  v_region_id uuid;
begin
  if not exists (select 1 from public.profiles where id = v_host_id) then
    raise exception 'Demo host profile % does not exist', v_host_id;
  end if;

  -- The existing privilege-escalation guards recognize only service-role
  -- review. A migration is a trusted administrative operation, so identify
  -- this transaction accordingly before setting backend-owned status fields.
  perform set_config(
    'request.jwt.claims',
    '{"role":"service_role"}',
    true
  );

  select id into v_category_id
  from public.categories
  where slug = 'trekking';

  select id into v_region_id
  from public.regions
  where slug = 'annapurna';

  if v_category_id is null or v_region_id is null then
    raise exception 'Required trekking/annapurna taxonomy is missing';
  end if;

  update public.profiles
  set full_name = 'Ram Shrestha',
      location = coalesce(nullif(location, ''), 'Pokhara, Nepal'),
      bio = coalesce(
        nullif(bio, ''),
        'DEVELOPMENT ONLY demo host for PLAN E frontend testing.'
      ),
      onboarding_complete = true,
      updated_at = now()
  where id = v_host_id;

  insert into public.host_applications (
    id,
    user_id,
    status,
    current_step,
    category_id,
    title,
    description,
    location,
    photos,
    submitted_at,
    reviewed_at,
    reviewer_note
  ) values (
    v_application_id,
    v_host_id,
    'approved'::public.host_app_status,
    4,
    v_category_id,
    'Local trekking host',
    'DEVELOPMENT ONLY approved host application for frontend testing.',
    'Pokhara, Nepal',
    array[]::text[],
    now(),
    now(),
    'DEVELOPMENT ONLY: approved for the linked test project.'
  )
  on conflict (user_id) do update set
    status = 'approved'::public.host_app_status,
    current_step = 4,
    category_id = excluded.category_id,
    title = excluded.title,
    description = excluded.description,
    location = excluded.location,
    submitted_at = coalesce(public.host_applications.submitted_at, now()),
    reviewed_at = now(),
    reviewer_note = excluded.reviewer_note,
    updated_at = now();

  -- Keep the deterministic application id when this is the first demo seed;
  -- the approval trigger creates/reactivates host_accounts and derives role.
  if not exists (
    select 1
    from public.host_accounts ha
    join public.host_applications app on app.id = ha.application_id
    where ha.user_id = v_host_id
      and ha.is_active
      and ha.suspended_at is null
      and app.status = 'approved'::public.host_app_status
  ) then
    raise exception 'Demo host approval synchronization failed for %', v_host_id;
  end if;

  insert into public.experiences (
    id, host_id, category_id, region_id, title, slug, summary, description,
    cover_image_url, gallery, location_name, meeting_point, duration_hours,
    difficulty, max_altitude_m, group_size_min, group_size_max, min_age,
    price_paisa, included, bring_list, status
  ) values
  (
    'e1000000-0000-4000-8000-000000000001', v_host_id,
    v_category_id, v_region_id, 'Mardi Himal Trek',
    'demo-ram-mardi-himal-trek',
    'A five-day ridge trek with close views of Machhapuchhre.',
    'DEVELOPMENT ONLY listing used to exercise the published Host Mode flow.',
    'https://images.unsplash.com/photo-1544735716-392fe2489ffa?auto=format&fit=crop&w=1200&q=80',
    array[]::text[], 'Kaski, Nepal', 'Lakeside, Pokhara', 120,
    'challenging'::public.difficulty_level, 4500, 1, 8, 16, 1250000,
    array['Local guide', 'Accommodation', 'Breakfast and dinner'],
    array['Hiking boots', 'Warm layers', 'Reusable water bottle'],
    'published'::public.experience_status
  ),
  (
    'e1000000-0000-4000-8000-000000000002', v_host_id,
    v_category_id, v_region_id, 'Pokhara Food & Culture Walk',
    'demo-ram-pokhara-food-culture-walk',
    'A relaxed local food and heritage walk through Pokhara.',
    'DEVELOPMENT ONLY draft listing for filter and edit testing.',
    'https://images.unsplash.com/photo-1605640840605-14ac1855827b?auto=format&fit=crop&w=1200&q=80',
    array[]::text[], 'Pokhara, Nepal', 'Old Bazaar, Pokhara', 6,
    'easy'::public.difficulty_level, 900, 1, 10, 8, 350000,
    array['Local tastings', 'Host guide'], array['Comfortable shoes'],
    'draft'::public.experience_status
  ),
  (
    'e1000000-0000-4000-8000-000000000003', v_host_id,
    v_category_id, v_region_id, 'Panchase Sunrise Hike',
    'demo-ram-panchase-sunrise-hike',
    'A sunrise hike above Phewa Lake and the Annapurna foothills.',
    'DEVELOPMENT ONLY pending-review listing for status testing.',
    'https://images.unsplash.com/photo-1519681393784-d120267933ba?auto=format&fit=crop&w=1200&q=80',
    array[]::text[], 'Kaski, Nepal', 'Hallan Chowk, Pokhara', 12,
    'moderate'::public.difficulty_level, 2500, 1, 8, 12, 550000,
    array['Transport', 'Breakfast'], array['Day pack', 'Light jacket'],
    'pending_review'::public.experience_status
  ),
  (
    'e1000000-0000-4000-8000-000000000004', v_host_id,
    v_category_id, v_region_id, 'Ghandruk Village Weekend',
    'demo-ram-ghandruk-village-weekend',
    'A community-led weekend in the Gurung village of Ghandruk.',
    'DEVELOPMENT ONLY paused listing for reactivate-flow testing.',
    'https://images.unsplash.com/photo-1589182373726-e4f658ab50f0?auto=format&fit=crop&w=1200&q=80',
    array[]::text[], 'Ghandruk, Nepal', 'Baglung Bus Park, Pokhara', 48,
    'moderate'::public.difficulty_level, 1940, 1, 8, 12, 850000,
    array['Homestay', 'Meals', 'Local guide'], array['Walking shoes'],
    'paused'::public.experience_status
  )
  on conflict (id) do update set
    host_id = excluded.host_id,
    category_id = excluded.category_id,
    region_id = excluded.region_id,
    title = excluded.title,
    summary = excluded.summary,
    description = excluded.description,
    cover_image_url = excluded.cover_image_url,
    location_name = excluded.location_name,
    meeting_point = excluded.meeting_point,
    duration_hours = excluded.duration_hours,
    difficulty = excluded.difficulty,
    max_altitude_m = excluded.max_altitude_m,
    group_size_min = excluded.group_size_min,
    group_size_max = excluded.group_size_max,
    min_age = excluded.min_age,
    price_paisa = excluded.price_paisa,
    included = excluded.included,
    bring_list = excluded.bring_list,
    status = excluded.status,
    updated_at = now();

  insert into public.experience_departures (
    id, experience_id, start_date, end_date, total_spots, spots_left, status
  ) values
    ('d1000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000001', '2026-09-18', '2026-09-22', 8, 2, 'open'),
    ('d1000000-0000-4000-8000-000000000002', 'e1000000-0000-4000-8000-000000000002', '2026-10-03', '2026-10-03', 10, 10, 'open'),
    ('d1000000-0000-4000-8000-000000000003', 'e1000000-0000-4000-8000-000000000003', '2026-10-10', '2026-10-10', 8, 8, 'open'),
    ('d1000000-0000-4000-8000-000000000004', 'e1000000-0000-4000-8000-000000000004', '2026-11-07', '2026-11-08', 8, 8, 'closed')
  on conflict (id) do update set
    experience_id = excluded.experience_id,
    start_date = excluded.start_date,
    end_date = excluded.end_date,
    total_spots = excluded.total_spots,
    spots_left = excluded.spots_left,
    status = excluded.status;

  insert into public.itinerary_items (
    id, experience_id, day_number, title, description, sort_order
  ) values
    ('f1000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000001', 1, 'Pokhara to Forest Camp', 'Meet in Pokhara and trek through rhododendron forest.', 1),
    ('f1000000-0000-4000-8000-000000000002', 'e1000000-0000-4000-8000-000000000001', 2, 'Forest Camp to High Camp', 'Climb the ridge toward the high camp.', 2),
    ('f1000000-0000-4000-8000-000000000003', 'e1000000-0000-4000-8000-000000000001', 3, 'Mardi viewpoint', 'Early viewpoint hike and return toward the valley.', 3)
  on conflict (id) do update set
    title = excluded.title,
    description = excluded.description,
    sort_order = excluded.sort_order;

  select p.id into v_traveler_id
  from public.profiles p
  where p.id <> v_host_id
    and p.role = 'traveler'::public.user_role
  order by p.created_at
  limit 1;

  if v_traveler_id is not null then
    insert into public.bookings (
      id, booking_ref, user_id, experience_id, departure_id, adults, children,
      contact_name, contact_phone, subtotal_paisa, addons_paisa, fees_paisa,
      total_paisa, status, is_draft, created_at
    ) values
    (
      'b1000000-0000-4000-8000-000000000001', 'DEMO-RAM-REQUEST',
      v_traveler_id, 'e1000000-0000-4000-8000-000000000001',
      'd1000000-0000-4000-8000-000000000001', 2, 0,
      'Aarav Gurung', '9800000001', 2500000, 0, 0, 2500000,
      'pending'::public.booking_status, false, now() - interval '2 hours'
    ),
    (
      'b1000000-0000-4000-8000-000000000002', 'DEMO-RAM-CONFIRMED',
      v_traveler_id, 'e1000000-0000-4000-8000-000000000001',
      'd1000000-0000-4000-8000-000000000001', 4, 0,
      'Sita Rai', '9800000002', 5000000, 0, 0, 5000000,
      'confirmed'::public.booking_status, false, now() - interval '3 days'
    )
    on conflict (id) do update set
      user_id = excluded.user_id,
      experience_id = excluded.experience_id,
      departure_id = excluded.departure_id,
      adults = excluded.adults,
      children = excluded.children,
      contact_name = excluded.contact_name,
      contact_phone = excluded.contact_phone,
      subtotal_paisa = excluded.subtotal_paisa,
      total_paisa = excluded.total_paisa,
      status = excluded.status,
      is_draft = false,
      updated_at = now();

    insert into public.booking_participants (
      id, booking_id, full_name, age, is_lead
    ) values
      ('c1000000-0000-4000-8000-000000000001', 'b1000000-0000-4000-8000-000000000001', 'Aarav Gurung', 29, true),
      ('c1000000-0000-4000-8000-000000000002', 'b1000000-0000-4000-8000-000000000001', 'Maya Gurung', 27, false),
      ('c1000000-0000-4000-8000-000000000003', 'b1000000-0000-4000-8000-000000000002', 'Sita Rai', 32, true),
      ('c1000000-0000-4000-8000-000000000004', 'b1000000-0000-4000-8000-000000000002', 'Nima Rai', 34, false)
    on conflict (id) do update set
      full_name = excluded.full_name,
      age = excluded.age,
      is_lead = excluded.is_lead;

    insert into public.trip_messages (
      id, booking_id, sender_id, body, created_at
    ) values
      ('a2000000-0000-4000-8000-000000000001', 'b1000000-0000-4000-8000-000000000001', v_traveler_id, 'Namaste! Is a sleeping bag included?', now() - interval '90 minutes'),
      ('a2000000-0000-4000-8000-000000000002', 'b1000000-0000-4000-8000-000000000001', v_host_id, 'Namaste! Yes, it is included in this demo departure.', now() - interval '75 minutes'),
      ('a2000000-0000-4000-8000-000000000003', 'b1000000-0000-4000-8000-000000000002', v_host_id, 'Welcome to the Mardi Himal departure group!', now() - interval '4 days')
    on conflict (id) do update set
      body = excluded.body,
      created_at = excluded.created_at;
  end if;
end;
$$;
