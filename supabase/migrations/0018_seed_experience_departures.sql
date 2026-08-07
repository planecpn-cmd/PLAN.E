-- Every bookable published experience needs server-backed departures.
-- The mobile app must never invent departure IDs because booking validation
-- and payment intents require a real foreign key.
insert into public.experience_departures (
  experience_id,
  start_date,
  end_date,
  total_spots,
  spots_left,
  status
)
select
  e.id,
  current_date + schedule.offset_days,
  current_date + schedule.offset_days
    + greatest(1, ceil(e.duration_hours / 24.0)::int),
  e.group_size_max,
  greatest(1, round(e.group_size_max * schedule.availability)::int),
  'open'
from public.experiences e
cross join (
  values
    (7, 1.0),
    (14, 0.6),
    (21, 0.3)
) as schedule(offset_days, availability)
where e.status = 'published'
on conflict (experience_id, start_date) do nothing;
