-- Published edits reuse the existing draft/revision workflow. Approved media
-- may satisfy validation when a revision keeps the current live photos.
drop function if exists public.submit_listing_draft(uuid);

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

  update public.listing_drafts set status = 'pending_review', submitted_at = now()
  where id = draft.id;

  if draft.experience_id is not null then
    insert into public.listing_revisions(experience_id, host_id, source_draft_id, data)
    values (draft.experience_id, draft.host_id, draft.id, draft.data);
  end if;

  return draft.id;
end;
$$;

revoke all on function public.submit_listing_draft(uuid) from public, anon;

grant execute on function public.submit_listing_draft(uuid) to authenticated;
