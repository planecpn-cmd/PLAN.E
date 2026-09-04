begin;

do $$
declare
  v_user_a uuid := 'fb000000-0000-4000-8000-000000000001';
  v_user_b uuid := 'fb000000-0000-4000-8000-000000000002';
  v_profile_count integer;
  v_phone text;
  v_role public.user_role;
  v_private_select_blocked boolean := false;
  v_role_update_blocked boolean := false;
begin
  insert into auth.users (
    id, instance_id, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role, aud
  ) values
    (
      v_user_a, '00000000-0000-0000-0000-000000000000',
      'profile-a@example.test', 'encrypted', now(),
      '{"provider":"email","providers":["email"]}',
      '{"role":"admin","user_role":"admin"}',
      now(), now(), 'authenticated', 'authenticated'
    ),
    (
      v_user_b, '00000000-0000-0000-0000-000000000000',
      'profile-b@example.test', 'encrypted', now(),
      '{"provider":"email","providers":["email"]}', '{}',
      now(), now(), 'authenticated', 'authenticated'
    )
  on conflict (id) do nothing;

  update public.profiles
  set phone = case id
    when v_user_a then '9800000001'
    when v_user_b then '9800000002'
  end
  where id in (v_user_a, v_user_b);

  if has_column_privilege('anon', 'public.profiles', 'phone', 'select') or
     has_column_privilege('authenticated', 'public.profiles', 'phone', 'select') then
    raise exception 'FAIL: private profile columns remain directly readable';
  end if;
  if not has_column_privilege('anon', 'public.profiles', 'full_name', 'select') then
    raise exception 'FAIL: public display names are no longer readable';
  end if;
  if has_function_privilege('anon', 'public.get_my_profile()', 'execute') then
    raise exception 'FAIL: anonymous users can execute get_my_profile';
  end if;
  if has_table_privilege('authenticated', 'public.my_plans_upcoming', 'select') or
     has_table_privilege('authenticated', 'public.my_trips_completed', 'select') or
     has_table_privilege('authenticated', 'public.my_trips_cancelled', 'select') then
    raise exception 'FAIL: client roles retain access to booking views';
  end if;
  if has_column_privilege('authenticated', 'public.profiles', 'role', 'update') or
     has_table_privilege('authenticated', 'public.host_accounts', 'insert') or
     has_table_privilege('authenticated', 'public.host_accounts', 'update') or
     has_table_privilege('authenticated', 'public.host_accounts', 'delete') then
    raise exception 'FAIL: client roles retain an authority-escalation grant';
  end if;

  set local role authenticated;
  perform set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', v_user_a,
      'role', 'authenticated',
      'user_metadata', json_build_object('role', 'admin', 'user_role', 'admin')
    )::text,
    true
  );

  if public.is_admin() then
    raise exception 'FAIL: forged user metadata granted admin authority';
  end if;

  begin
    update public.profiles set role = 'admin' where id = v_user_a;
  exception when insufficient_privilege then
    v_role_update_blocked := true;
  end;
  select role into v_role from public.get_my_profile();
  if not v_role_update_blocked or v_role <> 'traveler'::public.user_role then
    raise exception 'FAIL: authenticated user escalated their profile role';
  end if;

  select count(*), max(phone)
  into v_profile_count, v_phone
  from public.get_my_profile();
  if v_profile_count <> 1 or v_phone <> '9800000001' then
    raise exception 'FAIL: get_my_profile did not return only the caller profile';
  end if;

  begin
    perform phone from public.profiles where id = v_user_b;
  exception when insufficient_privilege then
    v_private_select_blocked := true;
  end;
  if not v_private_select_blocked then
    raise exception 'FAIL: authenticated user directly selected a private phone';
  end if;
end $$;

rollback;
