-- Phase 6B: explicit per-recipient delivery/seen receipts.
-- This is intentionally row-per-message-per-recipient and ships only because
-- granular receipts were explicitly requested after compact Phase 1 cursors.

create table public.trip_message_receipts (
  message_id uuid not null references public.trip_messages(id) on delete cascade,
  conversation_id uuid not null references public.bookings(id) on delete cascade,
  recipient_id uuid not null references auth.users(id) on delete cascade,
  delivered_at timestamptz not null default now(),
  seen_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (message_id, recipient_id)
);

create index idx_trip_message_receipts_conversation_recipient
  on public.trip_message_receipts(conversation_id, recipient_id, seen_at);

alter table public.trip_message_receipts enable row level security;

create policy "Recipients and senders can read message receipts"
  on public.trip_message_receipts for select to authenticated
  using (
    recipient_id = auth.uid()
    or exists (
      select 1
      from public.trip_messages message
      where message.id = message_id
        and message.sender_id = auth.uid()
    )
  );

revoke all on table public.trip_message_receipts from public, anon, authenticated;
grant select on table public.trip_message_receipts to authenticated;

create or replace function private.create_trip_message_receipts()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.trip_message_receipts (
    message_id,
    conversation_id,
    recipient_id,
    delivered_at
  )
  select distinct new.id, new.booking_id, participant.user_id, now()
  from (
    select member.user_id
    from public.trip_conversations conversation
    join public.trip_conversation_members member
      on member.conversation_id = conversation.id
    where conversation.booking_id = new.booking_id

    union

    select booking.user_id
    from public.bookings booking
    where booking.id = new.booking_id

    union

    select experience.host_id
    from public.bookings booking
    join public.experiences experience on experience.id = booking.experience_id
    where booking.id = new.booking_id
      and experience.host_id is not null
  ) participant
  where participant.user_id <> new.sender_id
  on conflict (message_id, recipient_id) do nothing;
  return new;
end;
$$;

revoke all on function private.create_trip_message_receipts()
  from public, anon, authenticated;

create trigger create_trip_message_receipts_after_insert
  after insert on public.trip_messages
  for each row execute function private.create_trip_message_receipts();

-- Backfill preserves the conservative meaning of "delivered": accepted by
-- the server. Historical messages are not guessed to have been seen.
insert into public.trip_message_receipts (
  message_id,
  conversation_id,
  recipient_id,
  delivered_at,
  created_at,
  updated_at
)
select distinct
  message.id,
  message.booking_id,
  participant.user_id,
  message.created_at,
  message.created_at,
  message.created_at
from public.trip_messages message
join lateral (
  select member.user_id
  from public.trip_conversations conversation
  join public.trip_conversation_members member
    on member.conversation_id = conversation.id
  where conversation.booking_id = message.booking_id

  union

  select booking.user_id
  from public.bookings booking
  where booking.id = message.booking_id

  union

  select experience.host_id
  from public.bookings booking
  join public.experiences experience on experience.id = booking.experience_id
  where booking.id = message.booking_id
    and experience.host_id is not null
) participant on participant.user_id <> message.sender_id
on conflict (message_id, recipient_id) do nothing;

-- Extend the existing conversation-open write path so read cursor and
-- per-message receipts stay consistent in one idempotent client call.
create or replace function public.mark_trip_conversation_read(
  p_conversation_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_message_id uuid;
  v_message_at timestamptz;
begin
  if v_user_id is null or not public.is_trip_member(p_conversation_id) then
    raise exception 'Trip conversation access denied';
  end if;

  select message.id, message.created_at
    into v_message_id, v_message_at
  from public.trip_messages message
  where message.booking_id = p_conversation_id
  order by message.created_at desc, message.id desc
  limit 1;

  insert into public.trip_message_reads (
    conversation_id,
    user_id,
    last_read_message_id,
    last_read_at
  ) values (
    p_conversation_id,
    v_user_id,
    v_message_id,
    coalesce(v_message_at, now())
  )
  on conflict (conversation_id, user_id) do update
  set last_read_message_id = excluded.last_read_message_id,
      last_read_at = excluded.last_read_at;

  update public.trip_message_receipts receipt
  set seen_at = coalesce(receipt.seen_at, now()),
      updated_at = now()
  where receipt.conversation_id = p_conversation_id
    and receipt.recipient_id = v_user_id
    and receipt.seen_at is null;
end;
$$;

revoke all on function public.mark_trip_conversation_read(uuid) from public;
grant execute on function public.mark_trip_conversation_read(uuid)
  to authenticated;

do $$
begin
  alter publication supabase_realtime
    add table public.trip_message_receipts;
exception
  when duplicate_object then null;
end $$;
