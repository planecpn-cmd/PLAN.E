-- Migration 0021: Remote config / feature flags / OTA update infrastructure
-- See docs/OTA_UPDATES_PLAN.md for the full design.

create table public.app_config (
  key text primary key,
  value jsonb not null,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id)
);

create table public.feature_flags (
  key text primary key,
  enabled boolean not null default false,
  rollout_percent int not null default 100 check (rollout_percent between 0 and 100),
  platforms text[] not null default array['ios','android','windows','web'],
  min_app_version text,
  max_app_version text,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id)
);

create table public.remote_content (
  slot text primary key,
  schema_version int not null default 1,
  payload jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id)
);

create table public.app_versions (
  platform text primary key,
  min_supported_version text not null,
  latest_version text not null,
  maintenance_mode boolean not null default false,
  maintenance_message text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.config_audit_log (
  id uuid primary key default gen_random_uuid(),
  table_name text not null,
  row_key text not null,
  old_value jsonb,
  new_value jsonb,
  changed_by uuid references public.profiles(id),
  changed_at timestamptz not null default now()
);

-- Shared updated_at trigger, same as every other table (see 0001_extensions.sql)
create trigger set_app_config_updated_at
  before update on public.app_config
  for each row execute function public.set_updated_at();

create trigger set_feature_flags_updated_at
  before update on public.feature_flags
  for each row execute function public.set_updated_at();

create trigger set_remote_content_updated_at
  before update on public.remote_content
  for each row execute function public.set_updated_at();

create trigger set_app_versions_updated_at
  before update on public.app_versions
  for each row execute function public.set_updated_at();

-------------------------------------------------------
-- Admin check helper — no equivalent existed in the
-- schema before this (0009_trip_tools.sql only has
-- is_trip_member()). Mirrors handle_new_user()'s
-- security definer style from 0003_profiles_trigger.sql.
-------------------------------------------------------
create or replace function public.is_admin()
returns boolean as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$ language sql security definer stable;

-------------------------------------------------------
-- Audit trigger — records every insert/update/delete on
-- the four config tables into config_audit_log.
-------------------------------------------------------
create or replace function public.log_config_change()
returns trigger as $$
declare
  row_json jsonb;
begin
  row_json := to_jsonb(case when TG_OP = 'DELETE' then old else new end);
  insert into public.config_audit_log (table_name, row_key, old_value, new_value, changed_by)
  values (
    TG_TABLE_NAME,
    coalesce(row_json ->> 'key', row_json ->> 'slot', row_json ->> 'platform'),
    case when TG_OP in ('UPDATE','DELETE') then to_jsonb(old) else null end,
    case when TG_OP in ('INSERT','UPDATE') then to_jsonb(new) else null end,
    auth.uid()
  );
  return coalesce(new, old);
end;
$$ language plpgsql security definer;

create trigger audit_app_config
  after insert or update or delete on public.app_config
  for each row execute function public.log_config_change();

create trigger audit_feature_flags
  after insert or update or delete on public.feature_flags
  for each row execute function public.log_config_change();

create trigger audit_remote_content
  after insert or update or delete on public.remote_content
  for each row execute function public.log_config_change();

create trigger audit_app_versions
  after insert or update or delete on public.app_versions
  for each row execute function public.log_config_change();

-------------------------------------------------------
-- RLS — every table default deny. 0016_grants.sql grants
-- insert/update/delete on ALL tables (including future
-- ones, via alter default privileges) to `authenticated`,
-- so RLS is the only thing stopping a normal signed-up
-- user from rewriting flags/kill switches. Non-negotiable.
-------------------------------------------------------
alter table public.app_config enable row level security;
alter table public.feature_flags enable row level security;
alter table public.remote_content enable row level security;
alter table public.app_versions enable row level security;
alter table public.config_audit_log enable row level security;

-- Readable by anyone, including anon (pre-auth force-update gate needs this).
create policy "Config readable by everyone"
  on public.app_config for select
  using (true);

create policy "Feature flags readable by everyone"
  on public.feature_flags for select
  using (true);

create policy "Remote content readable by everyone"
  on public.remote_content for select
  using (true);

create policy "App versions readable by everyone"
  on public.app_versions for select
  using (true);

-- Writes restricted to admins only.
create policy "Admins can manage app config"
  on public.app_config for all
  using (public.is_admin())
  with check (public.is_admin());

create policy "Admins can manage feature flags"
  on public.feature_flags for all
  using (public.is_admin())
  with check (public.is_admin());

create policy "Admins can manage remote content"
  on public.remote_content for all
  using (public.is_admin())
  with check (public.is_admin());

create policy "Admins can manage app versions"
  on public.app_versions for all
  using (public.is_admin())
  with check (public.is_admin());

-- Audit log: admins only, read-only from the client (writes only ever
-- come from the trigger, which runs as security definer).
create policy "Admins can read config audit log"
  on public.config_audit_log for select
  using (public.is_admin());
