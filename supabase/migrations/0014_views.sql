-- Migration 0014: Views for My Plans and My Trips
create or replace view public.my_plans_upcoming as
select
  b.id as booking_id,
  b.booking_ref,
  b.user_id,
  b.status,
  b.total_paisa,
  b.adults,
  b.children,
  e.id as experience_id,
  e.title as experience_title,
  e.cover_image_url,
  e.location_name,
  d.start_date,
  d.end_date
from public.bookings b
join public.experiences e on e.id = b.experience_id
join public.experience_departures d on d.id = b.departure_id
where b.status = 'confirmed' and d.start_date >= current_date;

create or replace view public.my_trips_completed as
select
  b.id as booking_id,
  b.booking_ref,
  b.user_id,
  b.total_paisa,
  b.completed_at,
  e.id as experience_id,
  e.title as experience_title,
  e.cover_image_url,
  e.location_name,
  r.id as review_id
from public.bookings b
join public.experiences e on e.id = b.experience_id
left join public.reviews r on r.booking_id = b.id
where b.status = 'completed';

create or replace view public.my_trips_cancelled as
select
  b.id as booking_id,
  b.booking_ref,
  b.user_id,
  b.total_paisa,
  b.cancelled_at,
  e.id as experience_id,
  e.title as experience_title,
  e.cover_image_url,
  e.location_name
from public.bookings b
join public.experiences e on e.id = b.experience_id
where b.status = 'cancelled';
