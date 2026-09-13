-- H1 core (1/4): public.host_set_experience_paused(uuid, boolean)
--
-- The only client path to toggle a listing published <-> paused. Asserts:
--   owner (approved, active) can pause a published listing and resume a paused
--   one; non-owner approved host cannot; suspended owner cannot; a wrong-status
--   transition is refused; unauthenticated is refused.

begin;

do $$
declare
  v_owner  uuid := 'c1000000-0000-4000-8000-000000000001';  -- approved active host
  v_other  uuid := 'c1000000-0000-4000-8000-000000000002';  -- approved active host, not the owner
  v_susp   uuid := 'c1000000-0000-4000-8000-000000000003';  -- approved then suspended
  v_trav   uuid := '11111111-1111-4111-8111-000000000001';  -- seed traveler, not a host
  v_cat    uuid;
  v_region uuid;
  v_exp_pub   uuid := 'c1e00000-0000-4000-8000-000000000001';
  v_exp_draft uuid := 'c1e00000-0000-4000-8000-000000000002';
  v_exp_susp  uuid := 'c1e00000-0000-4000-8000-000000000003';
  v_raised boolean;
  v_status public.experience_status;
begin
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  select id into v_cat    from public.categories order by created_at limit 1;
  select id into v_region from public.regions    order by created_at limit 1;

  insert into auth.users (id, instance_id, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role, aud)
  select u, '00000000-0000-0000-0000-000000000000', u::text || '@hw.test', 'x', now(),
    '{"provider":"email","providers":["email"]}', '{}', now(), now(), 'authenticated', 'authenticated'
  from unnest(array[v_owner, v_other, v_susp]) u
  on conflict (id) do nothing;

  insert into public.profiles (id, full_name, role)
  values (v_owner, 'HW Owner', 'traveler'), (v_other, 'HW Other', 'traveler'),
         (v_susp, 'HW Susp', 'traveler')
  on conflict (id) do update set role = excluded.role;

  -- approved applications -> sync trigger creates host_accounts + sets role=host
  insert into public.host_applications (id, user_id, status, current_step, application_data)
  values
    (gen_random_uuid(), v_owner, 'approved', 8, '{}'::jsonb),
    (gen_random_uuid(), v_other, 'approved', 8, '{}'::jsonb),
    (gen_random_uuid(), v_susp,  'approved', 8, '{}'::jsonb)
  on conflict (user_id) do nothing;

  update public.host_accounts
    set is_active = false, suspended_at = now()
  where user_id = v_susp;

  insert into public.experiences
    (id, host_id, category_id, region_id, title, slug, cover_image_url,
     price_paisa, status)
  values
    (v_exp_pub,   v_owner, v_cat, v_region, 'HW Published', 'hw-published',
      'https://example.test/c.webp', 500000, 'published'),
    (v_exp_draft, v_owner, v_cat, v_region, 'HW Draft', 'hw-draft',
      null, 500000, 'draft'),
    (v_exp_susp,  v_susp,  v_cat, v_region, 'HW Susp Pub', 'hw-susp-pub',
      'https://example.test/c.webp', 500000, 'published');

  ----------------------------------------------------------------------------
  -- 1. owner pauses the published listing
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_owner, 'role', 'authenticated')::text, true);
  v_status := public.host_set_experience_paused(v_exp_pub, true);
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  if v_status is distinct from 'paused'::public.experience_status
     or (select status from public.experiences where id = v_exp_pub)
        is distinct from 'paused'::public.experience_status then
    raise exception 'FAIL: owner could not pause a published listing';
  end if;

  -- 2. owner resumes it
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_owner, 'role', 'authenticated')::text, true);
  v_status := public.host_set_experience_paused(v_exp_pub, false);
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  if v_status is distinct from 'published'::public.experience_status then
    raise exception 'FAIL: owner could not resume a paused listing';
  end if;

  -- 3. wrong status: cannot pause a draft
  v_raised := false;
  begin
    perform set_config('request.jwt.claims',
      json_build_object('sub', v_owner, 'role', 'authenticated')::text, true);
    perform public.host_set_experience_paused(v_exp_draft, true);
  exception when others then v_raised := true;
  end;
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  if not v_raised then
    raise exception 'FAIL: pausing a draft experience was allowed';
  end if;

  -- 4. non-owner approved host cannot pause someone else's listing
  v_raised := false;
  begin
    perform set_config('request.jwt.claims',
      json_build_object('sub', v_other, 'role', 'authenticated')::text, true);
    perform public.host_set_experience_paused(v_exp_pub, true);
  exception when others then v_raised := true;
  end;
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  if not v_raised then
    raise exception 'FAIL: a non-owner host paused another host''s listing';
  end if;

  -- 5. suspended host cannot pause their own listing
  v_raised := false;
  begin
    perform set_config('request.jwt.claims',
      json_build_object('sub', v_susp, 'role', 'authenticated')::text, true);
    perform public.host_set_experience_paused(v_exp_susp, true);
  exception when others then v_raised := true;
  end;
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  if not v_raised then
    raise exception 'FAIL: a suspended host paused their own listing';
  end if;

  -- 6. a plain traveler (not a host) is refused
  v_raised := false;
  begin
    perform set_config('request.jwt.claims',
      json_build_object('sub', v_trav, 'role', 'authenticated')::text, true);
    perform public.host_set_experience_paused(v_exp_pub, true);
  exception when others then v_raised := true;
  end;
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  if not v_raised then
    raise exception 'FAIL: a non-host traveler paused a listing';
  end if;

  -- 7. unauthenticated is refused
  v_raised := false;
  begin
    perform set_config('request.jwt.claims', '{"role":"anon"}', true);
    perform public.host_set_experience_paused(v_exp_pub, true);
  exception when others then v_raised := true;
  end;
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  if not v_raised then
    raise exception 'FAIL: an unauthenticated caller paused a listing';
  end if;

  raise notice 'OK: host_set_experience_paused enforces owner + active + status';
end $$;

rollback;
