-- D1: editing a PUBLISHED (or paused) listing creates a pending-review
-- REVISION. The live row is never mutated until a reviewer approves; discovery
-- only ever shows status = 'published' rows and RLS blocks a traveler from
-- reading a non-published row, so a revision is invisible to travelers.
--
-- Model: a revision is a full public.experiences row with revision_of = <live
-- id> and status draft -> pending_review -> archived. The N1 review queue,
-- detail screen and decision endpoint already work on an experiences row, so
-- there is almost no new admin surface -- only "on approve, if revision_of is
-- set, apply it to the live row atomically" (admin_apply_experience_revision).
--
-- A revision covers listing CONTENT only. Availability stays on the live row
-- and is edited through host_update_experience_availability (which has the
-- booking-conflict rules). Bookings reference the live experiences.id and the
-- live row is updated in place (never deleted), so no FK churn and
-- finalize_verified_payment is untouched.

alter table public.experiences
  add column revision_of uuid references public.experiences(id) on delete set null;

create index idx_experiences_revision_of
  on public.experiences (revision_of) where revision_of is not null;

-- a revision is never directly published; approval applies it to the live row.
alter table public.experiences
  add constraint experiences_revision_not_published check (
    revision_of is null or status <> 'published'::public.experience_status
  );

-- ── host_save_experience_draft: route a live-listing edit to a revision ──────
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
  v_revof     uuid;
  v_rev       uuid;
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
    raise exception 'An approved, active host account is required' using errcode = '42501';
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
    raise exception 'End date must be on or after the start date' using errcode = '22023';
  end if;

  v_duration := case
    when v_start is not null and v_end is not null then greatest(1, (v_end - v_start)) * 24
    else null
  end;

  ----------------------------------------------------------------------------
  if v_id is null then
    v_base := btrim(regexp_replace(lower(v_title), '[^a-z0-9]+', '-', 'g'), '-');
    if v_base = '' then v_base := 'experience'; end if;
    v_base := left(v_base, 60);
    for i in 1..6 loop
      v_slug := case when i = 1 then v_base
        else v_base || '-' || substr(md5(random()::text), 1, 6) end;
      exit when not exists (select 1 from public.experiences where slug = v_slug);
      if i = 6 then
        raise exception 'Could not generate a unique slug for this title' using errcode = '23505';
      end if;
    end loop;

    insert into public.experiences (
      host_id, title, slug, description, location_name, meeting_point,
      price_paisa, group_size_max, included, bring_list, things_to_know,
      gallery, cover_image_url, currency, duration_hours, status
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
      'NPR', coalesce(v_duration, 24), 'draft'
    )
    returning id into v_id;
  else
    select status, revision_of into v_status, v_revof
    from public.experiences
    where id = v_id and host_id = v_uid
    for update;

    if not found then
      raise exception 'Experience not found or not owned by the caller' using errcode = '42501';
    end if;

    if v_status in ('published'::public.experience_status, 'paused'::public.experience_status)
       and v_revof is null then
      -- editing a LIVE listing: create or reuse a draft content revision
      if exists (
        select 1 from public.experiences
        where revision_of = v_id and status = 'pending_review'::public.experience_status
      ) then
        raise exception 'This listing already has changes awaiting review.' using errcode = '22023';
      end if;

      select id into v_rev
      from public.experiences
      where revision_of = v_id and status = 'draft'::public.experience_status
      limit 1
      for update;

      if v_rev is null then
        v_base := left(
          btrim(regexp_replace(lower(v_title), '[^a-z0-9]+', '-', 'g'), '-'), 50);
        if v_base = '' then v_base := 'experience'; end if;
        v_slug := v_base || '-rev-' || substr(md5(random()::text), 1, 8);
        insert into public.experiences
          (host_id, title, slug, price_paisa, currency, status, revision_of, duration_hours)
        values (v_uid, v_title, v_slug, greatest(v_price, 0), 'NPR', 'draft', v_id,
                coalesce(v_duration, 24))
        returning id into v_rev;
      end if;

      v_id := v_rev;   -- redirect the content write below to the revision
    elsif v_status <> 'draft'::public.experience_status then
      raise exception
        'Only a draft or a not-yet-submitted revision can be edited (status is %).',
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
  delete from public.itinerary_items where experience_id = v_id;
  insert into public.itinerary_items (experience_id, day_number, title, sort_order)
  select v_id, ord, val, ord
  from jsonb_array_elements_text(coalesce(p->'itinerary', '[]'::jsonb))
    with ordinality as t(val, ord)
  where btrim(val) <> '';

  ----------------------------------------------------------------------------
  -- Departure: only a NEW draft (not a revision) carries availability here;
  -- a revision covers content only.
  if v_start is not null and v_end is not null and v_capacity is not null
     and not exists (select 1 from public.experiences
                     where id = v_id and revision_of is not null) then
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

revoke execute on function public.host_save_experience_draft(jsonb) from public, anon;
grant execute on function public.host_save_experience_draft(jsonb) to authenticated;

