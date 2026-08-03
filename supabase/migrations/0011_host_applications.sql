-- Migration 0011: Host Applications
create table public.host_applications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique not null references public.profiles(id) on delete cascade,
  status host_app_status not null default 'draft',
  current_step int not null default 1 check (current_step >= 1 and current_step <= 4),
  category_id uuid references public.categories(id) on delete set null,
  title text,
  description text,
  location text,
  photos text[] default '{}',
  verification_doc_path text,
  submitted_at timestamptz,
  reviewed_at timestamptz,
  reviewer_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger set_host_apps_updated_at
  before update on public.host_applications
  for each row execute function public.set_updated_at();

-- Trigger preventing client role from mutating host_applications.status directly
create or replace function public.prevent_client_host_app_status_change()
returns trigger as $$
begin
  if old.status <> new.status and (current_setting('request.jwt.claims', true)::jsonb->>'role') <> 'service_role' then
    raise exception 'Permission denied: host application status updates are restricted to service role';
  end if;
  return new;
end;
$$ language plpgsql;

create trigger check_host_app_status_update
  before update on public.host_applications
  for each row execute function public.prevent_client_host_app_status_change();
