-- Phase 2 messaging hardening: additive idempotency for durable outbox replay.

alter table public.trip_messages
  add column client_message_id uuid;

alter table public.trip_messages
  add constraint trip_messages_client_message_id_key
  unique (client_message_id);

-- One security-invoker write path gives traveler and host clients identical
-- retry semantics. Existing trip_messages RLS remains authoritative.
create or replace function public.send_trip_message(
  p_booking_id uuid,
  p_client_message_id uuid,
  p_body text,
  p_attachment_url text default null
)
returns setof public.trip_messages
language plpgsql
security invoker
set search_path = public
as $$
begin
  if length(btrim(p_body)) < 1 or length(btrim(p_body)) > 2000 then
    raise exception 'Message must contain 1 to 2000 characters';
  end if;

  return query
  insert into public.trip_messages (
    id,
    booking_id,
    sender_id,
    body,
    attachment_url,
    client_message_id
  ) values (
    p_client_message_id,
    p_booking_id,
    auth.uid(),
    btrim(p_body),
    p_attachment_url,
    p_client_message_id
  )
  on conflict (client_message_id) do nothing
  returning *;

  if not found then
    return query
    select message.*
    from public.trip_messages message
    where message.client_message_id = p_client_message_id
      and message.booking_id = p_booking_id
      and message.sender_id = auth.uid();
  end if;
end;
$$;

revoke all on function public.send_trip_message(uuid, uuid, text, text)
  from public;
grant execute on function public.send_trip_message(uuid, uuid, text, text)
  to authenticated;
