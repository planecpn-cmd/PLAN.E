-- H1 core (2/4): host edits the dates + capacity of their experience's
-- departure.
--
-- Targets THE EARLIEST status = 'open' departure and creates one if none exists
-- -- the single departure the flattened HostExperience model and the host UI
-- surface. The one-departure limitation (and the client doc's real
-- availability-calendar requirement) is tracked in docs/H1_HOST_WRITE_PATH.md
-- under "Known limitations".
--
-- Booking-conflict rules are the point: capacity may not drop below the number
-- already booked, and dates may not move while the departure has active
-- bookings. experiences.status is never touched (client cannot publish).

create or replace function public.host_update_experience_availability(
  p_experience_id uuid,
  p_start date,
  p_end date,
  p_total_spots int
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid    uuid := auth.uid();
  v_dep_id uuid;
  v_d_start date;
  v_d_end   date;
  v_d_total int;
  v_d_left  int;
  v_booked  int;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;
  if not private.is_approved_active_host(v_uid) then
    raise exception 'An approved, active host account is required'
      using errcode = '42501';
  end if;
  if not exists (
    select 1 from public.experiences
    where id = p_experience_id and host_id = v_uid
  ) then
    raise exception 'Experience not found or not owned by the caller'
      using errcode = '42501';
  end if;

  if p_start is null or p_end is null or p_end < p_start then
    raise exception 'End date must be on or after the start date'
      using errcode = '22023';
  end if;
  if p_total_spots is null or p_total_spots < 1 or p_total_spots > 100 then
    raise exception 'Capacity must be between 1 and 100' using errcode = '22023';
  end if;

  select id, start_date, end_date, total_spots, spots_left
    into v_dep_id, v_d_start, v_d_end, v_d_total, v_d_left
  from public.experience_departures
  where experience_id = p_experience_id and status = 'open'
  order by start_date asc
  limit 1
  for update;

  if not found then
    insert into public.experience_departures
      (experience_id, start_date, end_date, total_spots, spots_left, status)
    values (p_experience_id, p_start, p_end, p_total_spots, p_total_spots, 'open')
    returning id into v_dep_id;
    return v_dep_id;
  end if;

  v_booked := v_d_total - v_d_left;

  if p_total_spots < v_booked then
    raise exception
      'Capacity (%) is below the % already booked on this departure',
      p_total_spots, v_booked using errcode = '22023';
  end if;

  if (p_start, p_end) is distinct from (v_d_start, v_d_end)
     and exists (
       select 1 from public.bookings
       where departure_id = v_dep_id
         and status not in (
           'cancelled'::public.booking_status,
           'expired'::public.booking_status
         )
     ) then
    raise exception
      'Cannot change the dates of a departure that has active bookings'
      using errcode = '22023';
  end if;

  update public.experience_departures
    set start_date  = p_start,
        end_date    = p_end,
        total_spots = p_total_spots,
        spots_left  = p_total_spots - v_booked
  where id = v_dep_id;

  return v_dep_id;
end;
$$;

revoke execute on function
  public.host_update_experience_availability(uuid, date, date, int)
  from public, anon;
grant execute on function
  public.host_update_experience_availability(uuid, date, date, int)
  to authenticated;
