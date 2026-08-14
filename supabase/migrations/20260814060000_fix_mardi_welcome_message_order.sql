-- Keep the seeded welcome message at the beginning of the Mardi conversation.
-- The original rolling `now() - 1 day` timestamp could place it after real
-- messages when the demo seed was re-run on a later day.
update public.trip_messages as welcome
set created_at = coalesce(
  (
    select min(message.created_at) - interval '1 minute'
    from public.trip_messages as message
    where message.booking_id = welcome.booking_id
      and message.id <> welcome.id
  ),
  (
    select booking.created_at + interval '1 minute'
    from public.bookings as booking
    where booking.id = welcome.booking_id
  ),
  welcome.created_at
)
where welcome.id = 'a2000000-0000-4000-8000-000000000003'
  and welcome.booking_id = 'b1000000-0000-4000-8000-000000000002';