-- ── host_submit_experience_for_review: skip the departure check for a revision ─
create or replace function public.host_submit_experience_for_review(
  p_experience_id uuid
)
returns public.experience_status
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_exp record;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;
  if not private.is_approved_active_host(v_uid) then
    raise exception 'An approved, active host account is required' using errcode = '42501';
  end if;

  select id, status, title, description, location_name, cover_image_url, price_paisa, revision_of
    into v_exp
  from public.experiences
  where id = p_experience_id and host_id = v_uid
  for update;

  if not found then
    raise exception 'Experience not found or not owned by the caller' using errcode = '42501';
  end if;
  if v_exp.status <> 'draft'::public.experience_status then
    raise exception 'Only a draft can be submitted for review (status is %)',
      v_exp.status using errcode = '22023';
  end if;

  if coalesce(btrim(v_exp.title), '') = '' then
    raise exception 'Add a title before submitting for review' using errcode = '22023';
  end if;
  if coalesce(btrim(v_exp.description), '') = '' then
    raise exception 'Add a description before submitting for review' using errcode = '22023';
  end if;
  if coalesce(btrim(v_exp.location_name), '') = '' then
    raise exception 'Add a location before submitting for review' using errcode = '22023';
  end if;
  if v_exp.cover_image_url is null then
    raise exception 'Add at least one photo before submitting for review' using errcode = '22023';
  end if;
  if coalesce(v_exp.price_paisa, 0) <= 0 then
    raise exception 'Set a price greater than zero before submitting for review' using errcode = '22023';
  end if;
  if v_exp.revision_of is null and not exists (
    select 1 from public.experience_departures
    where experience_id = p_experience_id and status = 'open'
  ) then
    raise exception 'Set dates and capacity before submitting for review' using errcode = '22023';
  end if;

  update public.experiences
    set status = 'pending_review'::public.experience_status, updated_at = now()
  where id = p_experience_id;

  return 'pending_review'::public.experience_status;
end;
$$;

revoke execute on function public.host_submit_experience_for_review(uuid) from public, anon;
grant execute on function public.host_submit_experience_for_review(uuid) to authenticated;

-- ── admin_apply_experience_revision: atomic swap into the live row ───────────
-- Service-role only; called by the admin decision endpoint after it has copied
-- the revision's photos into experience-photos-public. One transaction:
-- content -> live row, itinerary -> live row, revision -> archived, and an
-- experience_reviews row against the LIVE id.
create or replace function public.admin_apply_experience_revision(
  p_revision_id uuid,
  p_reviewer uuid,
  p jsonb
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_rev  public.experiences%rowtype;
  v_live uuid;
begin
  select * into v_rev from public.experiences where id = p_revision_id for update;
  if not found then
    raise exception 'revision not found' using errcode = '42704';
  end if;
  if v_rev.revision_of is null then
    raise exception 'not a revision' using errcode = '22023';
  end if;
  v_live := v_rev.revision_of;

  perform 1 from public.experiences where id = v_live for update;
  if not found then
    raise exception 'live experience is gone' using errcode = '42704';
  end if;

  update public.experiences set
    title          = v_rev.title,
    summary        = v_rev.summary,
    description     = v_rev.description,
    location_name  = v_rev.location_name,
    meeting_point  = v_rev.meeting_point,
    price_paisa    = v_rev.price_paisa,
    child_price_paisa = v_rev.child_price_paisa,
    group_size_max = v_rev.group_size_max,
    included       = v_rev.included,
    bring_list     = v_rev.bring_list,
    things_to_know = v_rev.things_to_know,
    duration_hours = v_rev.duration_hours,
    category_id    = nullif(p->>'category_id', '')::uuid,
    region_id      = nullif(p->>'region_id', '')::uuid,
    difficulty     = coalesce(nullif(p->>'difficulty', '')::public.difficulty_level, difficulty),
    cover_image_url = nullif(p->>'cover', ''),
    gallery        = coalesce(
                       array(select jsonb_array_elements_text(coalesce(p->'gallery', '[]'::jsonb))),
                       '{}'),
    reviewer_id    = p_reviewer,
    updated_at     = now()
  where id = v_live;

  delete from public.itinerary_items where experience_id = v_live;
  insert into public.itinerary_items
    (experience_id, day_number, start_time, title, description, sort_order)
  select v_live, day_number, start_time, title, description, sort_order
  from public.itinerary_items where experience_id = p_revision_id;

  update public.experiences
    set status = 'archived'::public.experience_status, updated_at = now()
  where id = p_revision_id;

  insert into public.experience_reviews
    (experience_id, reviewer_id, from_status, to_status, decision, note)
  values (v_live, p_reviewer,
          'published'::public.experience_status,
          'published'::public.experience_status,
          'approve', 'revision applied');

  return v_live;
end;
$$;

revoke execute on function public.admin_apply_experience_revision(uuid, uuid, jsonb)
  from public, anon, authenticated;
