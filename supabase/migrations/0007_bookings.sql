-- Migration 0007: Bookings & Participants
create table public.bookings (
  id uuid primary key default gen_random_uuid(),
  booking_ref text unique not null,
  user_id uuid not null references public.profiles(id) on delete cascade,
  experience_id uuid not null references public.experiences(id) on delete restrict,
  departure_id uuid not null references public.experience_departures(id) on delete restrict,
  adults int not null check (adults >= 1),
  children int not null default 0 check (children >= 0),
  addons jsonb default '[]'::jsonb,
  contact_name text not null,
  contact_phone text not null,
  subtotal_paisa bigint not null check (subtotal_paisa >= 0),
  addons_paisa bigint not null default 0 check (addons_paisa >= 0),
  fees_paisa bigint not null default 0 check (fees_paisa >= 0),
  total_paisa bigint not null check (total_paisa >= 0),
  status booking_status not null default 'pending',
  quote_expires_at timestamptz,
  is_draft boolean default false,
  cancelled_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger set_bookings_updated_at
  before update on public.bookings
  for each row execute function public.set_updated_at();

-- Trigger preventing client role from mutating booking.status directly
create or replace function public.prevent_client_booking_status_change()
returns trigger as $$
begin
  if old.status <> new.status and (current_setting('request.jwt.claims', true)::jsonb->>'role') <> 'service_role' then
    raise exception 'Permission denied: booking status updates are restricted to service role';
  end if;
  return new;
end;
$$ language plpgsql;

create trigger check_booking_status_update
  before update on public.bookings
  for each row execute function public.prevent_client_booking_status_change();

create index idx_bookings_user_status on public.bookings(user_id, status);
create index idx_bookings_departure on public.bookings(departure_id);
create index idx_bookings_quote_expiry on public.bookings(status, quote_expires_at) where status = 'pending';

-- Booking participants
create table public.booking_participants (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  full_name text not null,
  age int,
  is_lead boolean default false,
  created_at timestamptz not null default now()
);

create index idx_participants_booking on public.booking_participants(booking_id);
