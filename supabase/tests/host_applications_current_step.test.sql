-- host_applications.current_step CHECK must match the live questionnaire flow.
--
-- The Flutter questionnaire (lib/features/host/host_questionnaire_screen.dart) and
-- the shared web flow run 8 steps; HostRepository.saveQuestionnaireDraft clamps to
-- 1..8 and, from step 7, writes current_step = 8. Migration 0011 originally bounded
-- the column at 1..4; 20260906120000_shared_host_questionnaire.sql widened it to
-- 1..8. This test is the permanent guard that the bound is 8, not narrower and not
-- unbounded, so a real user completing the flow is never rejected by the DB and a
-- future migration cannot silently re-narrow it.
--
-- Uses seed_test.sql fixture 11111111-...-000000000001 (traveler), which has no
-- host_applications row (host_applications.user_id is UNIQUE).

begin;

do $$
declare
  v_user   constant uuid := '11111111-1111-4111-8111-000000000001';
  v_id     uuid;
  v_step   int;
begin
  -- step 8 must be accepted
  insert into public.host_applications (user_id, status, current_step)
  values (v_user, 'draft', 8)
  returning id into v_id;

  select current_step into v_step from public.host_applications where id = v_id;
  if v_step is distinct from 8 then
    raise exception 'FAIL: step-8 write did not persist current_step (got %)', v_step;
  end if;

  -- free the unique(user_id) slot before the negative cases
  delete from public.host_applications where id = v_id;

  -- step 9 must be rejected by host_applications_current_step_check
  begin
    insert into public.host_applications (user_id, status, current_step)
    values (v_user, 'draft', 9);
    raise exception 'FAIL: current_step = 9 was accepted; CHECK constraint is too wide';
  exception
    when check_violation then null;  -- expected
  end;

  -- step 0 must be rejected too
  begin
    insert into public.host_applications (user_id, status, current_step)
    values (v_user, 'draft', 0);
    raise exception 'FAIL: current_step = 0 was accepted; CHECK constraint is too wide';
  exception
    when check_violation then null;  -- expected
  end;

  raise notice 'OK: host_applications.current_step accepts 8, rejects 0 and 9';
end $$;

rollback;
