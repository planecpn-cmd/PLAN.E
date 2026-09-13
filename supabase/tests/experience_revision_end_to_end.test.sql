-- D1: editing a PUBLISHED listing creates a pending-review revision; the live
-- row is never mutated until a reviewer approves; travelers see the live
-- version throughout; on approve the revision is swapped into the live row
-- atomically and archived.

begin;

do $$
declare
  v_host uuid := 'd3000000-0000-4000-8000-000000000001';  -- approved active host
  v_rev  uuid := 'd3000000-0000-4000-8000-000000000002';  -- content:manage + content:decide
  v_trav uuid := '11111111-1111-4111-8111-000000000001';
  v_cat    uuid;
  v_region uuid;
  v_live uuid;
  v_revision uuid;
  v_cnt  int;
  v_title text;
begin
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  select id into v_cat    from public.categories order by created_at limit 1;
  select id into v_region from public.regions    order by created_at limit 1;

  insert into auth.users (id, instance_id, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role, aud)
  select u, '00000000-0000-0000-0000-000000000000', u::text || '@rev.test', 'x', now(),
    '{"provider":"email","providers":["email"]}', '{}', now(), now(), 'authenticated', 'authenticated'
  from unnest(array[v_host, v_rev]) u
  on conflict (id) do nothing;

  insert into public.profiles (id, full_name, role)
  values (v_host,'Rev Host','traveler'), (v_rev,'Rev Reviewer','traveler')
  on conflict (id) do update set role = excluded.role;

  insert into public.host_applications (id, user_id, status, current_step, application_data)
  values (gen_random_uuid(), v_host, 'approved', 8, '{}'::jsonb)
  on conflict (user_id) do nothing;

  insert into public.staff_members (user_id, status, scopes)
  values (v_rev, 'active', array['content:manage','content:decide'])
  on conflict (user_id) do update set scopes = excluded.scopes;

  -- a LIVE published listing owned by the host
  insert into public.experiences
    (id, host_id, category_id, region_id, title, slug, description, location_name,
     cover_image_url, gallery, price_paisa, difficulty, status)
  values (gen_random_uuid(), v_host, v_cat, v_region, 'Original Ridge Trek',
    'original-ridge-trek', 'The original description.', 'Kaski, Nepal',
    'http://pub/experience-photos-public/orig/cover.jpg',
    array['http://pub/experience-photos-public/orig/cover.jpg'],
    500000, 'moderate', 'published')
  returning id into v_live;
  insert into public.itinerary_items (experience_id, day_number, title, sort_order)
  values (v_live, 1, 'Original day 1', 1);

  ----------------------------------------------------------------------------
  -- 1. host edits the published listing -> a revision is created, live untouched
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_host, 'role', 'authenticated')::text, true);
  v_revision := public.host_save_experience_draft(jsonb_build_object(
    'id', v_live::text,
    'title', 'Revised Ridge Trek',
    'location', 'Kaski, Nepal',
    'description', 'A revised, longer and more detailed description of the trek.',
    'trip_details', 'Now with an extra acclimatisation day.',
    'meeting_point', 'Lakeside, Pokhara',
    'price_npr', 6500, 'capacity', 8,
    'itinerary', jsonb_build_array('Revised day 1', 'Revised day 2'),
    'included', jsonb_build_array('Guide', 'Extra night'),
    'bring', jsonb_build_array('Boots'),
    'gallery', jsonb_build_array(
      'http://pub/experience-photos-public/orig/cover.jpg',
      v_host::text || '/rev/new.jpg'),
    'cover_image_url', 'http://pub/experience-photos-public/orig/cover.jpg'));
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);

  if v_revision = v_live then
    raise exception 'FAIL: edit mutated the live row instead of making a revision';
  end if;
  if (select revision_of from public.experiences where id = v_revision) is distinct from v_live
     or (select status from public.experiences where id = v_revision)
        is distinct from 'draft'::public.experience_status then
    raise exception 'FAIL: revision row not shaped correctly';
  end if;
  select title into v_title from public.experiences where id = v_live;
  if v_title <> 'Original Ridge Trek'
     or (select status from public.experiences where id = v_live)
        is distinct from 'published'::public.experience_status then
    raise exception 'FAIL: live row changed while a revision is in progress (title=%)', v_title;
  end if;

  -- 2. travelers still see the live version, and cannot see the revision
  set local role authenticated;
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_trav, 'role', 'authenticated')::text, true);
  select count(*) into v_cnt from public.experiences
  where slug = 'original-ridge-trek' and status = 'published' and title = 'Original Ridge Trek';
  if v_cnt <> 1 then reset role; raise exception 'FAIL: traveler lost sight of the live listing'; end if;
  select count(*) into v_cnt from public.experiences where id = v_revision;
  if v_cnt <> 0 then reset role; raise exception 'FAIL: a traveler can see the revision'; end if;
  reset role;

  -- 3. host submits the revision for review
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_host, 'role', 'authenticated')::text, true);
  perform public.host_submit_experience_for_review(v_revision);
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  if (select status from public.experiences where id = v_revision)
     is distinct from 'pending_review'::public.experience_status then
    raise exception 'FAIL: revision did not reach pending_review';
  end if;
  -- live still untouched
  if (select title from public.experiences where id = v_live) <> 'Original Ridge Trek' then
    raise exception 'FAIL: live row changed on revision submit';
  end if;

  -- a second edit while one revision is in review is refused
  begin
    perform set_config('request.jwt.claims',
      json_build_object('sub', v_host, 'role', 'authenticated')::text, true);
    perform public.host_save_experience_draft(jsonb_build_object(
      'id', v_live::text, 'title', 'Third attempt'));
    perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
    raise exception 'FAIL: a second revision was allowed while one is in review';
  exception when others then
    perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  end;

  -- 4. reviewer approve -> swap into the live row atomically, archive the revision
  perform public.admin_apply_experience_revision(v_revision, v_rev, jsonb_build_object(
    'cover', 'http://pub/experience-photos-public/orig/cover.jpg',
    'gallery', jsonb_build_array(
      'http://pub/experience-photos-public/orig/cover.jpg',
      'http://pub/experience-photos-public/' || v_host::text || '/rev/new.jpg'),
    'category_id', v_cat::text,
    'region_id', v_region::text,
    'difficulty', 'challenging'));

  if (select title from public.experiences where id = v_live) <> 'Revised Ridge Trek'
     or (select status from public.experiences where id = v_live)
        is distinct from 'published'::public.experience_status
     or (select difficulty from public.experiences where id = v_live)
        is distinct from 'challenging'::public.difficulty_level
     or (select price_paisa from public.experiences where id = v_live) <> 650000 then
    raise exception 'FAIL: revision was not swapped into the live row on approve';
  end if;
  if (select status from public.experiences where id = v_revision)
     is distinct from 'archived'::public.experience_status then
    raise exception 'FAIL: revision not archived after approve';
  end if;
  select count(*) into v_cnt from public.itinerary_items where experience_id = v_live;
  if v_cnt <> 2 then raise exception 'FAIL: live itinerary not replaced from the revision'; end if;
  if not exists (
    select 1 from public.experience_reviews
    where experience_id = v_live and decision = 'approve' and note = 'revision applied'
  ) then
    raise exception 'FAIL: no experience_reviews row on the live id after approve';
  end if;

  -- 5. travelers now see the revised content, still one published row
  set local role authenticated;
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_trav, 'role', 'authenticated')::text, true);
  select count(*) into v_cnt from public.experiences
  where slug = 'original-ridge-trek' and status = 'published' and title = 'Revised Ridge Trek';
  reset role;
  if v_cnt <> 1 then
    raise exception 'FAIL: traveler does not see the approved revision on the live slug';
  end if;

  raise notice 'OK: published edit -> revision -> submit -> approve swaps into live atomically, live never mutated mid-flight';
end $$;

rollback;
