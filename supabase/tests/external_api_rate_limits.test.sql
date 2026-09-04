begin;

do $$
declare
  v_key text := 'test:phase-1:' || gen_random_uuid()::text;
  v_other_key text := 'test:phase-2:' || gen_random_uuid()::text;
begin
  if has_function_privilege(
      'anon',
      'public.check_ai_rate_limit(text,integer,integer)',
      'EXECUTE'
    ) or has_function_privilege(
      'authenticated',
      'public.check_ai_rate_limit(text,integer,integer)',
      'EXECUTE'
    ) or not has_function_privilege(
      'service_role',
      'public.check_ai_rate_limit(text,integer,integer)',
      'EXECUTE'
    ) then
    raise exception 'FAIL: rate limit RPC privileges are unsafe';
  end if;

  begin
    perform public.check_ai_rate_limit('', 1, 1);
    raise exception 'FAIL: empty rate limit key was accepted';
  exception when invalid_parameter_value then null;
  end;

  begin
    perform public.check_ai_rate_limit(v_key, 0, 1);
    raise exception 'FAIL: invalid rate limit was accepted';
  exception when invalid_parameter_value then null;
  end;

  begin
    perform public.check_ai_rate_limit(v_key, 1, 0);
    raise exception 'FAIL: invalid rate limit window was accepted';
  exception when invalid_parameter_value then null;
  end;

  if not public.check_ai_rate_limit(v_key, 2, 60)
    or not public.check_ai_rate_limit(v_key, 2, 60)
    or public.check_ai_rate_limit(v_key, 2, 60)
  then
    raise exception 'FAIL: atomic rate limit threshold is incorrect';
  end if;

  if not public.check_ai_rate_limit(v_other_key || ':user-hour', 1, 60)
    or not public.check_ai_rate_limit(v_other_key || ':user-day', 1, 1440)
    or not public.check_ai_rate_limit(v_other_key || ':global-hour', 1, 60)
    or not public.check_ai_rate_limit(v_other_key || ':global-day', 1, 1440)
    or public.check_ai_rate_limit(v_other_key || ':global-day', 1, 1440)
  then
    raise exception 'FAIL: layered quota keys are not independently enforced';
  end if;
end $$;

rollback;
