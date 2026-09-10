-- N1: experience_reviews RLS + the content:decide scope.
--
-- Mirrors host_review_rls.test.sql. content:manage reads the review history;
-- content:decide alone does not; hosts:review does not; traveler / anon do not.
-- No client may INSERT a review row (no write policy). The scope CHECK accepts
-- content:decide and still rejects unknown scopes.

begin;

do $$
declare
  v_mgr    uuid := 'd1000000-0000-4000-8000-000000000001';  -- content:manage
  v_dec    uuid := 'd1000000-0000-4000-8000-000000000002';  -- content:manage + content:decide
  v_deconly uuid := 'd1000000-0000-4000-8000-000000000003'; -- content:decide only
  v_hrev   uuid := 'd1000000-0000-4000-8000-000000000004';  -- hosts:review only
  v_trav   uuid := '11111111-1111-4111-8111-000000000001';  -- seed traveler
  v_host   uuid := 'd1000000-0000-4000-8000-000000000005';  -- approved host, owns the experience
  v_cat    uuid;
  v_region uuid;
  v_exp    uuid := 'd1e00000-0000-4000-8000-000000000001';
begin
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  select id into v_cat    from public.categories order by created_at limit 1;
  select id into v_region from public.regions    order by created_at limit 1;

  insert into auth.users (id, instance_id, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role, aud)
  select u, '00000000-0000-0000-0000-000000000000', u::text || '@er.test', 'x', now(),
    '{"provider":"email","providers":["email"]}', '{}', now(), now(), 'authenticated', 'authenticated'
  from unnest(array[v_mgr, v_dec, v_deconly, v_hrev, v_host]) u
  on conflict (id) do nothing;

  insert into public.profiles (id, full_name, role)
  values (v_mgr,'ER Mgr','traveler'), (v_dec,'ER Dec','traveler'),
         (v_deconly,'ER DecOnly','traveler'), (v_hrev,'ER HRev','traveler'),
         (v_host,'ER Host','traveler')
  on conflict (id) do update set role = excluded.role;

  insert into public.staff_members (user_id, status, scopes)
  values
    (v_mgr,    'active', array['content:manage']),
    (v_dec,    'active', array['content:manage','content:decide']),
    (v_deconly,'active', array['content:decide']),
    (v_hrev,   'active', array['hosts:review'])
  on conflict (user_id) do update set status = excluded.status, scopes = excluded.scopes;

  insert into public.host_applications (id, user_id, status, current_step, application_data)
  values (gen_random_uuid(), v_host, 'approved', 8, '{}'::jsonb)
  on conflict (user_id) do nothing;

  insert into public.experiences
    (id, host_id, category_id, region_id, title, slug, description, location_name,
     cover_image_url, price_paisa, status)
  values (v_exp, v_host, v_cat, v_region, 'ER Listing', 'er-listing',
    'Pending review.', 'Kaski, Nepal', 'https://e.test/c.webp', 500000, 'pending_review');

  -- a review row as the admin backend would write it (service_role)
  insert into public.experience_reviews
    (experience_id, reviewer_id, from_status, to_status, decision, note)
  values (v_exp, v_mgr, 'pending_review', 'pending_review', 'under_review', 'taking a look');
end $$;

create or replace function pg_temp.count_as(p_user uuid, p_sql text)
returns bigint language plpgsql as $$
declare v bigint;
begin
  set local role authenticated;
  perform set_config('request.jwt.claims',
    json_build_object('sub', p_user::text, 'role', 'authenticated')::text, true);
  begin execute p_sql into v; exception when others then v := 0; end;
  reset role;
  return coalesce(v, 0);
end $$;

create or replace function pg_temp.write_blocked(p_user uuid, p_sql text)
returns boolean language plpgsql as $$
begin
  set local role authenticated;
  perform set_config('request.jwt.claims',
    json_build_object('sub', p_user::text, 'role', 'authenticated')::text, true);
  begin execute p_sql; reset role; return false;
  exception when others then reset role; return true; end;
end $$;

do $$
declare
  v_mgr    uuid := 'd1000000-0000-4000-8000-000000000001';
  v_dec    uuid := 'd1000000-0000-4000-8000-000000000002';
  v_deconly uuid := 'd1000000-0000-4000-8000-000000000003';
  v_hrev   uuid := 'd1000000-0000-4000-8000-000000000004';
  v_trav   uuid := '11111111-1111-4111-8111-000000000001';
  v_exp    uuid := 'd1e00000-0000-4000-8000-000000000001';
  v_ins    text := 'insert into public.experience_reviews (experience_id, reviewer_id, decision) '
                   || 'values (''' || 'd1e00000-0000-4000-8000-000000000001'' , auth.uid(), ''approve'')';
begin
  -- reads
  if pg_temp.count_as(v_mgr, 'select count(*) from public.experience_reviews') < 1 then
    raise exception 'FAIL: content:manage cannot read experience review history';
  end if;
  if pg_temp.count_as(v_dec, 'select count(*) from public.experience_reviews') < 1 then
    raise exception 'FAIL: a content:manage+decide reviewer cannot read review history';
  end if;
  if pg_temp.count_as(v_deconly, 'select count(*) from public.experience_reviews') <> 0 then
    raise exception 'FAIL: content:decide alone can read review history';
  end if;
  if pg_temp.count_as(v_hrev, 'select count(*) from public.experience_reviews') <> 0 then
    raise exception 'FAIL: hosts:review can read experience review history';
  end if;
  if pg_temp.count_as(v_trav, 'select count(*) from public.experience_reviews') <> 0 then
    raise exception 'FAIL: a plain traveler can read experience review history';
  end if;

  -- no client write path
  if not pg_temp.write_blocked(v_mgr, v_ins) then
    raise exception 'FAIL: content:manage inserted a review row via direct JWT';
  end if;
  if not pg_temp.write_blocked(v_dec, v_ins) then
    raise exception 'FAIL: content:decide inserted a review row via direct JWT';
  end if;

  raise notice 'OK: experience_reviews readable by content:manage only, no client write';
end $$;

-- The scope CHECK: content:decide already stored above for v_deconly, so it is
-- accepted. Confirm an unknown scope is still rejected (as the trusted role).
do $$
begin
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  begin
    update public.staff_members
      set scopes = array['content:teleport']
    where user_id = 'd1000000-0000-4000-8000-000000000003';  -- v_deconly
    raise exception 'FAIL: staff_members_scopes_known accepted an unknown scope';
  exception when check_violation then null;
  end;
  raise notice 'OK: content:decide is a known scope; unknown scopes still rejected';
end $$;

rollback;
