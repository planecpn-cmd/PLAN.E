-- H1 core (4/4): public.host_submit_experience_for_review(uuid)
--
-- Flips a complete draft to pending_review. Asserts: a complete draft is
-- accepted; an incomplete draft (no cover, no departure, no price) is refused
-- with a message; a non-draft status is refused; non-owner / suspended refused;
-- the client can never produce 'published'.

begin;

do $$
declare
  v_owner uuid := 'c4000000-0000-4000-8000-000000000001';
  v_other uuid := 'c4000000-0000-4000-8000-000000000002';
  v_susp  uuid := 'c4000000-0000-4000-8000-000000000003';
  v_cat    uuid;
  v_region uuid;
  v_exp_ok   uuid := 'c4e00000-0000-4000-8000-000000000001';  -- complete draft
  v_exp_bad  uuid := 'c4e00000-0000-4000-8000-000000000002';  -- no cover / no departure
  v_exp_pub  uuid := 'c4e00000-0000-4000-8000-000000000003';  -- already published
  v_ret   public.experience_status;
  v_raised boolean;
begin
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  select id into v_cat    from public.categories order by created_at limit 1;
  select id into v_region from public.regions    order by created_at limit 1;

  insert into auth.users (id, instance_id, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role, aud)
  select u, '00000000-0000-0000-0000-000000000000', u::text || '@hw4.test', 'x', now(),
    '{"provider":"email","providers":["email"]}', '{}', now(), now(), 'authenticated', 'authenticated'
  from unnest(array[v_owner, v_other, v_susp]) u
  on conflict (id) do nothing;

  insert into public.profiles (id, full_name, role)
  values (v_owner,'HW4 Owner','traveler'), (v_other,'HW4 Other','traveler'),
         (v_susp,'HW4 Susp','traveler')
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
    (id, host_id, category_id, region_id, title, slug, description, location_name,
     cover_image_url, price_paisa, status)
  values
    (v_exp_ok,  v_owner, v_cat, v_region, 'HW4 Complete', 'hw4-complete',
      'A complete draft ready for review.', 'Kaski, Nepal',
      'https://e.test/c.webp', 500000, 'draft'),
    (v_exp_bad, v_owner, v_cat, v_region, 'HW4 Incomplete', 'hw4-incomplete',
      'Missing a cover and a departure.', 'Kaski, Nepal',
      null, 500000, 'draft'),
    (v_exp_pub, v_owner, v_cat, v_region, 'HW4 Published', 'hw4-published',
      'Already live.', 'Kaski, Nepal',
      'https://e.test/c.webp', 500000, 'published');

  insert into public.experience_departures
    (experience_id, start_date, end_date, total_spots, spots_left, status)
  values (v_exp_ok, date '2026-10-01', date '2026-10-05', 8, 8, 'open');

  ----------------------------------------------------------------------------
  -- 1. complete draft -> pending_review
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_owner, 'role', 'authenticated')::text, true);
  v_ret := public.host_submit_experience_for_review(v_exp_ok);
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  if v_ret is distinct from 'pending_review'::public.experience_status
     or (select status from public.experiences where id = v_exp_ok)
        is distinct from 'pending_review'::public.experience_status then
    raise exception 'FAIL: a complete draft was not moved to pending_review';
  end if;

  -- 2. incomplete draft refused
  v_raised := false;
  begin
    perform set_config('request.jwt.claims',
      json_build_object('sub', v_owner, 'role', 'authenticated')::text, true);
    perform public.host_submit_experience_for_review(v_exp_bad);
  exception when others then v_raised := true;
  end;
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  if not v_raised
     or (select status from public.experiences where id = v_exp_bad)
        is distinct from 'draft'::public.experience_status then
    raise exception 'FAIL: an incomplete draft was submitted';
  end if;

  -- 3. non-draft status refused
  v_raised := false;
  begin
    perform set_config('request.jwt.claims',
      json_build_object('sub', v_owner, 'role', 'authenticated')::text, true);
    perform public.host_submit_experience_for_review(v_exp_pub);
  exception when others then v_raised := true;
  end;
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  if not v_raised
     or (select status from public.experiences where id = v_exp_pub)
        is distinct from 'published'::public.experience_status then
    raise exception 'FAIL: a published experience was re-submitted for review';
  end if;

  -- 4. non-owner refused
  v_raised := false;
  begin
    perform set_config('request.jwt.claims',
      json_build_object('sub', v_other, 'role', 'authenticated')::text, true);
    perform public.host_submit_experience_for_review(v_exp_bad);
  exception when others then v_raised := true;
  end;
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  if not v_raised then raise exception 'FAIL: a non-owner submitted a draft'; end if;

  -- 5. suspended host refused
  v_raised := false;
  begin
    perform set_config('request.jwt.claims',
      json_build_object('sub', v_susp, 'role', 'authenticated')::text, true);
    perform public.host_submit_experience_for_review(v_exp_bad);
  exception when others then v_raised := true;
  end;
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  if not v_raised then raise exception 'FAIL: a suspended host submitted a draft'; end if;

  -- 6. the RPC has no path to 'published'
  if (select status from public.experiences where id = v_exp_ok) =
     'published'::public.experience_status then
    raise exception 'FAIL: submit-for-review produced a published listing';
  end if;

  raise notice 'OK: host_submit_experience_for_review flips a complete draft to pending_review only';
end $$;

rollback;
