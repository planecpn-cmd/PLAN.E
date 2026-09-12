-- H1 core (3/4): public.host_save_experience_draft(jsonb)
--
-- Creates / edits an experience DRAFT only. Asserts: create writes a draft row
-- + itinerary + one departure; a second call updates in place and replaces the
-- itinerary; slugs are unique per title collision; editing a non-draft row is
-- refused; non-owner / suspended / no-title / bad-capacity refused; a draft
-- with no dates gets no departure.

begin;

do $$
declare
  v_owner uuid := 'c3000000-0000-4000-8000-000000000001';
  v_other uuid := 'c3000000-0000-4000-8000-000000000002';
  v_susp  uuid := 'c3000000-0000-4000-8000-000000000003';
  v_id1   uuid;
  v_id2   uuid;
  v_idn   uuid;
  v_slug1 text;
  v_slug2 text;
  v_raised boolean;
  v_cnt   int;
  v_base  jsonb;
begin
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);

  insert into auth.users (id, instance_id, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role, aud)
  select u, '00000000-0000-0000-0000-000000000000', u::text || '@hw3.test', 'x', now(),
    '{"provider":"email","providers":["email"]}', '{}', now(), now(), 'authenticated', 'authenticated'
  from unnest(array[v_owner, v_other, v_susp]) u
  on conflict (id) do nothing;

  insert into public.profiles (id, full_name, role)
  values (v_owner,'HW3 Owner','traveler'), (v_other,'HW3 Other','traveler'),
         (v_susp,'HW3 Susp','traveler')
  on conflict (id) do update set role = excluded.role;

  insert into public.host_applications (id, user_id, status, current_step, application_data)
  values
    (gen_random_uuid(), v_owner, 'approved', 8, '{}'::jsonb),
    (gen_random_uuid(), v_other, 'approved', 8, '{}'::jsonb),
    (gen_random_uuid(), v_susp,  'approved', 8, '{}'::jsonb)
  on conflict (user_id) do nothing;
  update public.host_accounts set is_active = false, suspended_at = now()
  where user_id = v_susp;

  v_base := jsonb_build_object(
    'title', 'Annapurna Base Camp Trek',
    'location', 'Kaski, Nepal',
    'description', 'A classic lodge-to-lodge trek into the Annapurna sanctuary.',
    'trip_details', 'Moderate, seven days, teahouse stays throughout.',
    'meeting_point', 'Lakeside, Pokhara',
    'price_npr', 32000,
    'capacity', 10,
    'start_date', '2026-10-05',
    'end_date', '2026-10-12',
    'itinerary', jsonb_build_array('Day 1 — Pokhara to Nayapul', 'Day 2 — to Ghandruk'),
    'included', jsonb_build_array('Licensed guide', 'Teahouse stays'),
    'bring', jsonb_build_array('Boots', 'Warm layers'),
    'gallery', jsonb_build_array()
  );

  ----------------------------------------------------------------------------
  -- 1. create
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_owner, 'role', 'authenticated')::text, true);
  v_id1 := public.host_save_experience_draft(v_base);
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);

  select slug into v_slug1 from public.experiences where id = v_id1;
  if not exists (
    select 1 from public.experiences
    where id = v_id1 and host_id = v_owner
      and status = 'draft'::public.experience_status
      and title = 'Annapurna Base Camp Trek'
      and price_paisa = 3200000 and group_size_max = 10
      and cover_image_url is null
      and included @> array['Licensed guide']
      and things_to_know @> array['Moderate, seven days, teahouse stays throughout.']
  ) then
    raise exception 'FAIL: draft row not written as expected';
  end if;

  select count(*) into v_cnt from public.itinerary_items where experience_id = v_id1;
  if v_cnt <> 2 then raise exception 'FAIL: itinerary items = % (want 2)', v_cnt; end if;

  select count(*) into v_cnt from public.experience_departures
  where experience_id = v_id1 and status = 'open'
    and start_date = date '2026-10-05' and total_spots = 10 and spots_left = 10;
  if v_cnt <> 1 then raise exception 'FAIL: departure not created for the draft'; end if;

  ----------------------------------------------------------------------------
  -- 2. update in place: new title, shorter itinerary
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_owner, 'role', 'authenticated')::text, true);
  v_id2 := public.host_save_experience_draft(
    v_base || jsonb_build_object(
      'id', v_id1::text,
      'title', 'ABC Trek (revised)',
      'itinerary', jsonb_build_array('Day 1 only')));
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);

  if v_id2 <> v_id1 then raise exception 'FAIL: update created a new row'; end if;
  if (select title from public.experiences where id = v_id1) <> 'ABC Trek (revised)' then
    raise exception 'FAIL: update did not change the title';
  end if;
  if (select slug from public.experiences where id = v_id1) <> v_slug1 then
    raise exception 'FAIL: slug churned on update';
  end if;
  select count(*) into v_cnt from public.itinerary_items where experience_id = v_id1;
  if v_cnt <> 1 then raise exception 'FAIL: itinerary not replaced (count %)', v_cnt; end if;

  ----------------------------------------------------------------------------
  -- 2b. gallery is REPLACED, not appended: save with two photos, then one
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_owner, 'role', 'authenticated')::text, true);
  perform public.host_save_experience_draft(v_base || jsonb_build_object(
    'id', v_id1::text,
    'gallery', jsonb_build_array(
      v_owner::text || '/k/1.jpg', v_owner::text || '/k/2.jpg'),
    'cover_image_url', v_owner::text || '/k/1.jpg'));
  perform public.host_save_experience_draft(v_base || jsonb_build_object(
    'id', v_id1::text,
    'gallery', jsonb_build_array(v_owner::text || '/k/2.jpg'),
    'cover_image_url', v_owner::text || '/k/2.jpg'));
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  if (select gallery from public.experiences where id = v_id1)
     is distinct from array[v_owner::text || '/k/2.jpg']
     or (select cover_image_url from public.experiences where id = v_id1)
        is distinct from v_owner::text || '/k/2.jpg' then
    raise exception 'FAIL: gallery/cover not replaced on re-save';
  end if;

  ----------------------------------------------------------------------------
  -- 3. slug collision -> distinct slug
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_owner, 'role', 'authenticated')::text, true);
  v_idn := public.host_save_experience_draft(
    v_base || jsonb_build_object('title', 'ABC Trek (revised)'));
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  select slug into v_slug2 from public.experiences where id = v_idn;
  if v_slug2 = v_slug1 or v_slug2 is null then
    raise exception 'FAIL: colliding titles produced the same slug (%)', v_slug2;
  end if;

  ----------------------------------------------------------------------------
  -- 4. editing a PUBLISHED row makes a content revision (D1), not a refusal;
  --    the live row is untouched. Full revision flow is in
  --    experience_revision_end_to_end.test.sql.
  update public.experiences
    set status = 'published', cover_image_url = 'https://e.test/c.webp'
  where id = v_idn;
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_owner, 'role', 'authenticated')::text, true);
  declare
    v_rev_id uuid;
  begin
    v_rev_id := public.host_save_experience_draft(
      v_base || jsonb_build_object('id', v_idn::text, 'title', 'ABC via revision'));
    if v_rev_id = v_idn then
      raise exception 'FAIL: editing a published row mutated it instead of making a revision';
    end if;
    if (select revision_of from public.experiences where id = v_rev_id) is distinct from v_idn then
      raise exception 'FAIL: revision row not linked to its live parent';
    end if;
    if (select title from public.experiences where id = v_idn) = 'ABC via revision' then
      raise exception 'FAIL: the live published row was changed by the edit';
    end if;
  end;
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);

  ----------------------------------------------------------------------------
  -- 5. non-owner refused
  v_raised := false;
  begin
    perform set_config('request.jwt.claims',
      json_build_object('sub', v_other, 'role', 'authenticated')::text, true);
    perform public.host_save_experience_draft(
      v_base || jsonb_build_object('id', v_id1::text));
  exception when others then v_raised := true;
  end;
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  if not v_raised then raise exception 'FAIL: a non-owner edited a draft'; end if;

  ----------------------------------------------------------------------------
  -- 6. suspended host refused
  v_raised := false;
  begin
    perform set_config('request.jwt.claims',
      json_build_object('sub', v_susp, 'role', 'authenticated')::text, true);
    perform public.host_save_experience_draft(v_base);
  exception when others then v_raised := true;
  end;
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  if not v_raised then raise exception 'FAIL: a suspended host saved a draft'; end if;

  ----------------------------------------------------------------------------
  -- 7. no title refused
  v_raised := false;
  begin
    perform set_config('request.jwt.claims',
      json_build_object('sub', v_owner, 'role', 'authenticated')::text, true);
    perform public.host_save_experience_draft(v_base - 'title');
  exception when others then v_raised := true;
  end;
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  if not v_raised then raise exception 'FAIL: a titleless draft saved'; end if;

  ----------------------------------------------------------------------------
  -- 8. bad capacity refused
  v_raised := false;
  begin
    perform set_config('request.jwt.claims',
      json_build_object('sub', v_owner, 'role', 'authenticated')::text, true);
    perform public.host_save_experience_draft(
      v_base || jsonb_build_object('capacity', 250));
  exception when others then v_raised := true;
  end;
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  if not v_raised then raise exception 'FAIL: capacity 250 accepted'; end if;

  ----------------------------------------------------------------------------
  -- 9. a draft with no dates gets no departure and does not error
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_owner, 'role', 'authenticated')::text, true);
  v_idn := public.host_save_experience_draft(jsonb_build_object(
    'title', 'Bare draft', 'itinerary', jsonb_build_array()));
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  if exists (select 1 from public.experience_departures where experience_id = v_idn) then
    raise exception 'FAIL: departure created for a draft with no dates';
  end if;

  raise notice 'OK: host_save_experience_draft creates/edits drafts only, with itinerary + departure';
end $$;

rollback;
