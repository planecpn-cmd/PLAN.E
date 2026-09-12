-- H1 core (4/4): host submits a draft experience for admin review.
--
-- The only client path to move experiences.status draft -> pending_review.
-- The client can never reach 'published' -- that is an admin content:manage
-- action (the review queue, N1, is a later node). This RPC just flips a
-- complete draft into the queue.
--
-- Completeness is checked with clear messages before the flip (title,
-- description, location, a cover photo, a positive price, an open departure);
-- the experiences_cover_image_required CHECK (20260909140000) is the backstop.
-- The cover check is satisfiable now that the photo slice (20260909190000)
-- uploads real photos -- see host_write_end_to_end.test.sql.

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
    raise exception 'An approved, active host account is required'
      using errcode = '42501';
  end if;

  select id, status, title, description, location_name, cover_image_url, price_paisa
    into v_exp
  from public.experiences
  where id = p_experience_id and host_id = v_uid
  for update;

  if not found then
    raise exception 'Experience not found or not owned by the caller'
      using errcode = '42501';
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
  if not exists (
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

revoke execute on function public.host_submit_experience_for_review(uuid)
  from public, anon;
grant execute on function public.host_submit_experience_for_review(uuid)
  to authenticated;
