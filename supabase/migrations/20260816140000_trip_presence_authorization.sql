-- Phase 6 messaging hardening: private, ephemeral trip Presence channels.
-- Presence state remains in Realtime's CRDT memory; no application rows are
-- created and no typing/online history is persisted.

create or replace function private.can_join_trip_presence(
  candidate_topic text,
  candidate_user_id uuid
)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_booking_id uuid;
begin
  if candidate_user_id is null or candidate_topic is null or
      candidate_topic !~* '^trip-presence:[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' then
    return false;
  end if;

  v_booking_id := substring(candidate_topic from 15)::uuid;

  -- Keep the booking relationship authoritative during the Phase 3 shadow
  -- burn-in, while also accepting conversation memberships for future groups.
  return exists (
    select 1
    from public.bookings booking
    left join public.experiences experience
      on experience.id = booking.experience_id
    where booking.id = v_booking_id
      and candidate_user_id in (booking.user_id, experience.host_id)
  ) or exists (
    select 1
    from public.trip_conversations conversation
    join public.trip_conversation_members membership
      on membership.conversation_id = conversation.id
    where conversation.booking_id = v_booking_id
      and membership.user_id = candidate_user_id
  );
end;
$$;

revoke all on function private.can_join_trip_presence(text, uuid)
  from public, anon;
grant execute on function private.can_join_trip_presence(text, uuid)
  to authenticated;

create policy "Trip members can receive private trip presence"
  on realtime.messages
  for select
  to authenticated
  using (
    realtime.messages.extension = 'presence'
    and private.can_join_trip_presence(
      (select realtime.topic()),
      (select auth.uid())
    )
  );

create policy "Trip members can publish private trip presence"
  on realtime.messages
  for insert
  to authenticated
  with check (
    realtime.messages.extension = 'presence'
    and private.can_join_trip_presence(
      (select realtime.topic()),
      (select auth.uid())
    )
  );
