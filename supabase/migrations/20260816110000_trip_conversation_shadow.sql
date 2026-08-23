-- Phase 3 messaging hardening: shadow conversation/membership model.
-- Existing trip_messages.booking_id reads remain authoritative during burn-in.

create table public.trip_conversations (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null unique references public.bookings(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table public.trip_conversation_members (
  conversation_id uuid not null references public.trip_conversations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('traveler', 'host')),
  created_at timestamptz not null default now(),
  primary key (conversation_id, user_id)
);

create index idx_trip_conversation_members_user
  on public.trip_conversation_members(user_id, conversation_id);

alter table public.trip_conversations enable row level security;
alter table public.trip_conversation_members enable row level security;

-- A member may discover the conversation container, but membership identity
-- remains private: the member-table policy below exposes only the caller's
-- own row, never the other participant.
create policy "Trip members can read their conversation containers"
  on public.trip_conversations for select to authenticated
  using (
    exists (
      select 1
      from public.trip_conversation_members membership
      where membership.conversation_id = id
        and membership.user_id = auth.uid()
    )
  );

create policy "Users can read only their own conversation membership"
  on public.trip_conversation_members for select to authenticated
  using (user_id = auth.uid());

revoke all on table public.trip_conversations from anon, authenticated;
revoke all on table public.trip_conversation_members from anon, authenticated;
grant select on table public.trip_conversations to authenticated;
grant select on table public.trip_conversation_members to authenticated;

create or replace function private.shadow_trip_conversation_for_booking()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_conversation_id uuid;
  v_host_id uuid;
begin
  insert into public.trip_conversations (booking_id)
  values (new.id)
  on conflict (booking_id) do update set booking_id = excluded.booking_id
  returning id into v_conversation_id;

  select experience.host_id
    into v_host_id
  from public.experiences experience
  where experience.id = new.experience_id;

  insert into public.trip_conversation_members (
    conversation_id,
    user_id,
    role
  ) values (
    v_conversation_id,
    new.user_id,
    'traveler'
  )
  on conflict (conversation_id, user_id) do nothing;

  if v_host_id is not null then
    insert into public.trip_conversation_members (
      conversation_id,
      user_id,
      role
    ) values (
      v_conversation_id,
      v_host_id,
      'host'
    )
    on conflict (conversation_id, user_id) do update set role = 'host';
  end if;

  return new;
end;
$$;

revoke all on function private.shadow_trip_conversation_for_booking()
  from public, anon, authenticated;

create trigger shadow_trip_conversation_after_booking_insert
  after insert on public.bookings
  for each row execute function private.shadow_trip_conversation_for_booking();

-- One-time backfill. The unique booking key and membership primary key make
-- the operation idempotent if it is repeated during deployment verification.
insert into public.trip_conversations (booking_id)
select booking.id
from public.bookings booking
on conflict (booking_id) do nothing;

insert into public.trip_conversation_members (conversation_id, user_id, role)
select conversation.id, booking.user_id, 'traveler'
from public.trip_conversations conversation
join public.bookings booking on booking.id = conversation.booking_id
on conflict (conversation_id, user_id) do nothing;

insert into public.trip_conversation_members (conversation_id, user_id, role)
select conversation.id, experience.host_id, 'host'
from public.trip_conversations conversation
join public.bookings booking on booking.id = conversation.booking_id
join public.experiences experience on experience.id = booking.experience_id
where experience.host_id is not null
on conflict (conversation_id, user_id) do update set role = 'host';

-- Backend-only burn-in diagnostic. An empty result means every booking has
-- one shadow conversation and the expected private participant memberships.
create or replace view private.trip_conversation_shadow_drift as
select booking.id as booking_id, 'missing_conversation'::text as reason
from public.bookings booking
where not exists (
  select 1
  from public.trip_conversations conversation
  where conversation.booking_id = booking.id
)
union all
select booking.id, 'missing_traveler_membership'
from public.bookings booking
join public.trip_conversations conversation
  on conversation.booking_id = booking.id
where not exists (
  select 1
  from public.trip_conversation_members membership
  where membership.conversation_id = conversation.id
    and membership.user_id = booking.user_id
)
union all
select booking.id, 'missing_host_membership'
from public.bookings booking
join public.experiences experience on experience.id = booking.experience_id
join public.trip_conversations conversation
  on conversation.booking_id = booking.id
where experience.host_id is not null
  and not exists (
    select 1
    from public.trip_conversation_members membership
    where membership.conversation_id = conversation.id
      and membership.user_id = experience.host_id
  );

revoke all on table private.trip_conversation_shadow_drift
  from public, anon, authenticated;
