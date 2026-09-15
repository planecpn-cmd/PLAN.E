-- Atomically promote the current listing_revisions workflow into its live
-- experience. Storage objects must be copied to public URLs before this RPC;
-- the ordered URLs are committed with the content update.
create or replace function public.approve_listing_revision(
  p_revision_id uuid,
  p_public_photo_urls text[] default null
) returns uuid
language plpgsql
security definer
set search_path = public, private
as $$
declare
  revision public.listing_revisions%rowtype;
  draft public.listing_drafts%rowtype;
  live public.experiences%rowtype;
  payload jsonb;
  photo_count integer;
begin
  if auth.role() is distinct from 'service_role' then
    raise exception 'Moderator access required' using errcode = '42501';
  end if;

  select * into revision from public.listing_revisions
  where id = p_revision_id and status = 'pending_review'
  for update;
  if not found then
    raise exception 'Active pending revision not found' using errcode = 'P0002';
  end if;

  select * into draft from public.listing_drafts
  where id = revision.source_draft_id
  for update;
  if not found
     or draft.status <> 'pending_review'
     or draft.experience_id is distinct from revision.experience_id
     or draft.host_id is distinct from revision.host_id
     or draft.data is distinct from revision.data then
    raise exception 'Revision source draft is missing or inconsistent' using errcode = '23514';
  end if;

  select * into live from public.experiences
  where id = revision.experience_id and status = 'published'
  for update;
  if not found or live.host_id is distinct from revision.host_id then
    raise exception 'Published listing is missing or inconsistent' using errcode = '23514';
  end if;

  if exists (
    select 1 from public.listing_revisions other
    where other.experience_id = revision.experience_id
      and other.id <> revision.id
      and other.status in ('pending_review', 'action_required')
  ) then
    raise exception 'Revision is not the only active revision' using errcode = '23505';
  end if;

  payload := revision.data;
  photo_count := cardinality(coalesce(draft.photo_paths, '{}'));
  if photo_count > 0 and (
    p_public_photo_urls is null
    or cardinality(p_public_photo_urls) <> photo_count
    or exists (
      select 1 from unnest(p_public_photo_urls) url
      where nullif(trim(url), '') is null or url !~ '^https?://'
    )
  ) then
    raise exception 'Public photo URLs must match the ordered revision photos' using errcode = '22023';
  end if;

  update public.experiences set
    title = coalesce(nullif(trim(payload->>'title'), ''), live.title),
    summary = case when payload ? 'summary' then nullif(trim(payload->>'summary'), '') else live.summary end,
    description = case when payload ? 'description' then nullif(trim(payload->>'description'), '') else live.description end,
    category_id = coalesce(draft.category_id, live.category_id),
    location_name = case when payload ? 'public_location' then nullif(trim(payload->>'public_location'), '') else live.location_name end,
    meeting_point = case when payload ? 'meeting_point' then nullif(trim(payload->>'meeting_point'), '') else live.meeting_point end,
    lat = coalesce(nullif(payload->>'lat', '')::double precision, live.lat),
    lng = coalesce(nullif(payload->>'lng', '')::double precision, live.lng),
    duration_hours = coalesce(
      nullif(payload->>'duration_value', '')::integer
        * case when payload->>'duration_unit' = 'days' then 24 else 1 end,
      live.duration_hours
    ),
    difficulty = coalesce(nullif(payload->>'difficulty', '')::public.difficulty_level, live.difficulty),
    max_altitude_m = coalesce(nullif(payload->>'max_altitude_m', '')::integer, live.max_altitude_m),
    group_size_min = coalesce(nullif(payload->>'min_guests', '')::integer, live.group_size_min),
    group_size_max = coalesce(nullif(payload->>'max_guests', '')::integer, live.group_size_max),
    min_age = coalesce(nullif(payload->>'minimum_age', '')::integer, live.min_age),
    price_paisa = coalesce(nullif(payload->>'price_paisa', '')::bigint, live.price_paisa),
    child_price_paisa = coalesce(nullif(payload->>'child_price_paisa', '')::bigint, live.child_price_paisa),
    included = case when payload ? 'included' then array(select jsonb_array_elements_text(payload->'included')) else live.included end,
    bring_list = case when payload ? 'excluded' then array(select jsonb_array_elements_text(payload->'excluded')) else live.bring_list end,
    things_to_know = case when payload ? 'things_to_know' then array(select jsonb_array_elements_text(payload->'things_to_know')) else live.things_to_know end,
    cover_image_url = case when photo_count > 0 then p_public_photo_urls[1] else live.cover_image_url end,
    gallery = case when photo_count > 1 then p_public_photo_urls[2:photo_count] when photo_count = 1 then '{}' else live.gallery end,
    updated_at = now()
  where id = live.id;

  if payload ? 'itinerary' then
    delete from public.itinerary_items where experience_id = live.id;
    insert into public.itinerary_items
      (experience_id, day_number, start_time, title, description, sort_order)
    select
      live.id,
      ordinality::integer,
      nullif(item->>'start_time', '')::time,
      coalesce(nullif(trim(item->>'title'), ''), 'Stop ' || ordinality),
      nullif(trim(item->>'description'), ''),
      ordinality::integer
    from jsonb_array_elements(coalesce(payload->'itinerary', '[]'))
      with ordinality as entries(item, ordinality);
  end if;

  update public.listing_revisions
  set status = 'approved', reviewed_at = now(), updated_at = now()
  where id = revision.id;

  update public.listing_drafts
  set status = 'approved', reviewed_at = now(), updated_at = now()
  where id = draft.id;

  return live.id;
end;
$$;

revoke all on function public.approve_listing_revision(uuid, text[]) from public, anon, authenticated;

grant execute on function public.approve_listing_revision(uuid, text[]) to service_role;
