-- Paid-provider rate limits are server controls, not client-callable RPCs.

create or replace function public.check_ai_rate_limit(
  p_key text,
  p_limit int,
  p_window_minutes int
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_row public.ai_rate_limits%rowtype;
begin
  if p_key is null or char_length(btrim(p_key)) not between 1 and 200 or
      p_limit not between 1 and 100000 or
      p_window_minutes not between 1 and 43200 then
    raise exception using
      errcode = '22023',
      message = 'Invalid rate limit parameters';
  end if;

  insert into public.ai_rate_limits (rate_key, window_start, request_count)
  values (p_key, now(), 0)
  on conflict (rate_key) do nothing;

  select * into v_row
  from public.ai_rate_limits
  where rate_key = p_key
  for update;

  if v_row.window_start < now() - make_interval(mins => p_window_minutes) then
    update public.ai_rate_limits
    set window_start = now(), request_count = 1, updated_at = now()
    where rate_key = p_key;
    return true;
  end if;

  if v_row.request_count >= p_limit then
    return false;
  end if;

  update public.ai_rate_limits
  set request_count = request_count + 1, updated_at = now()
  where rate_key = p_key;
  return true;
end;
$$;

revoke all on function public.check_ai_rate_limit(text, int, int)
  from public, anon, authenticated;
grant execute on function public.check_ai_rate_limit(text, int, int)
  to service_role;
