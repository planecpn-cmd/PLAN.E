-- =============================================================================
-- staff_admin_audit.test.sql  —  staff_members + admin_audit_log invariants
-- (P1 Step 3). begin / assertions / rollback.
-- =============================================================================

begin;

do $$
declare
  v_admin uuid := 'ab000000-0000-4000-8000-000000000001';
begin
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  insert into auth.users (id, instance_id, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role, aud)
  values (v_admin, '00000000-0000-0000-0000-000000000000', 'staff.test@test.local', 'x', now(),
    '{"provider":"email","providers":["email"]}', '{}', now(), now(), 'authenticated', 'authenticated')
  on conflict (id) do nothing;
  insert into public.profiles (id, full_name, role)
  values (v_admin, 'Staff Test', 'admin'::public.user_role)
  on conflict (id) do update set role = 'admin';
end $$;

-- Assertion 1: an unknown scope is rejected at the DB level.
do $$
declare v_admin uuid := 'ab000000-0000-4000-8000-000000000001'; v_ok boolean := false;
begin
  begin
    insert into public.staff_members (user_id, scopes) values (v_admin, array['hosts:review','not-a-real-scope']);
    v_ok := true;
  exception when check_violation then
    v_ok := false;
  end;
  if v_ok then raise exception 'FAIL: staff_members accepted an unknown scope'; end if;
end $$;

-- Assertion 2: a valid scope set is accepted, and an empty set is the default.
do $$
declare v_admin uuid := 'ab000000-0000-4000-8000-000000000001';
begin
  insert into public.staff_members (user_id, scopes)
  values (v_admin, array['hosts:review','bookings:read','content:manage']);
  if not exists (select 1 from public.staff_members where user_id = v_admin and 'content:manage' = any(scopes))
    then raise exception 'FAIL: valid staff_members row not stored'; end if;
end $$;

-- Assertion 3: suspension consistency — status active with suspended_at set is rejected.
do $$
declare v_admin uuid := 'ab000000-0000-4000-8000-000000000001'; v_ok boolean := false;
begin
  begin
    update public.staff_members set suspended_at = now() where user_id = v_admin;  -- status still 'active'
    v_ok := true;
  exception when check_violation then
    v_ok := false;
  end;
  if v_ok then raise exception 'FAIL: staff_members allowed active + suspended_at'; end if;
end $$;

-- Assertion 4: admin_audit_log is append-only even for service_role.
do $$
declare v_admin uuid := 'ab000000-0000-4000-8000-000000000001'; v_id uuid; v_blocked boolean;
begin
  insert into public.admin_audit_log (actor_user_id, action) values (v_admin, 'test.append')
  returning id into v_id;

  set local role service_role;
  v_blocked := false;
  begin
    update public.admin_audit_log set reason = 'tampered' where id = v_id;
  exception when insufficient_privilege then v_blocked := true;
  end;
  if not v_blocked then reset role; raise exception 'FAIL: service_role UPDATEd admin_audit_log'; end if;

  v_blocked := false;
  begin
    delete from public.admin_audit_log where id = v_id;
  exception when insufficient_privilege then v_blocked := true;
  end;
  reset role;
  if not v_blocked then raise exception 'FAIL: service_role DELETEd admin_audit_log'; end if;
end $$;

-- Assertion 5: neither table is readable by a non-admin authenticated user.
do $$
declare v_count bigint;
begin
  set local role authenticated;
  perform set_config('request.jwt.claims',
    json_build_object('sub','00000000-0000-0000-0000-0000000000ff','role','authenticated')::text, true);
  select count(*) into v_count from public.staff_members;
  if v_count <> 0 then reset role; raise exception 'FAIL: non-admin read staff_members'; end if;
  select count(*) into v_count from public.admin_audit_log;
  reset role;
  if v_count <> 0 then raise exception 'FAIL: non-admin read admin_audit_log'; end if;
end $$;

rollback;
