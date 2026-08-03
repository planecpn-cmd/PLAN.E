-- Migration 0003: Profiles table & new user trigger
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text unique,
  avatar_url text,
  location text,
  bio text,
  role user_role not null default 'traveler',
  language text default 'en' check (language in ('en','ne')),
  points int not null default 0,
  onboarding_complete boolean default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger set_profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- Trigger to create profile row automatically when new user signs up in auth.users
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', 'Traveler'),
    new.raw_user_meta_data->>'avatar_url'
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Trigger to prevent client role from changing user role unless admin
create or replace function public.prevent_profile_role_escalation()
returns trigger as $$
begin
  if old.role <> new.role and (current_setting('request.jwt.claims', true)::jsonb->>'role') <> 'service_role' then
    raise exception 'Permission denied: cannot alter profile role directly';
  end if;
  return new;
end;
$$ language plpgsql;

create trigger check_profile_role_update
  before update on public.profiles
  for each row execute function public.prevent_profile_role_escalation();
