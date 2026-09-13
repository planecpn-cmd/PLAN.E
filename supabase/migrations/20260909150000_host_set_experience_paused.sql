-- H1 core (1/4): host pauses / resumes their own published listing.
--
-- Client cannot write experiences directly (insert/update/delete revoked from
-- authenticated in 20260823120000). This SECURITY DEFINER RPC is the only path.
-- It never produces 'published' from nothing -- it only toggles an already
-- published listing to 'paused' and back.

create or replace function public.host_set_experience_paused(
  p_experience_id uuid,
  p_paused boolean
)
returns public.experience_status
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid    uuid := auth.uid();
  v_status public.experience_status;
  v_new    public.experience_status;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;
  if not private.is_approved_active_host(v_uid) then
    raise exception 'An approved, active host account is required'
      using errcode = '42501';
  end if;

  select status into v_status
  from public.experiences
  where id = p_experience_id and host_id = v_uid
  for update;

  if not found then
    raise exception 'Experience not found or not owned by the caller'
      using errcode = '42501';
  end if;

  if p_paused and v_status <> 'published'::public.experience_status then
    raise exception 'Only a published experience can be paused (status is %)',
      v_status using errcode = '22023';
  end if;
  if not p_paused and v_status <> 'paused'::public.experience_status then
    raise exception 'Only a paused experience can be resumed (status is %)',
      v_status using errcode = '22023';
  end if;

  v_new := case when p_paused
    then 'paused'::public.experience_status
    else 'published'::public.experience_status
  end;

  update public.experiences
    set status = v_new, updated_at = now()
  where id = p_experience_id;

  return v_new;
end;
$$;

revoke execute on function public.host_set_experience_paused(uuid, boolean)
  from public, anon;
grant execute on function public.host_set_experience_paused(uuid, boolean)
  to authenticated;
