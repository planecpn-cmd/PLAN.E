-- send_trip_message is security invoker and relies on trip_messages RLS.
grant insert on table public.trip_messages to authenticated;

-- Immutable audit history is available only through authorized moderator RPCs.
revoke select on table
  public.trip_message_edits,
  public.trip_message_deletions
from authenticated;
