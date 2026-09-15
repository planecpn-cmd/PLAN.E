-- Keep change requests attached to the same draft/revision and preserve the
-- approved experience while a published edit is corrected.
alter table public.listing_revisions
  drop constraint if exists listing_revisions_status_check;

alter table public.listing_revisions
  add constraint listing_revisions_status_check
  check (status in ('action_required', 'pending_review', 'approved', 'rejected'));

drop index if exists public.listing_revisions_one_pending_idx;

create unique index listing_revisions_one_open_per_experience
on public.listing_revisions(experience_id)
where status in ('action_required', 'pending_review');

create or replace function public.request_listing_changes(
  p_draft_id uuid,
  p_reviewer_note text default null
) returns uuid language plpgsql security definer set search_path = public, private as $$
declare
  target public.listing_drafts%rowtype;
begin
  if auth.role() <> 'service_role' then
    raise exception 'Moderator access required';
  end if;

  select * into target from public.listing_drafts
  where id = p_draft_id and status = 'pending_review' for update;
  if not found then raise exception 'Pending listing not found'; end if;

  update public.listing_drafts
  set status = 'action_required', reviewer_note = nullif(trim(p_reviewer_note), ''),
      reviewed_at = now(), updated_at = now()
  where id = target.id;

  if target.experience_id is not null then
    update public.listing_revisions
    set status = 'action_required', reviewer_note = nullif(trim(p_reviewer_note), ''),
        reviewed_at = now(), updated_at = now()
    where source_draft_id = target.id and status = 'pending_review';
    if not found then raise exception 'Pending revision not found'; end if;
  end if;
  return target.id;
end;
$$;

revoke all on function public.request_listing_changes(uuid, text) from public, anon, authenticated;

grant execute on function public.request_listing_changes(uuid, text) to service_role;

-- Saving corrections must not erase the moderation state or its feedback.
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
  if p_experience_id is not null and not exists (
    select 1 from public.experiences where id = p_experience_id and host_id = user_id
  ) then raise exception 'Listing not found'; end if;
  if p_draft_id is null then
    insert into public.listing_drafts(host_id, listing_type, category_id, experience_id, current_step, data, cover_photo_path, photo_paths)
    values (user_id, p_listing_type, p_category_id, p_experience_id, greatest(p_current_step, 0), coalesce(p_data, '{}'), p_cover_photo_path, coalesce(p_photo_paths, '{}'))
    returning id into result_id;
  else
    update public.listing_drafts
    set listing_type = p_listing_type, category_id = p_category_id,
        current_step = greatest(p_current_step, 0), data = coalesce(p_data, '{}'),
        cover_photo_path = p_cover_photo_path, photo_paths = coalesce(p_photo_paths, '{}')
    where id = p_draft_id and host_id = user_id and status in ('draft', 'action_required')
    returning id into result_id;
    if result_id is null then raise exception 'Editable draft not found'; end if;
  end if;
  return result_id;
end;
$$;

revoke all on function public.save_listing_draft(text, uuid, integer, jsonb, text, text[], uuid, uuid) from public, anon;

grant execute on function public.save_listing_draft(text, uuid, integer, jsonb, text, text[], uuid, uuid) to authenticated;

create or replace function public.submit_listing_draft(p_draft_id uuid)
returns uuid language plpgsql security definer set search_path = public, private as $$
declare
  draft public.listing_drafts%rowtype;
  live public.experiences%rowtype;
  validation_cover text;
  validation_photos text[];
begin
  if auth.uid() is null or not private.is_approved_active_host(auth.uid()) then
    raise exception 'Approved host access required';
  end if;

  select * into draft from public.listing_drafts
  where id = p_draft_id and host_id = auth.uid()
    and status in ('draft', 'action_required') for update;
  if not found then raise exception 'Editable draft not found'; end if;

  validation_cover := draft.cover_photo_path;
  validation_photos := draft.photo_paths;
  if draft.experience_id is not null then
    select * into live from public.experiences
    where id = draft.experience_id and host_id = auth.uid() and status = 'published';
    if not found then raise exception 'Published listing not found'; end if;
    validation_cover := coalesce(validation_cover, live.cover_image_url);
    validation_photos := array_prepend(live.cover_image_url, coalesce(live.gallery, '{}'))
      || coalesce(validation_photos, '{}');
  end if;

  perform private.validate_listing_draft(
    draft.listing_type, draft.category_id, draft.data,
    validation_cover, validation_photos
  );

  update public.listing_drafts
  set status = 'pending_review', submitted_at = now(), reviewer_note = null,
      reviewed_at = null, updated_at = now()
  where id = draft.id;

  if draft.experience_id is not null then
    insert into public.listing_revisions(experience_id, host_id, source_draft_id, data)
    values (draft.experience_id, draft.host_id, draft.id, draft.data)
    on conflict (source_draft_id) do update
    set data = excluded.data, status = 'pending_review', reviewer_note = null,
        reviewed_at = null, updated_at = now();
  end if;
  return draft.id;
end;
$$;

revoke all on function public.submit_listing_draft(uuid) from public, anon;

grant execute on function public.submit_listing_draft(uuid) to authenticated;
