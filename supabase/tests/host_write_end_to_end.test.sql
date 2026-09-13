-- H1 exit condition: a host goes from an empty wizard to pending_review.
--
-- host A saves a draft with a photo -> cover_image_url is set -> submit for
-- review succeeds -> the row is pending_review with the photo readable by a
-- content:manage reviewer and NOT by another host.

begin;

do $$
declare
  v_hostA uuid := 'c6000000-0000-4000-8000-000000000001';
  v_hostB uuid := 'c6000000-0000-4000-8000-000000000002';
  v_mgr   uuid := 'c6000000-0000-4000-8000-000000000003';
  v_id    uuid;
  v_cover text;
  v_photo text;
begin
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);

  insert into auth.users (id, instance_id, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role, aud)
  select u, '00000000-0000-0000-0000-000000000000', u::text || '@e2e.test', 'x', now(),
    '{"provider":"email","providers":["email"]}', '{}', now(), now(), 'authenticated', 'authenticated'
  from unnest(array[v_hostA, v_hostB, v_mgr]) u
  on conflict (id) do nothing;

  insert into public.profiles (id, full_name, role)
  values (v_hostA,'E2E A','traveler'), (v_hostB,'E2E B','traveler'), (v_mgr,'E2E Mgr','traveler')
  on conflict (id) do update set role = excluded.role;

  insert into public.host_applications (id, user_id, status, current_step, application_data)
  values
    (gen_random_uuid(), v_hostA, 'approved', 8, '{}'::jsonb),
    (gen_random_uuid(), v_hostB, 'approved', 8, '{}'::jsonb)
  on conflict (user_id) do nothing;

  insert into public.staff_members (user_id, status, scopes)
  values (v_mgr, 'active', array['content:manage'])
  on conflict (user_id) do update set status = excluded.status, scopes = excluded.scopes;

  v_photo := v_hostA::text || '/wiz-1/1700000000000.jpg';

  ----------------------------------------------------------------------------
  -- 1. save a complete draft WITH a photo, as host A
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_hostA, 'role', 'authenticated')::text, true);
  v_id := public.host_save_experience_draft(jsonb_build_object(
    'title', 'E2E Sunrise Hike',
    'location', 'Kaski, Nepal',
    'description', 'A short sunrise hike above Pokhara with a local host.',
    'trip_details', 'Easy, half a day, transport included.',
    'meeting_point', 'Lakeside, Pokhara',
    'price_npr', 4500,
    'capacity', 6,
    'start_date', '2026-10-05',
    'end_date', '2026-10-05',
    'itinerary', jsonb_build_array('05:00 pickup', '06:15 summit for sunrise'),
    'included', jsonb_build_array('Local guide', 'Transport'),
    'bring', jsonb_build_array('Warm layer', 'Headlamp'),
    'gallery', jsonb_build_array(v_photo),
    'cover_image_url', v_photo
  ));
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);

  select cover_image_url into v_cover from public.experiences where id = v_id;
  if v_cover is distinct from v_photo
     or (select status from public.experiences where id = v_id)
        is distinct from 'draft'::public.experience_status then
    raise exception 'FAIL: draft not saved with the cover photo (cover %)', v_cover;
  end if;

  -- the object exists in storage (client uploaded it before saving)
  insert into storage.objects (bucket_id, name)
  values ('experience-photos', v_photo);

  ----------------------------------------------------------------------------
  -- 2. submit for review, as host A -> pending_review
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_hostA, 'role', 'authenticated')::text, true);
  perform public.host_submit_experience_for_review(v_id);
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);

  if (select status from public.experiences where id = v_id)
     is distinct from 'pending_review'::public.experience_status then
    raise exception 'FAIL: complete draft with a photo did not reach pending_review';
  end if;
  if (select cover_image_url from public.experiences where id = v_id) is distinct from v_photo then
    raise exception 'FAIL: cover_image_url lost on submit';
  end if;

  ----------------------------------------------------------------------------
  -- 3. the photo is readable by a content:manage reviewer, not by another host
  set local role authenticated;

  perform set_config('request.jwt.claims',
    json_build_object('sub', v_mgr, 'role', 'authenticated')::text, true);
  if (select count(*) from storage.objects
      where bucket_id = 'experience-photos' and name = v_photo) <> 1 then
    reset role;
    raise exception 'FAIL: a content:manage reviewer cannot read the submitted photo';
  end if;

  perform set_config('request.jwt.claims',
    json_build_object('sub', v_hostB, 'role', 'authenticated')::text, true);
  if (select count(*) from storage.objects
      where bucket_id = 'experience-photos' and name = v_photo) <> 0 then
    reset role;
    raise exception 'FAIL: another host can read the submitted photo';
  end if;

  reset role;
  raise notice 'OK: empty wizard -> draft with photo -> pending_review, photo reviewer-readable only';
end $$;

rollback;
