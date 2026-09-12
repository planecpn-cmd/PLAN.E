-- Shared, category-driven host listing drafts for Flutter and web.
-- Submission is moderation-only: these functions never publish catalog rows.

create table public.listing_type_configs (
  key text primary key check (key in ('adventure', 'experience', 'stay', 'tour_package', 'community_activity')),
  label text not null,
  config jsonb not null default '{}'::jsonb,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  updated_at timestamptz not null default now()
);

insert into public.listing_type_configs (key, label, sort_order, config) values
  ('adventure', 'Adventure', 10, '{"category_slugs":["trekking","hiking","camping","climbing","wildlife"],"requires_itinerary":true,"schedule_model":"dated","pricing_model":"per_person","detail_fields":["difficulty","minimum_age","maximum_altitude_m","fitness_level","gear"]}'),
  ('experience', 'Experience', 20, '{"category_slugs":["culture","wellness","volunteering"],"requires_itinerary":false,"schedule_model":"flexible","pricing_model":"per_person","detail_fields":["language","accessibility","skill_level"]}'),
  ('stay', 'Stay', 30, '{"category_slugs":["homestay"],"requires_itinerary":false,"schedule_model":"nightly_inventory","pricing_model":"per_room","detail_fields":["property_type","provider_relationship","check_in","check_out"]}'),
  ('tour_package', 'Tour / Package', 40, '{"category_slugs":["travel-package","multi-day-tour"],"requires_itinerary":true,"schedule_model":"dated","pricing_model":"per_person","detail_fields":["transport","difficulty","minimum_age"]}'),
  ('community_activity', 'Community Activity', 50, '{"category_slugs":["community-event"],"requires_itinerary":false,"schedule_model":"dated","pricing_model":"per_person","detail_fields":["organizer","accessibility","minimum_age"]}')
on conflict (key) do update set label = excluded.label, config = excluded.config,
  sort_order = excluded.sort_order, is_active = true, updated_at = now();

