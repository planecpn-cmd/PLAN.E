-- H1 core (3/4): host creates or edits an experience DRAFT.
--
-- The only client path to write public.experiences (insert/update/delete were
-- revoked from authenticated in 20260823120000). This RPC ONLY ever produces
-- status = 'draft'. Submitting for review is a separate RPC (4/4); publishing
-- is an admin action. Editing a row that is already published / pending_review
-- is rejected here -- that path (a pending_review revision, N1) is a later node.
--
-- Photos are deferred: the wizard holds local file paths until a later slice
-- adds the private experience-photos bucket. cover_image_url stays NULL for a
-- draft (20260909140000 made it optional below pending_review).
--
-- Lossy field mapping documented inline: trip_details has no column and is
-- stored as a single things_to_know element; category_id / region_id / difficulty
-- / duration_hours are left to the admin at review.

create or replace function public.host_save_experience_draft(p jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid       uuid := auth.uid();
  v_id        uuid := nullif(p->>'id', '')::uuid;
  v_title     text := nullif(btrim(coalesce(p->>'title', '')), '');
  v_status    public.experience_status;
  v_slug      text;
  v_base      text;
  v_price     bigint := floor(coalesce((p->>'price_npr')::numeric, 0) * 100)::bigint;
  v_capacity  int    := nullif(p->>'capacity', '')::int;
  v_start     date   := nullif(p->>'start_date', '')::date;
  v_end       date   := nullif(p->>'end_date', '')::date;
  v_trip      text   := nullif(btrim(coalesce(p->>'trip_details', '')), '');
  v_duration  int;
  v_dep_id    uuid;
  i           int;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;
  if not private.is_approved_active_host(v_uid) then
    raise exception 'An approved, active host account is required'
      using errcode = '42501';
  end if;
  if v_title is null then
    raise exception 'Add a title before saving the draft' using errcode = '22023';
  end if;
  if char_length(v_title) > 120 then
    raise exception 'Title must be 120 characters or fewer' using errcode = '22023';
  end if;
  if v_price < 0 then
    raise exception 'Price cannot be negative' using errcode = '22023';
  end if;
  if v_capacity is not null and (v_capacity < 1 or v_capacity > 100) then
    raise exception 'Capacity must be between 1 and 100' using errcode = '22023';
  end if;
  if v_start is not null and v_end is not null and v_end < v_start then
    raise exception 'End date must be on or after the start date'
      using errcode = '22023';
  end if;

  v_duration := case
    when v_start is not null and v_end is not null
      then greatest(1, (v_end - v_start)) * 24
    else null
  end;

  ----------------------------------------------------------------------------
  if v_id is null then
    -- INSERT a new draft. Generate a unique slug (retry on conflict).
    v_base := btrim(regexp_replace(lower(v_title), '[^a-z0-9]+', '-', 'g'), '-');
    if v_base = '' then v_base := 'experience'; end if;
    v_base := left(v_base, 60);
    for i in 1..6 loop
      v_slug := case when i = 1
        then v_base
        else v_base || '-' || substr(md5(random()::text), 1, 6) end;
      exit when not exists (
        select 1 from public.experiences where slug = v_slug
      );
      if i = 6 then
        raise exception 'Could not generate a unique slug for this title'
          using errcode = '23505';
      end if;
    end loop;

    insert into public.experiences (
      host_id, title, slug, description, location_name, meeting_point,
      price_paisa, group_size_max, included, bring_list, things_to_know,
      gallery, cover_image_url, currency,
      duration_hours, status
    ) values (
      v_uid, v_title, v_slug,
      nullif(btrim(coalesce(p->>'description', '')), ''),
      nullif(btrim(coalesce(p->>'location', '')), ''),
      nullif(btrim(coalesce(p->>'meeting_point', '')), ''),
      v_price, v_capacity,
      coalesce(array(select jsonb_array_elements_text(coalesce(p->'included', '[]'::jsonb))), '{}'),
      coalesce(array(select jsonb_array_elements_text(coalesce(p->'bring', '[]'::jsonb))), '{}'),
      case when v_trip is not null then array[v_trip] else '{}'::text[] end,
      coalesce(array(select jsonb_array_elements_text(coalesce(p->'gallery', '[]'::jsonb))), '{}'),
      nullif(p->>'cover_image_url', ''),
      'NPR',
      coalesce(v_duration, 24),
      'draft'
    )
    returning id into v_id;
  else
    -- UPDATE an existing draft owned by the caller.
    select status into v_status
    from public.experiences
    where id = v_id and host_id = v_uid
    for update;

    if not found then
      raise exception 'Experience not found or not owned by the caller'
        using errcode = '42501';
    end if;
    if v_status <> 'draft'::public.experience_status then
      raise exception
        'Only a draft can be edited here (status is %). Editing a live listing is not supported yet.',
        v_status using errcode = '22023';
    end if;

    update public.experiences set
      title          = v_title,
      description     = nullif(btrim(coalesce(p->>'description', '')), ''),
      location_name  = nullif(btrim(coalesce(p->>'location', '')), ''),
      meeting_point  = nullif(btrim(coalesce(p->>'meeting_point', '')), ''),
      price_paisa    = v_price,
      group_size_max = v_capacity,
      included       = coalesce(array(select jsonb_array_elements_text(coalesce(p->'included', '[]'::jsonb))), '{}'),
      bring_list     = coalesce(array(select jsonb_array_elements_text(coalesce(p->'bring', '[]'::jsonb))), '{}'),
      things_to_know = case when v_trip is not null then array[v_trip] else '{}'::text[] end,
      gallery        = coalesce(array(select jsonb_array_elements_text(coalesce(p->'gallery', '[]'::jsonb))), '{}'),
      cover_image_url = nullif(p->>'cover_image_url', ''),
      duration_hours = coalesce(v_duration, duration_hours),
      updated_at     = now()
    where id = v_id;
  end if;

  ----------------------------------------------------------------------------
  -- Itinerary: replace with the ordered list from the payload.
  delete from public.itinerary_items where experience_id = v_id;
  insert into public.itinerary_items (experience_id, day_number, title, sort_order)
  select v_id, ord, val, ord
  from jsonb_array_elements_text(coalesce(p->'itinerary', '[]'::jsonb))
    with ordinality as t(val, ord)
  where btrim(val) <> '';

  ----------------------------------------------------------------------------
  -- Departure: only when the draft carries both dates and a capacity.
  -- A draft has no bookings, so this is a straight upsert of the earliest
  -- open departure.
  if v_start is not null and v_end is not null and v_capacity is not null then
    select id into v_dep_id
    from public.experience_departures
    where experience_id = v_id and status = 'open'
    order by start_date asc
    limit 1
    for update;

    if v_dep_id is null then
      insert into public.experience_departures
        (experience_id, start_date, end_date, total_spots, spots_left, status)
      values (v_id, v_start, v_end, v_capacity, v_capacity, 'open');
    else
      update public.experience_departures
        set start_date = v_start, end_date = v_end,
            total_spots = v_capacity, spots_left = v_capacity
      where id = v_dep_id;
    end if;
  end if;

  return v_id;
end;
$$;

revoke execute on function public.host_save_experience_draft(jsonb)
  from public, anon;
grant execute on function public.host_save_experience_draft(jsonb)
  to authenticated;
