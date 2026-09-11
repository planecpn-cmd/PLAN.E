create or replace function private.validate_listing_draft(
  draft_type text, category uuid, payload jsonb, cover_path text, photos text[]
) returns void language plpgsql security definer set search_path = public, private as $$
declare allowed boolean; item jsonb;
begin
  select exists (select 1 from public.listing_type_configs cfg join public.categories c on c.id = category
    where cfg.key = draft_type and cfg.is_active and cfg.config->'category_slugs' ? c.slug) into allowed;
  if not allowed then raise exception 'Select a category valid for this listing type'; end if;
  if length(trim(coalesce(payload->>'title', ''))) not between 5 and 80 then raise exception 'Title must be 5 to 80 characters'; end if;
  if payload->>'title' ~* '(https?://|www\.|[[:alnum:]._%+-]+@[[:alnum:].-]+\.[[:alpha:]]{2,}|\+?[0-9][0-9 ()-]{7,})' then raise exception 'Title cannot contain contact or booking information'; end if;
  if length(trim(coalesce(payload->>'description', ''))) < 30 then raise exception 'Description must be at least 30 characters'; end if;
  if trim(coalesce(payload->>'public_location', '')) = '' then raise exception 'Public location is required'; end if;
  if coalesce((payload->>'price_paisa')::bigint, 0) <= 0 then raise exception 'A positive price is required'; end if;
  if coalesce(array_length(photos, 1), 0) = 0 or cover_path is null then raise exception 'At least one photo and a cover photo are required'; end if;
  if jsonb_typeof(payload->'included') <> 'array' or jsonb_array_length(payload->'included') = 0 then raise exception 'Add at least one inclusion'; end if;
  if trim(coalesce(payload->>'cancellation_policy', '')) = '' then raise exception 'Cancellation policy is required'; end if;
  if draft_type <> 'stay' then
    if coalesce((payload->>'duration_value')::numeric, 0) <= 0 or payload->>'duration_unit' not in ('hours','days') then raise exception 'A valid duration is required'; end if;
    if trim(coalesce(payload->>'schedule_type', '')) = '' then raise exception 'Availability model is required'; end if;
    if coalesce((payload->>'max_guests')::int, 0) <= 0 or coalesce((payload->>'min_guests')::int, 0) <= 0 or (payload->>'min_guests')::int > (payload->>'max_guests')::int then raise exception 'Enter a valid participant capacity'; end if;
  end if;
  if draft_type in ('adventure', 'tour_package') and (jsonb_typeof(payload->'itinerary') <> 'array' or jsonb_array_length(payload->'itinerary') = 0) then raise exception 'An itinerary is required'; end if;
  if draft_type = 'stay' then
    if jsonb_typeof(payload->'provider') <> 'object' or jsonb_typeof(payload->'property') <> 'object' then raise exception 'Provider and property details are required'; end if;
    if jsonb_typeof(payload->'rooms') <> 'array' or jsonb_array_length(payload->'rooms') = 0 then raise exception 'Add at least one room type'; end if;
    for item in select value from jsonb_array_elements(payload->'rooms') loop
      if coalesce((item->>'units_total')::int, 0) <= 0 or coalesce((item->>'max_adults')::int, 0) <= 0 or coalesce((item->>'nightly_rate_paisa')::bigint, 0) <= 0 then raise exception 'Every room needs units, occupancy, and a nightly rate'; end if;
    end loop;
    if trim(coalesce(payload->>'operational_address', '')) = '' then raise exception 'Property address is required'; end if;
    if payload->>'check_in_from' is null or payload->>'check_out_until' is null then raise exception 'Check-in and check-out times are required'; end if;
  end if;
end;
$$;

revoke all on function private.validate_listing_draft(text, uuid, jsonb, text, text[]) from public, anon, authenticated;
