-- N6 dashboard shell: indexes the new counter queries need that nothing
-- existing covers. idx_bookings_status/created_at, idx_host_accounts_is_active
-- and idx_profiles_role already exist (20260908100000) and cover the rest of
-- what these counters filter on.

-- "today's cancellations" filters by cancelled_at directly (not status alone,
-- not created_at) -- no existing index touches this column.
create index if not exists idx_bookings_cancelled_at
  on public.bookings (cancelled_at desc);

-- "new users today" filters profiles by created_at -- profiles had no
-- created_at index at all (only idx_profiles_role).
create index if not exists idx_profiles_created_at
  on public.profiles (created_at desc);

-- "new hosts today" filters host_accounts by created_at -- host_accounts only
-- had is_active/suspended_at indexed.
create index if not exists idx_host_accounts_created_at
  on public.host_accounts (created_at desc);

-- "upcoming bookings" first selects departures with start_date >= today, then
-- looks up bookings by departure_id. idx_departures_exp_date (0007) is a
-- partial index WHERE status = 'open' on (experience_id, start_date) -- not
-- usable here since the dashboard counter deliberately does not filter by
-- departure status (a booking against a now-closed departure that hasn't
-- happened yet is still "upcoming"). bookings.departure_id already has
-- idx_bookings_departure (0007).
create index if not exists idx_departures_start_date
  on public.experience_departures (start_date);