create table public.listing_drafts (
  id uuid primary key default gen_random_uuid(),
  host_id uuid not null references public.profiles(id) on delete cascade,
  listing_type text not null references public.listing_type_configs(key),
  category_id uuid references public.categories(id) on delete restrict,
  experience_id uuid references public.experiences(id) on delete set null,
  current_step integer not null default 0 check (current_step >= 0),
  status text not null default 'draft' check (status in ('draft', 'action_required', 'pending_review', 'approved', 'rejected')),
  data jsonb not null default '{}'::jsonb,
  cover_photo_path text,
  photo_paths text[] not null default '{}',
  reviewer_note text,
  submitted_at timestamptz,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger set_listing_drafts_updated_at before update on public.listing_drafts
for each row execute function public.set_updated_at();

create index listing_drafts_host_updated_idx on public.listing_drafts(host_id, updated_at desc);

create unique index listing_drafts_one_pending_edit_idx on public.listing_drafts(experience_id)
where experience_id is not null and status = 'pending_review';

create table public.listing_revisions (
  id uuid primary key default gen_random_uuid(),
  experience_id uuid not null references public.experiences(id) on delete cascade,
  host_id uuid not null references public.profiles(id) on delete cascade,
  source_draft_id uuid not null unique references public.listing_drafts(id) on delete restrict,
  data jsonb not null,
  status text not null default 'pending_review' check (status in ('pending_review', 'approved', 'rejected')),
  reviewer_note text,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger set_listing_revisions_updated_at before update on public.listing_revisions
for each row execute function public.set_updated_at();

create unique index listing_revisions_one_pending_idx on public.listing_revisions(experience_id)
where status = 'pending_review';

create table public.accommodation_providers (
  id uuid primary key default gen_random_uuid(),
  host_id uuid not null references public.profiles(id) on delete cascade,
  provider_type text not null check (provider_type in ('individual', 'business', 'organization')),
  relationship text not null check (relationship in ('owner', 'manager', 'authorized_representative')),
  display_name text not null,
  business_name text,
  status text not null default 'active' check (status in ('active', 'inactive')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger set_accommodation_providers_updated_at before update on public.accommodation_providers
for each row execute function public.set_updated_at();

create table public.accommodation_properties (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references public.accommodation_providers(id) on delete restrict,
  host_id uuid not null references public.profiles(id) on delete cascade,
  source_draft_id uuid unique references public.listing_drafts(id) on delete set null,
  category_id uuid not null references public.categories(id) on delete restrict,
  name text not null,
  property_type text not null,
  summary text,
  description text not null,
  country text not null,
  province text,
  district text,
  area text,
  public_location text not null,
  operational_address text not null,
  lat double precision,
  lng double precision,
  amenities text[] not null default '{}',
  policies jsonb not null default '{}'::jsonb,
  check_in_from time not null,
  check_in_until time,
  check_out_until time not null,
  cover_image_url text not null,
  gallery text[] not null default '{}',
  status text not null default 'pending_review' check (status in ('pending_review', 'published', 'paused', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger set_accommodation_properties_updated_at before update on public.accommodation_properties
for each row execute function public.set_updated_at();

create table public.accommodation_units (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references public.accommodation_properties(id) on delete cascade,
  name text not null,
  units_total integer not null check (units_total > 0),
  max_adults integer not null check (max_adults > 0),
  max_children integer not null default 0 check (max_children >= 0),
  bed_type text,
  bed_count integer check (bed_count is null or bed_count > 0),
  bathroom_type text,
  size_sqm numeric check (size_sqm is null or size_sqm > 0),
  amenities text[] not null default '{}',
  photo_urls text[] not null default '{}',
  nightly_rate_paisa bigint not null check (nightly_rate_paisa > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger set_accommodation_units_updated_at before update on public.accommodation_units
for each row execute function public.set_updated_at();

create table public.accommodation_inventory (
  id uuid primary key default gen_random_uuid(),
  unit_id uuid not null references public.accommodation_units(id) on delete cascade,
  date date not null,
  units_available integer not null check (units_available >= 0),
  rate_override_paisa bigint check (rate_override_paisa is null or rate_override_paisa > 0),
  unique (unit_id, date)
);

create index accommodation_inventory_date_idx on public.accommodation_inventory(date, unit_id);

alter table public.listing_type_configs enable row level security;

alter table public.listing_drafts enable row level security;

alter table public.listing_revisions enable row level security;

alter table public.accommodation_providers enable row level security;

alter table public.accommodation_properties enable row level security;

alter table public.accommodation_units enable row level security;

alter table public.accommodation_inventory enable row level security;

create policy listing_type_configs_read on public.listing_type_configs for select using (is_active);

create policy listing_drafts_host_read on public.listing_drafts for select to authenticated
using (host_id = auth.uid() and private.is_approved_active_host(auth.uid()));

create policy listing_revisions_host_read on public.listing_revisions for select to authenticated
using (host_id = auth.uid() and private.is_approved_active_host(auth.uid()));

create policy accommodation_providers_host_all on public.accommodation_providers for all to authenticated
using (host_id = auth.uid() and private.is_approved_active_host(auth.uid()))
with check (host_id = auth.uid() and private.is_approved_active_host(auth.uid()));

create policy accommodation_properties_public_read on public.accommodation_properties for select
using (status = 'published' or (auth.uid() = host_id and private.is_approved_active_host(auth.uid())));

create policy accommodation_properties_host_write on public.accommodation_properties for all to authenticated
using (host_id = auth.uid() and private.is_approved_active_host(auth.uid()))
with check (host_id = auth.uid() and private.is_approved_active_host(auth.uid()));

create policy accommodation_units_read on public.accommodation_units for select
using (exists (select 1 from public.accommodation_properties p where p.id = property_id and (p.status = 'published' or p.host_id = auth.uid())));

create policy accommodation_units_host_write on public.accommodation_units for all to authenticated
using (exists (select 1 from public.accommodation_properties p where p.id = property_id and p.host_id = auth.uid() and private.is_approved_active_host(auth.uid())))
with check (exists (select 1 from public.accommodation_properties p where p.id = property_id and p.host_id = auth.uid() and private.is_approved_active_host(auth.uid())));

create policy accommodation_inventory_read on public.accommodation_inventory for select
using (exists (select 1 from public.accommodation_units u join public.accommodation_properties p on p.id = u.property_id where u.id = unit_id and (p.status = 'published' or p.host_id = auth.uid())));

create policy accommodation_inventory_host_write on public.accommodation_inventory for all to authenticated
using (exists (select 1 from public.accommodation_units u join public.accommodation_properties p on p.id = u.property_id where u.id = unit_id and p.host_id = auth.uid() and private.is_approved_active_host(auth.uid())))
with check (exists (select 1 from public.accommodation_units u join public.accommodation_properties p on p.id = u.property_id where u.id = unit_id and p.host_id = auth.uid() and private.is_approved_active_host(auth.uid())));

revoke all on public.listing_type_configs, public.listing_drafts, public.listing_revisions,
  public.accommodation_providers, public.accommodation_properties, public.accommodation_units,
  public.accommodation_inventory from anon, authenticated;

grant select on public.listing_type_configs to anon, authenticated;

grant select on public.listing_drafts, public.listing_revisions to authenticated;

grant select, insert, update, delete on public.accommodation_providers, public.accommodation_properties,
  public.accommodation_units, public.accommodation_inventory to authenticated;

create or replace function private.validate_listing_draft(
  draft_type text, category uuid, payload jsonb, cover_path text, photos text[]
) returns void language plpgsql security definer set search_path = public, private as $$
declare
  allowed boolean;
  item jsonb;
begin
  select exists (
    select 1 from public.listing_type_configs cfg join public.categories c on c.id = category
    where cfg.key = draft_type and cfg.is_active and cfg.config->'category_slugs' ? c.slug
  ) into allowed;
  if not allowed then raise exception 'Select a category valid for this listing type'; end if;
  if length(trim(coalesce(payload->>'title', ''))) not between 5 and 80 then raise exception 'Title must be 5 to 80 characters'; end if;
  if payload->>'title' ~* '(https?://|www\.|[[:alnum:]._%+-]+@[[:alnum:].-]+\.[[:alpha:]]{2,}|\+?[0-9][0-9 ()-]{7,})' then raise exception 'Title cannot contain contact or booking information'; end if;
  if length(trim(coalesce(payload->>'description', ''))) < 30 then raise exception 'Description must be at least 30 characters'; end if;
  if trim(coalesce(payload->>'public_location', '')) = '' then raise exception 'Public location is required'; end if;
  if coalesce((payload->>'price_paisa')::bigint, 0) <= 0 then raise exception 'A positive price is required'; end if;
  if coalesce(array_length(photos, 1), 0) = 0 or cover_path is null then raise exception 'At least one photo and a cover photo are required'; end if;
  if jsonb_typeof(payload->'included') <> 'array' or jsonb_array_length(payload->'included') = 0 then raise exception 'Add at least one inclusion'; end if;
  if trim(coalesce(payload->>'cancellation_policy', '')) = '' then raise exception 'Cancellation policy is required'; end if;
  if draft_type in ('adventure', 'tour_package') and (jsonb_typeof(payload->'itinerary') <> 'array' or jsonb_array_length(payload->'itinerary') = 0) then raise exception 'An itinerary is required'; end if;
  if draft_type = 'stay' then
    if jsonb_typeof(payload->'provider') <> 'object' or jsonb_typeof(payload->'property') <> 'object' then raise exception 'Provider and property details are required'; end if;
    if jsonb_typeof(payload->'rooms') <> 'array' or jsonb_array_length(payload->'rooms') = 0 then raise exception 'Add at least one room type'; end if;
    for item in select value from jsonb_array_elements(payload->'rooms') loop
      if coalesce((item->>'units_total')::int, 0) <= 0 or coalesce((item->>'max_adults')::int, 0) <= 0 or coalesce((item->>'nightly_rate_paisa')::bigint, 0) <= 0 then
        raise exception 'Every room needs units, occupancy, and a nightly rate';
      end if;
    end loop;
    if trim(coalesce(payload->>'operational_address', '')) = '' then raise exception 'Property address is required'; end if;
    if payload->>'check_in_from' is null or payload->>'check_out_until' is null then raise exception 'Check-in and check-out times are required'; end if;
  end if;
end;
$$;

create or replace function public.save_listing_draft(
  p_listing_type text, p_category_id uuid, p_current_step integer, p_data jsonb,
  p_cover_photo_path text default null, p_photo_paths text[] default '{}', p_draft_id uuid default null,
  p_experience_id uuid default null
) returns uuid language plpgsql security definer set search_path = public, private as $$
declare result_id uuid; user_id uuid := auth.uid();
begin
  if user_id is null or not private.is_approved_active_host(user_id) then raise exception 'Approved host access required'; end if;
  if not exists (select 1 from public.listing_type_configs where key = p_listing_type and is_active) then raise exception 'Invalid listing type'; end if;
  if p_category_id is not null and not exists (
    select 1 from public.listing_type_configs cfg join public.categories c on c.id = p_category_id
    where cfg.key = p_listing_type and cfg.config->'category_slugs' ? c.slug
  ) then raise exception 'Category does not belong to this listing type'; end if;
  if p_experience_id is not null and not exists (select 1 from public.experiences where id = p_experience_id and host_id = user_id) then raise exception 'Listing not found'; end if;
  if p_draft_id is null then
    insert into public.listing_drafts(host_id, listing_type, category_id, experience_id, current_step, data, cover_photo_path, photo_paths)
    values (user_id, p_listing_type, p_category_id, p_experience_id, greatest(p_current_step, 0), coalesce(p_data, '{}'), p_cover_photo_path, coalesce(p_photo_paths, '{}')) returning id into result_id;
  else
    update public.listing_drafts set listing_type = p_listing_type, category_id = p_category_id,
      current_step = greatest(p_current_step, 0), data = coalesce(p_data, '{}'), cover_photo_path = p_cover_photo_path,
      photo_paths = coalesce(p_photo_paths, '{}'), status = case when status = 'action_required' then 'draft' else status end
    where id = p_draft_id and host_id = user_id and status in ('draft', 'action_required') returning id into result_id;
    if result_id is null then raise exception 'Editable draft not found'; end if;
  end if;
  return result_id;
end;
$$;

create or replace function public.submit_listing_draft(p_draft_id uuid)
returns void language plpgsql security definer set search_path = public, private as $$
declare draft public.listing_drafts%rowtype;
begin
  if auth.uid() is null or not private.is_approved_active_host(auth.uid()) then raise exception 'Approved host access required'; end if;
  select * into draft from public.listing_drafts where id = p_draft_id and host_id = auth.uid() and status in ('draft', 'action_required') for update;
  if not found then raise exception 'Editable draft not found'; end if;
  perform private.validate_listing_draft(draft.listing_type, draft.category_id, draft.data, draft.cover_photo_path, draft.photo_paths);
  update public.listing_drafts set status = 'pending_review', submitted_at = now() where id = draft.id;
  if draft.experience_id is not null then
    insert into public.listing_revisions(experience_id, host_id, source_draft_id, data)
    values (draft.experience_id, draft.host_id, draft.id, draft.data);
  end if;
end;
$$;

revoke all on function private.validate_listing_draft(text, uuid, jsonb, text, text[]) from public, anon, authenticated;

revoke all on function public.save_listing_draft(text, uuid, integer, jsonb, text, text[], uuid, uuid) from public, anon;

revoke all on function public.submit_listing_draft(uuid) from public, anon;

grant execute on function public.save_listing_draft(text, uuid, integer, jsonb, text, text[], uuid, uuid) to authenticated;

grant execute on function public.submit_listing_draft(uuid) to authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('listing-media', 'listing-media', false, 10485760, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public = false, file_size_limit = excluded.file_size_limit, allowed_mime_types = excluded.allowed_mime_types;

create policy listing_media_host_insert on storage.objects for insert to authenticated
with check (bucket_id = 'listing-media' and (storage.foldername(name))[1] = auth.uid()::text and private.is_approved_active_host(auth.uid()));

create policy listing_media_host_read on storage.objects for select to authenticated
using (bucket_id = 'listing-media' and (storage.foldername(name))[1] = auth.uid()::text and private.is_approved_active_host(auth.uid()));

create policy listing_media_host_update on storage.objects for update to authenticated
using (bucket_id = 'listing-media' and (storage.foldername(name))[1] = auth.uid()::text and private.is_approved_active_host(auth.uid()))
with check (bucket_id = 'listing-media' and (storage.foldername(name))[1] = auth.uid()::text and private.is_approved_active_host(auth.uid()));

create policy listing_media_host_delete on storage.objects for delete to authenticated
using (bucket_id = 'listing-media' and (storage.foldername(name))[1] = auth.uid()::text and private.is_approved_active_host(auth.uid()));
