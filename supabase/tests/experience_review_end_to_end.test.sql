-- N1 exit condition: signup -> approved host -> creates an experience with a
-- photo -> submits -> a reviewer approves -> the experience is discoverable by a
-- traveler as 'published' with a PUBLIC-bucket cover URL.
--
-- The reviewer's approve is a service-role admin route
-- (POST /api/experiences/:id/decision, content:decide). Its storage copy
-- (experience-photos -> experience-photos-public) cannot run in psql, so this
-- test performs the route's SQL-observable effects as service_role and then
-- checks the traveler-visible outcome.

begin;

do $$
declare
  v_host uuid := 'd2000000-0000-4000-8000-000000000001';  -- approved active host
  v_rev  uuid := 'd2000000-0000-4000-8000-000000000002';  -- content:manage + content:decide
  v_trav uuid := '11111111-1111-4111-8111-000000000001';  -- seed traveler
  v_cat    uuid;
  v_region uuid;
  v_id   uuid;
  v_priv text;
  v_pub  text;
  v_cnt  int;
begin
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  select id into v_cat    from public.categories order by created_at limit 1;
  select id into v_region from public.regions    order by created_at limit 1;

  insert into auth.users (id, instance_id, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role, aud)
  select u, '00000000-0000-0000-0000-000000000000', u::text || '@e2n.test', 'x', now(),
    '{"provider":"email","providers":["email"]}', '{}', now(), now(), 'authenticated', 'authenticated'
  from unnest(array[v_host, v_rev]) u
  on conflict (id) do nothing;

  insert into public.profiles (id, full_name, role)
  values (v_host,'E2N Host','traveler'), (v_rev,'E2N Rev','traveler')
  on conflict (id) do update set role = excluded.role;

  insert into public.host_applications (id, user_id, status, current_step, application_data)
  values (gen_random_uuid(), v_host, 'approved', 8, '{}'::jsonb)
  on conflict (user_id) do nothing;

  insert into public.staff_members (user_id, status, scopes)
  values (v_rev, 'active', array['content:manage','content:decide'])
  on conflict (user_id) do update set status = excluded.status, scopes = excluded.scopes;

  v_priv := v_host::text || '/wiz/1700000000000.jpg';

  ----------------------------------------------------------------------------
  -- host: save a complete draft with a photo, then submit
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_host, 'role', 'authenticated')::text, true);
  v_id := public.host_save_experience_draft(jsonb_build_object(
    'title', 'E2N Ridge Trek',
    'location', 'Kaski, Nepal',
    'description', 'A guided ridge trek with teahouse stays and sunrise views.',
    'trip_details', 'Moderate, four days, transport from Pokhara included.',
    'meeting_point', 'Lakeside, Pokhara',
    'price_npr', 18000, 'capacity', 8,
    'start_date', '2026-11-01', 'end_date', '2026-11-04',
    'itinerary', jsonb_build_array('Day 1 drive in', 'Day 2 ascend'),
    'included', jsonb_build_array('Guide', 'Teahouse'),
    'bring', jsonb_build_array('Boots'),
    'gallery', jsonb_build_array(v_priv),
    'cover_image_url', v_priv));
  perform public.host_submit_experience_for_review(v_id);
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);

  insert into storage.objects (bucket_id, name) values ('experience-photos', v_priv);

  if (select status from public.experiences where id = v_id)
     is distinct from 'pending_review'::public.experience_status then
    raise exception 'FAIL: submit did not reach pending_review';
  end if;

  ----------------------------------------------------------------------------
  -- reviewer approve (route effects): copy the object to the public bucket,
  -- set the public cover/gallery + normalised taxonomy, status = published,
  -- write the review row.
  insert into storage.objects (bucket_id, name) values ('experience-photos-public', v_priv);
  v_pub := 'http://127.0.0.1:54341/storage/v1/object/public/experience-photos-public/' || v_priv;

  update public.experiences set
    status = 'published',
    category_id = v_cat,
    region_id = v_region,
    difficulty = 'moderate',
    cover_image_url = v_pub,
    gallery = array[v_pub],
    reviewer_id = v_rev,
    updated_at = now()
  where id = v_id;

  insert into public.experience_reviews
    (experience_id, reviewer_id, from_status, to_status, decision, note)
  values (v_id, v_rev, 'pending_review', 'published', 'approve', null);

  ----------------------------------------------------------------------------
  -- traveler discovery: the published experience is visible with a public cover
  set local role authenticated;
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_trav, 'role', 'authenticated')::text, true);

  select count(*) into v_cnt from public.experiences
  where id = v_id and status = 'published';
  if v_cnt <> 1 then
    reset role;
    raise exception 'FAIL: a traveler cannot see the approved experience as published';
  end if;

  if (select cover_image_url from public.experiences where id = v_id)
     not like '%/experience-photos-public/%' then
    reset role;
    raise exception 'FAIL: cover_image_url is not a public-bucket URL after approve';
  end if;

  reset role;

  -- and it shows up in a plain published-catalog scan
  if not exists (
    select 1 from public.experiences
    where status = 'published' and slug like 'e2n-ridge-trek%'
  ) then
    raise exception 'FAIL: approved experience missing from the published catalog';
  end if;

  raise notice 'OK: signup -> approved host -> draft+photo -> submit -> approve -> published + discoverable with a public cover';
end $$;

rollback;
