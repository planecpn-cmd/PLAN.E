-- Keep only public identity fields directly readable. Complete profiles are
-- available only to their owner, and host details only for approved hosts.
drop policy if exists "Public profiles are readable by everyone" on public.profiles;
create policy "Public profile identities are readable"
  on public.profiles for select to anon, authenticated
  using (true);

revoke all privileges on table public.profiles from anon, authenticated;
grant select (id, full_name, avatar_url)
  on public.profiles to anon, authenticated;
grant update (
  full_name, phone, avatar_url, location, bio, language,
  onboarding_complete, updated_at
) on public.profiles to authenticated;

create or replace function public.get_my_profile()
returns setof public.profiles
language sql
stable
security definer
set search_path = ''
as $$
  select p.*
  from public.profiles p
  where p.id = auth.uid();
$$;

revoke all on function public.get_my_profile() from public, anon;
grant execute on function public.get_my_profile() to authenticated;

create or replace function public.get_public_host_profile(p_user_id uuid)
returns table (
  id uuid,
  full_name text,
  avatar_url text,
  location text,
  bio text,
  created_at timestamptz,
  updated_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    p.id,
    p.full_name,
    p.avatar_url,
    p.location,
    p.bio,
    p.created_at,
    p.updated_at
  from public.profiles p
  join public.host_accounts ha on ha.user_id = p.id
  join public.host_applications app on app.id = ha.application_id
  where p.id = p_user_id
    and ha.is_active
    and ha.suspended_at is null
    and app.status = 'approved'::public.host_app_status;
$$;

revoke all on function public.get_public_host_profile(uuid) from public;
grant execute on function public.get_public_host_profile(uuid) to anon, authenticated;

-- These views are currently unused by the Flutter app. Keep them available to
-- service code, but make underlying RLS explicit and remove all client access.
alter view public.my_plans_upcoming set (security_invoker = true);
alter view public.my_trips_completed set (security_invoker = true);
alter view public.my_trips_cancelled set (security_invoker = true);

revoke all on table
  public.my_plans_upcoming,
  public.my_trips_completed,
  public.my_trips_cancelled
from anon, authenticated;
