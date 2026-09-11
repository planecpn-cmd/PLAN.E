-- Client-readable readiness rules. Backend validation remains authoritative.
update public.listing_type_configs
set config = config || jsonb_build_object(
  'minimum_photos', 1,
  'requires_location', true,
  'requires_price', true,
  'requires_capacity', key <> 'stay',
  'requires_schedule', key <> 'stay',
  'requires_excluded', true
), updated_at = now();

create or replace function private.validate_listing_draft(
  draft_type text, category uuid, payload jsonb, cover_path text, photos text[]
) returns void language plpgsql security definer set search_path = public, private as $$
declare allowed boolean; item jsonb; minimum_photos integer;
begin
  select exists (select 1 from public.listing_type_configs cfg join public.categories c on c.id = category
    where cfg.key = draft_type and cfg.is_active and cfg.config->'category_slugs' ? c.slug),
    coalesce((select (config->>'minimum_photos')::integer from public.listing_type_configs where key = draft_type), 1)
    into allowed, minimum_photos;
  if not allowed then raise exception 'Choose a category for this listing'; end if;
  if length(trim(coalesce(payload->>'title', ''))) not between 5 and 80 then raise exception 'Add a title between 5 and 80 characters'; end if;
  if payload->>'title' ~* '(https?://|www\.|[[:alnum:]._%+-]+@[[:alnum:].-]+\.[[:alpha:]]{2,}|\+?[0-9][0-9 ()-]{7,})' then raise exception 'Title cannot contain contact or booking information'; end if;
  if length(trim(coalesce(payload->>'description', ''))) < 30 then raise exception 'Add a description of at least 30 characters'; end if;
  if trim(coalesce(payload->>'public_location', '')) = '' then raise exception 'Add a location'; end if;
  if coalesce((payload->>'price_paisa')::bigint, 0) <= 0 then raise exception 'Add a valid price'; end if;
  if coalesce(array_length(photos, 1), 0) < minimum_photos or cover_path is null then raise exception 'Upload the required listing photos'; end if;
  if jsonb_typeof(payload->'included') <> 'array' or jsonb_array_length(payload->'included') = 0 then raise exception 'Add what is included'; end if;
  if jsonb_typeof(payload->'excluded') <> 'array' or jsonb_array_length(payload->'excluded') = 0 then raise exception 'Add what is not included'; end if;
  if trim(coalesce(payload->>'cancellation_policy', '')) = '' then raise exception 'Add a cancellation policy'; end if;
  if draft_type <> 'stay' then
    if coalesce((payload->>'duration_value')::numeric, 0) <= 0 or payload->>'duration_unit' not in ('hours','days') then raise exception 'Add a valid duration'; end if;
    if trim(coalesce(payload->>'schedule_type', '')) = '' then raise exception 'Add availability'; end if;
    if coalesce((payload->>'max_guests')::int, 0) <= 0 or coalesce((payload->>'min_guests')::int, 0) <= 0 or (payload->>'min_guests')::int > (payload->>'max_guests')::int then raise exception 'Add a valid participant capacity'; end if;
  end if;
  if draft_type in ('adventure', 'tour_package') and (jsonb_typeof(payload->'itinerary') <> 'array' or jsonb_array_length(payload->'itinerary') = 0) then raise exception 'Add an itinerary'; end if;
  if draft_type = 'stay' then
    if jsonb_typeof(payload->'provider') <> 'object' or trim(coalesce(payload->'provider'->>'display_name', '')) = '' or jsonb_typeof(payload->'property') <> 'object' or trim(coalesce(payload->'property'->>'name', '')) = '' then raise exception 'Add provider and property details'; end if;
    if jsonb_typeof(payload->'rooms') <> 'array' or jsonb_array_length(payload->'rooms') = 0 then raise exception 'Add at least one room type'; end if;
    if jsonb_typeof(payload->'inventory') <> 'object' or coalesce((payload->'inventory'->>'units_available')::int, 0) <= 0 then raise exception 'Add available room inventory'; end if;
    for item in select value from jsonb_array_elements(payload->'rooms') loop
      if coalesce((item->>'units_total')::int, 0) <= 0 or coalesce((item->>'max_adults')::int, 0) <= 0 or coalesce((item->>'nightly_rate_paisa')::bigint, 0) <= 0 then raise exception 'Complete room inventory, occupancy and rate'; end if;
    end loop;
    if trim(coalesce(payload->>'operational_address', '')) = '' then raise exception 'Add the property address'; end if;
    if payload->>'check_in_from' is null or payload->>'check_out_until' is null then raise exception 'Add check-in and check-out times'; end if;
  end if;
end;
$$;

revoke all on function private.validate_listing_draft(text, uuid, jsonb, text, text[]) from public, anon, authenticated;
