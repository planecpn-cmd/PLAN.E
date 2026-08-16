-- Migration 0022: per-user rate limit for the generate-itinerary AI edge function.
-- One row per rate_key, upserted in place (no log-per-request growth), so no
-- cron prune job is needed unlike a request-log style rate_limits table.

create table public.ai_rate_limits (
  id uuid primary key default gen_random_uuid(),
  rate_key text not null unique,
  window_start timestamptz not null default now(),
  request_count int not null default 1,
  updated_at timestamptz not null default now()
);

create or replace function public.check_ai_rate_limit(p_key text, p_limit int, p_window_minutes int)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_row public.ai_rate_limits%rowtype;
begin
  insert into public.ai_rate_limits (rate_key, window_start, request_count)
  values (p_key, now(), 0)
  on conflict (rate_key) do nothing;

  select * into v_row from public.ai_rate_limits where rate_key = p_key for update;

  if v_row.window_start < now() - (p_window_minutes || ' minutes')::interval then
    update public.ai_rate_limits set window_start = now(), request_count = 1, updated_at = now()
      where rate_key = p_key;
    return true;
  end if;

  if v_row.request_count >= p_limit then
    return false;
  end if;

  update public.ai_rate_limits set request_count = request_count + 1, updated_at = now()
    where rate_key = p_key;
  return true;
end;
$$;

-- RLS enabled, no policies: service-role/RPC only. Blocks the blanket
-- `grant insert/update/delete to authenticated` in 0016_grants.sql from
-- letting a signed-in user reset their own rate-limit row directly.
alter table public.ai_rate_limits enable row level security;
