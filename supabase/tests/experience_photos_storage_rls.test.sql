-- H1 photo slice: storage RLS on the private experience-photos bucket.
--
-- Path <host_id>/<experience_key>/<file>. Asserts: an approved active host
-- uploads only under their own uid prefix; a suspended / non-host cannot upload
-- even under their own prefix; the owning host reads their objects; another host
-- cannot; a content:manage staff member can; a plain traveler and a staff
-- member without content:manage cannot.

begin;

do $$
declare
  v_hostA uuid := 'c5000000-0000-4000-8000-000000000001';
  v_hostB uuid := 'c5000000-0000-4000-8000-000000000002';
  v_susp  uuid := 'c5000000-0000-4000-8000-000000000003';
  v_mgr   uuid := 'c5000000-0000-4000-8000-000000000004';  -- content:manage
  v_rev   uuid := 'c5000000-0000-4000-8000-000000000005';  -- hosts:review only
  v_trav  uuid := '11111111-1111-4111-8111-000000000001';  -- seed traveler
begin
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);

  insert into auth.users (id, instance_id, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role, aud)
  select u, '00000000-0000-0000-0000-000000000000', u::text || '@ph.test', 'x', now(),
    '{"provider":"email","providers":["email"]}', '{}', now(), now(), 'authenticated', 'authenticated'
  from unnest(array[v_hostA, v_hostB, v_susp, v_mgr, v_rev]) u
  on conflict (id) do nothing;

  insert into public.profiles (id, full_name, role)
  values (v_hostA,'PH A','traveler'), (v_hostB,'PH B','traveler'),
         (v_susp,'PH Susp','traveler'), (v_mgr,'PH Mgr','traveler'),
         (v_rev,'PH Rev','traveler')
  on conflict (id) do update set role = excluded.role;

  insert into public.host_applications (id, user_id, status, current_step, application_data)
  values
    (gen_random_uuid(), v_hostA, 'approved', 8, '{}'::jsonb),
    (gen_random_uuid(), v_hostB, 'approved', 8, '{}'::jsonb),
    (gen_random_uuid(), v_susp,  'approved', 8, '{}'::jsonb)
  on conflict (user_id) do nothing;
  update public.host_accounts set is_active = false, suspended_at = now()
  where user_id = v_susp;

  insert into public.staff_members (user_id, status, scopes)
  values (v_mgr, 'active', array['content:manage']),
         (v_rev, 'active', array['hosts:review'])
  on conflict (user_id) do update set status = excluded.status, scopes = excluded.scopes;

  -- seed an object owned by host A (written here as service_role, bypassing RLS)
  insert into storage.objects (bucket_id, name)
  values ('experience-photos', v_hostA::text || '/exp-1/cover.jpg');
end $$;

-- act-as helpers on storage.objects
create or replace function pg_temp.st_write_blocked(p_user uuid, p_sql text)
returns boolean language plpgsql as $$
begin
  set local role authenticated;
  perform set_config('request.jwt.claims',
    json_build_object('sub', p_user::text, 'role', 'authenticated')::text, true);
  begin
    execute p_sql;
    reset role;
    return false;
  exception when others then
    reset role;
    return true;
  end;
end $$;

create or replace function pg_temp.st_count_as(p_user uuid, p_sql text)
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

do $$
declare
  v_hostA uuid := 'c5000000-0000-4000-8000-000000000001';
  v_hostB uuid := 'c5000000-0000-4000-8000-000000000002';
  v_susp  uuid := 'c5000000-0000-4000-8000-000000000003';
  v_mgr   uuid := 'c5000000-0000-4000-8000-000000000004';
  v_rev   uuid := 'c5000000-0000-4000-8000-000000000005';
  v_trav  uuid := '11111111-1111-4111-8111-000000000001';
  v_read  text := 'select count(*) from storage.objects where bucket_id = ''experience-photos'' and name = '''
                  || v_hostA::text || '/exp-1/cover.jpg''';
begin
  -- uploads
  if pg_temp.st_write_blocked(v_hostA,
       'insert into storage.objects (bucket_id, name) values (''experience-photos'', '''
       || v_hostA::text || '/exp-2/a.jpg'')') then
    raise exception 'FAIL: approved host A cannot upload under its own prefix';
  end if;

  if not pg_temp.st_write_blocked(v_hostA,
       'insert into storage.objects (bucket_id, name) values (''experience-photos'', '''
       || v_hostB::text || '/exp-9/x.jpg'')') then
    raise exception 'FAIL: host A uploaded under host B''s prefix';
  end if;

  if not pg_temp.st_write_blocked(v_susp,
       'insert into storage.objects (bucket_id, name) values (''experience-photos'', '''
       || v_susp::text || '/exp/x.jpg'')') then
    raise exception 'FAIL: a suspended host uploaded an experience photo';
  end if;

  if not pg_temp.st_write_blocked(v_trav,
       'insert into storage.objects (bucket_id, name) values (''experience-photos'', '''
       || v_trav::text || '/x.jpg'')') then
    raise exception 'FAIL: a non-host traveler uploaded an experience photo';
  end if;

  -- reads of host A's seeded object
  if pg_temp.st_count_as(v_hostA, v_read) <> 1 then
    raise exception 'FAIL: host A cannot read its own experience photo';
  end if;
  if pg_temp.st_count_as(v_hostB, v_read) <> 0 then
    raise exception 'FAIL: host B can read host A''s experience photo';
  end if;
  if pg_temp.st_count_as(v_mgr, v_read) <> 1 then
    raise exception 'FAIL: a content:manage reviewer cannot read the photo';
  end if;
  if pg_temp.st_count_as(v_rev, v_read) <> 0 then
    raise exception 'FAIL: a hosts:review staff member (no content:manage) read the photo';
  end if;
  if pg_temp.st_count_as(v_trav, v_read) <> 0 then
    raise exception 'FAIL: a plain traveler read host A''s experience photo';
  end if;

  raise notice 'OK: experience-photos storage RLS: own-prefix upload, owner + content:manage read only';
end $$;

rollback;
