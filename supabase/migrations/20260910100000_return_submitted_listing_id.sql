-- Submission is successful only when the locked, owned draft reaches the
-- canonical pending-review state. Returning the ID lets clients verify that
-- persistence completed before showing success or navigating away.
drop function if exists public.submit_listing_draft(uuid);

create or replace function public.submit_listing_draft(p_draft_id uuid)
returns uuid language plpgsql security definer set search_path = public, private as $$
declare draft public.listing_drafts%rowtype;
begin
  if auth.uid() is null or not private.is_approved_active_host(auth.uid()) then
    raise exception 'Approved host access required';
  end if;

  select * into draft
  from public.listing_drafts
  where id = p_draft_id
    and host_id = auth.uid()
    and status in ('draft', 'action_required')
  for update;
  if not found then raise exception 'Editable draft not found'; end if;

  perform private.validate_listing_draft(
    draft.listing_type,
    draft.category_id,
    draft.data,
    draft.cover_photo_path,
    draft.photo_paths
  );

  update public.listing_drafts
  set status = 'pending_review', submitted_at = now()
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
