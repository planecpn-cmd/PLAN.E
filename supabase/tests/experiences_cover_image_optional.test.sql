-- 20260909140000: cover_image_url is optional for drafts, required at
-- pending_review / published. Guards the D3 decision on the host write path.
-- Uses seed_test.sql fixtures: v_host (approved), v_category, v_region.

begin;

do $$
declare
  v_host     constant uuid := '11111111-1111-4111-8111-000000000003';
  v_category uuid;
  v_region   uuid;
  v_id       uuid;
begin
  select id into v_category from public.categories order by created_at limit 1;
  select id into v_region   from public.regions    order by created_at limit 1;

  -- 1. a draft with no cover image inserts fine
  insert into public.experiences
    (host_id, category_id, region_id, title, slug, price_paisa, status)
  values
    (v_host, v_category, v_region, 'Draft — cover optional',
     'test-cover-optional-draft', 500000, 'draft')
  returning id into v_id;

  -- 2. promoting that row to pending_review with no cover must fail
  begin
    update public.experiences set status = 'pending_review' where id = v_id;
    raise exception 'FAIL: pending_review accepted with a NULL cover_image_url';
  exception
    when check_violation then null;  -- expected
  end;

  -- 3. promoting to published with no cover must fail
  begin
    update public.experiences set status = 'published' where id = v_id;
    raise exception 'FAIL: published accepted with a NULL cover_image_url';
  exception
    when check_violation then null;  -- expected
  end;

  -- 4. with a cover, pending_review succeeds
  update public.experiences
    set cover_image_url = 'https://example.test/cover.webp',
        status = 'pending_review'
  where id = v_id;

  if (select status from public.experiences where id = v_id)
     is distinct from 'pending_review'::public.experience_status then
    raise exception 'FAIL: pending_review with a cover did not persist';
  end if;

  -- 5. and published succeeds
  update public.experiences set status = 'published' where id = v_id;

  -- 6. clearing the cover on a published row must fail (constraint still bites)
  begin
    update public.experiences set cover_image_url = null where id = v_id;
    raise exception 'FAIL: published row allowed cover_image_url to be cleared';
  exception
    when check_violation then null;  -- expected
  end;

  -- 7. existing seed published experiences are unaffected
  if exists (
    select 1 from public.experiences
    where status = 'published' and cover_image_url is null
  ) then
    raise exception 'FAIL: a pre-existing published experience has a NULL cover';
  end if;

  raise notice 'OK: cover_image_url optional for drafts, required at review/publish';
end $$;

rollback;
