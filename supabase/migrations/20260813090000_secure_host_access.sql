-- Secure Traveler -> Host authorization boundary.
-- A profile role is descriptive only. Host Mode authorization requires an
-- authenticated session plus an approved, active host_accounts row.

create table public.host_accounts (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  application_id uuid not null unique references public.host_applications(id) on delete restrict,
  is_active boolean not null default true,
  approved_at timestamptz not null default now(),
  suspended_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint host_accounts_suspension_check check (
    (is_active and suspended_at is null) or not is_active
  )
);

create trigger set_host_accounts_updated_at
  before update on public.host_accounts
  for each row execute function public.set_updated_at();

alter table public.host_accounts enable row level security;

create policy "Hosts can view their own host account"
  on public.host_accounts for select to authenticated
  using (auth.uid() = user_id);

revoke all on table public.host_accounts from anon, authenticated;
grant select on table public.host_accounts to authenticated;

create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;

create or replace function private.is_approved_active_host(candidate_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select candidate_user_id is not null and exists (
    select 1
    from public.host_accounts ha
    join public.host_applications app on app.id = ha.application_id
    where ha.user_id = candidate_user_id
      and ha.is_active
      and ha.suspended_at is null
      and app.status = 'approved'::public.host_app_status
  );
$$;

revoke all on function private.is_approved_active_host(uuid) from public, anon;
grant execute on function private.is_approved_active_host(uuid) to authenticated;

create or replace function public.current_host_access()
returns table (
  is_authenticated boolean,
  is_approved boolean,
  is_active boolean,
  application_status text
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    auth.uid() is not null,
    coalesce(app.status = 'approved'::public.host_app_status, false),
    coalesce(ha.is_active and ha.suspended_at is null, false),
    coalesce(app.status::text, 'not_applied')
  from (select auth.uid() as user_id) session
  left join public.host_applications app on app.user_id = session.user_id
  left join public.host_accounts ha
    on ha.user_id = session.user_id and ha.application_id = app.id;
$$;

revoke all on function public.current_host_access() from public, anon;
grant execute on function public.current_host_access() to authenticated;

-- Only a trusted service-role caller may approve/reject applications. The
-- trigger below derives the profile role and Host Mode account server-side.
create or replace function private.sync_host_account_from_application()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status = 'approved'::public.host_app_status then
    insert into public.host_accounts (
      user_id, application_id, is_active, approved_at, suspended_at
    ) values (
      new.user_id, new.id, true, coalesce(new.reviewed_at, now()), null
    )
    on conflict (user_id) do update set
      application_id = excluded.application_id,
      is_active = true,
      approved_at = excluded.approved_at,
      suspended_at = null,
      updated_at = now();

    update public.profiles
       set role = 'host'::public.user_role, updated_at = now()
     where id = new.user_id;
  elsif new.status = 'rejected'::public.host_app_status then
    update public.host_accounts
       set is_active = false,
           suspended_at = coalesce(suspended_at, now()),
           updated_at = now()
     where user_id = new.user_id;

    update public.profiles
       set role = 'traveler'::public.user_role, updated_at = now()
     where id = new.user_id;
  end if;
  return new;
end;
$$;

revoke all on function private.sync_host_account_from_application() from public, anon, authenticated;

create trigger sync_host_account_after_application_review
  after insert or update of status on public.host_applications
  for each row execute function private.sync_host_account_from_application();

-- Backfill any applications approved before this migration.
insert into public.host_accounts (user_id, application_id, is_active, approved_at)
select app.user_id, app.id, true, coalesce(app.reviewed_at, app.updated_at, now())
from public.host_applications app
where app.status = 'approved'::public.host_app_status
on conflict (user_id) do nothing;

-- Replace the broad application policy with operation-specific policies.
drop policy if exists "Users can create and edit draft host applications" on public.host_applications;

create policy "Users can create their own draft host application"
  on public.host_applications for insert to authenticated
  with check (auth.uid() = user_id and status = 'draft'::public.host_app_status);

create policy "Users can edit their own draft host application"
  on public.host_applications for update to authenticated
  using (auth.uid() = user_id and status = 'draft'::public.host_app_status)
  with check (auth.uid() = user_id and status = 'draft'::public.host_app_status);

-- Verification documents are private and scoped to the authenticated user's
-- top-level object folder. Service-role review bypasses these client policies.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'host-documents',
  'host-documents',
  false,
  10485760,
  array['image/jpeg', 'image/png', 'application/pdf']
)
on conflict (id) do update set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy "Applicants can upload their own host documents"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'host-documents' and
    auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Applicants can view their own host documents"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'host-documents' and
    auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Applicants can replace their own host documents"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'host-documents' and
    auth.uid()::text = (storage.foldername(name))[1]
  )
  with check (
    bucket_id = 'host-documents' and
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Existing Host Mode table policies now require the backend-owned active
-- host account, not merely matching a host_id supplied by the frontend.
drop policy if exists "Hosts can manage draft or pending experiences" on public.experiences;
drop policy if exists "Published experiences are readable by anyone" on public.experiences;
create policy "Published experiences and approved host records are readable"
  on public.experiences for select
  using (
    status = 'published'::public.experience_status or
    (auth.uid() = host_id and private.is_approved_active_host(auth.uid()))
  );

create policy "Approved active hosts can manage their experiences"
  on public.experiences for all to authenticated
  using (
    auth.uid() = host_id and private.is_approved_active_host(auth.uid())
  )
  with check (
    auth.uid() = host_id and private.is_approved_active_host(auth.uid())
  );

drop policy if exists "Users can view their own bookings" on public.bookings;
create policy "Travelers and approved hosts can view related bookings"
  on public.bookings for select
  using (
    auth.uid() = user_id or exists (
      select 1 from public.experiences e
      where e.id = experience_id
        and e.host_id = auth.uid()
        and private.is_approved_active_host(auth.uid())
    )
  );

drop policy if exists "Participants readable by booking owner or host" on public.booking_participants;
create policy "Travelers and approved hosts can view participants"
  on public.booking_participants for select
  using (
    exists (
      select 1 from public.bookings b
      where b.id = booking_id
        and (
          b.user_id = auth.uid() or exists (
            select 1 from public.experiences e
            where e.id = b.experience_id
              and e.host_id = auth.uid()
              and private.is_approved_active_host(auth.uid())
          )
        )
    )
  );
