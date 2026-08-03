-- Migration 0013: RLS Policies for All Tables (Default Deny)

-- Enable RLS on every table
alter table public.profiles enable row level security;
alter table public.interests enable row level security;
alter table public.user_interests enable row level security;
alter table public.regions enable row level security;
alter table public.categories enable row level security;
alter table public.experiences enable row level security;
alter table public.experience_departures enable row level security;
alter table public.itinerary_items enable row level security;
alter table public.saved_experiences enable row level security;
alter table public.bookings enable row level security;
alter table public.booking_participants enable row level security;
alter table public.payments enable row level security;
alter table public.trip_messages enable row level security;
alter table public.gear_checklist_items enable row level security;
alter table public.budget_entries enable row level security;
alter table public.reviews enable row level security;
alter table public.host_applications enable row level security;
alter table public.notifications enable row level security;
alter table public.device_tokens enable row level security;

-------------------------------------------------------
-- 1. Profiles Policies
-------------------------------------------------------
create policy "Public profiles are readable by everyone"
  on public.profiles for select
  using (true);

create policy "Users can update their own profile"
  on public.profiles for update
  using (auth.uid() = id);

-------------------------------------------------------
-- 2. Interests Policies
-------------------------------------------------------
create policy "Interests are readable by everyone"
  on public.interests for select
  using (true);

-------------------------------------------------------
-- 3. User Interests Policies
-------------------------------------------------------
create policy "Users can read their own interests"
  on public.user_interests for select
  using (auth.uid() = user_id);

create policy "Users can manage their own interests"
  on public.user_interests for all
  using (auth.uid() = user_id);

-------------------------------------------------------
-- 4. Regions & Categories Policies
-------------------------------------------------------
create policy "Regions are readable by everyone"
  on public.regions for select
  using (true);

create policy "Categories are readable by everyone"
  on public.categories for select
  using (true);

-------------------------------------------------------
-- 5. Experiences & Departures Policies
-------------------------------------------------------
create policy "Published experiences are readable by anyone"
  on public.experiences for select
  using (status = 'published' or auth.uid() = host_id);

create policy "Hosts can manage draft or pending experiences"
  on public.experiences for all
  using (auth.uid() = host_id and status in ('draft','pending_review'));

create policy "Departures readable for published experiences"
  on public.experience_departures for select
  using (
    exists (
      select 1 from public.experiences e
      where e.id = experience_id and (e.status = 'published' or e.host_id = auth.uid())
    )
  );

create policy "Itinerary items readable by anyone"
  on public.itinerary_items for select
  using (
    exists (
      select 1 from public.experiences e
      where e.id = experience_id and (e.status = 'published' or e.host_id = auth.uid())
    )
  );

-------------------------------------------------------
-- 6. Saved Experiences Policies
-------------------------------------------------------
create policy "Users can manage saved experiences"
  on public.saved_experiences for all
  using (auth.uid() = user_id);

-------------------------------------------------------
-- 7. Bookings & Participants Policies
-------------------------------------------------------
create policy "Users can view their own bookings"
  on public.bookings for select
  using (
    auth.uid() = user_id or
    exists (
      select 1 from public.experiences e
      where e.id = experience_id and e.host_id = auth.uid()
    )
  );

create policy "Users can insert pending bookings"
  on public.bookings for insert
  with check (
    auth.uid() = user_id and status = 'pending'
  );

create policy "Participants readable by booking owner or host"
  on public.booking_participants for select
  using (
    exists (
      select 1 from public.bookings b
      where b.id = booking_id and (b.user_id = auth.uid() or exists (
        select 1 from public.experiences e where e.id = b.experience_id and e.host_id = auth.uid()
      ))
    )
  );

create policy "Booking lead user can insert participants"
  on public.booking_participants for insert
  with check (
    exists (
      select 1 from public.bookings b
      where b.id = booking_id and b.user_id = auth.uid()
    )
  );

-------------------------------------------------------
-- 8. Payments Policies (No Client Access)
-------------------------------------------------------
-- Intentionally no client policies created on payments! Service role only.

-------------------------------------------------------
-- 9. Trip Tools Policies
-------------------------------------------------------
create policy "Trip members can read trip messages"
  on public.trip_messages for select
  using (public.is_trip_member(booking_id));

create policy "Trip members can insert trip messages"
  on public.trip_messages for insert
  with check (public.is_trip_member(booking_id) and auth.uid() = sender_id);

create policy "Booking owners can manage gear checklist"
  on public.gear_checklist_items for all
  using (
    exists (select 1 from public.bookings b where b.id = booking_id and b.user_id = auth.uid())
  );

create policy "Booking owners can manage budget entries"
  on public.budget_entries for all
  using (
    exists (select 1 from public.bookings b where b.id = booking_id and b.user_id = auth.uid())
  );

-------------------------------------------------------
-- 10. Reviews Policies
-------------------------------------------------------
create policy "Reviews are readable by everyone"
  on public.reviews for select
  using (true);

create policy "Users can insert review for completed booking"
  on public.reviews for insert
  with check (
    auth.uid() = user_id and
    exists (
      select 1 from public.bookings b
      where b.id = booking_id and b.user_id = auth.uid() and b.status = 'completed'
    )
  );

-------------------------------------------------------
-- 11. Host Applications Policies
-------------------------------------------------------
create policy "Users can view their own host application"
  on public.host_applications for select
  using (auth.uid() = user_id);

create policy "Users can create and edit draft host applications"
  on public.host_applications for all
  using (auth.uid() = user_id and status = 'draft');

-------------------------------------------------------
-- 12. Notifications & Device Tokens
-------------------------------------------------------
create policy "Users can view their own notifications"
  on public.notifications for select
  using (auth.uid() = user_id);

create policy "Users can mark notifications as read"
  on public.notifications for update
  using (auth.uid() = user_id);

create policy "Users can manage their device tokens"
  on public.device_tokens for all
  using (auth.uid() = user_id);
