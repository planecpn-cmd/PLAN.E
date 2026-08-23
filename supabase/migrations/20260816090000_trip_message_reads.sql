-- Phase 1 messaging hardening: compact per-user conversation read state.
-- Additive only; trip_messages remains unchanged.

create table public.trip_message_reads (
  conversation_id uuid not null references public.bookings(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  last_read_message_id uuid references public.trip_messages(id) on delete set null,
  last_read_at timestamptz not null default now(),
  primary key (conversation_id, user_id)
);

create index idx_trip_message_reads_user
  on public.trip_message_reads(user_id);

alter table public.trip_message_reads enable row level security;

create policy "Trip members can read their own message read state"
  on public.trip_message_reads for select
  using (
    user_id = auth.uid()
    and public.is_trip_member(conversation_id)
  );

create policy "Trip members can insert their own message read state"
  on public.trip_message_reads for insert
  with check (
    user_id = auth.uid()
    and public.is_trip_member(conversation_id)
    and (
      last_read_message_id is null
      or exists (
        select 1
        from public.trip_messages message
        where message.id = last_read_message_id
          and message.booking_id = conversation_id
      )
    )
  );

create policy "Trip members can update their own message read state"
  on public.trip_message_reads for update
  using (
    user_id = auth.uid()
    and public.is_trip_member(conversation_id)
  )
  with check (
    user_id = auth.uid()
    and public.is_trip_member(conversation_id)
    and (
      last_read_message_id is null
      or exists (
        select 1
        from public.trip_messages message
        where message.id = last_read_message_id
          and message.booking_id = conversation_id
      )
    )
  );

grant select, insert, update on public.trip_message_reads to authenticated;

-- A single idempotent call marks the latest server-authoritative message as
-- read. SECURITY INVOKER keeps the table policies and booking membership
-- check in force for every caller.
create or replace function public.mark_trip_conversation_read(
  p_conversation_id uuid
)
returns void
language plpgsql
security invoker
set search_path = public
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
end;
$$;

revoke all on function public.mark_trip_conversation_read(uuid) from public;
grant execute on function public.mark_trip_conversation_read(uuid) to authenticated;
