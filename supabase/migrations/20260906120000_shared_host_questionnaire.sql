-- Shared eight-step host questionnaire for Flutter and web.
alter table public.host_applications
  drop constraint if exists host_applications_current_step_check;

alter table public.host_applications
  add constraint host_applications_current_step_check
  check (current_step between 1 and 8),
  add column if not exists application_data jsonb not null default '{}'::jsonb;

comment on column public.host_applications.application_data is
  'Canonical v1 host questionnaire payload shared by Flutter and web clients.';

drop policy if exists "Users can edit their own draft host application"
  on public.host_applications;
create policy "Users can edit their own draft host application"
  on public.host_applications for update to authenticated
  using (
    auth.uid() = user_id and
    status in ('draft', 'action_required', 'rejected')
  )
  with check (
    auth.uid() = user_id and
    status in ('draft', 'action_required', 'rejected')
  );
