-- Migration 0009: Trip Tools (Chat, Gear, Budget)

-- Helper security definer function to check trip membership
create or replace function public.is_trip_member(p_booking_id uuid)
returns boolean as $$
declare
  v_user_id uuid;
  v_is_owner boolean;
  v_is_host boolean;
begin
  v_user_id := auth.uid();
  if v_user_id is null then return false; end if;

  select exists (
    select 1 from public.bookings b where b.id = p_booking_id and b.user_id = v_user_id
  ) into v_is_owner;

  if v_is_owner then return true; end if;

  select exists (
    select 1 from public.bookings b
    join public.experiences e on e.id = b.experience_id
    where b.id = p_booking_id and e.host_id = v_user_id
  ) into v_is_host;

  return v_is_host;
end;
$$ language plpgsql security definer;

-- Trip messages (RM-11)
create table public.trip_messages (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  body text not null,
  attachment_url text,
  created_at timestamptz not null default now()
);

create index idx_trip_messages_booking on public.trip_messages(booking_id, created_at desc);

-- Gear checklist items (RM-12)
create table public.gear_checklist_items (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  label text not null,
  is_checked boolean not null default false,
  is_custom boolean not null default false,
  sort_order int default 0,
  created_at timestamptz not null default now()
);

create index idx_gear_items_booking on public.gear_checklist_items(booking_id);

-- Budget entries (RM-13)
create table public.budget_entries (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  label text not null,
  amount_paisa bigint not null check (amount_paisa >= 0),
  category text,
  spent_on date default current_date,
  created_at timestamptz not null default now()
);

create index idx_budget_entries_booking on public.budget_entries(booking_id);
