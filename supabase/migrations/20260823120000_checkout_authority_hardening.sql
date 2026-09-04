-- Priced bookings and live experience mutations are server-authoritative.

drop policy if exists "Users can insert pending bookings" on public.bookings;
revoke insert on table public.bookings from authenticated;

drop policy if exists "Approved active hosts can manage their experiences"
  on public.experiences;
revoke insert, update, delete on table public.experiences from authenticated;

-- Published discovery and approved-host ownership reads remain governed by:
--   "Published experiences are readable by everyone"
--   "Approved active hosts can view their own experiences"
