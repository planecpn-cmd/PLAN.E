-- =============================================================================
-- host_review_rls.test.sql  —  P2 scope split + write boundaries
-- =============================================================================
-- hosts:review reads review history + documents and may NOT write a decision
-- row or move a status via direct JWT. hosts:decide reads too, and its writes
-- also go only through the service-role backend (no client insert policy on
-- either new table; host_applications.status stays service_role-only). Both
-- layers, per the node spec.
-- =============================================================================

begin;

do $$
declare
  v_founder  uuid := 'ba000000-0000-4000-8000-000000000001';  -- all 8 scopes + role=admin
  v_reviewer uuid := 'ba000000-0000-4000-8000-000000000002';  -- {hosts:review}
  v_decider  uuid := 'ba000000-0000-4000-8000-000000000003';  -- {hosts:review, hosts:decide} (a decider is also a reviewer)
  v_payer    uuid := 'ba000000-0000-4000-8000-000000000004';  -- {payments:read}
  v_susp     uuid := 'ba000000-0000-4000-8000-000000000005';  -- suspended, {hosts:review,hosts:decide}
  v_other    uuid := 'ba000000-0000-4000-8000-000000000006';  -- plain traveler
  v_applicant uuid := 'ba000000-0000-4000-8000-000000000007';
  v_decideonly uuid := 'ba000000-0000-4000-8000-000000000008';  -- {hosts:decide} only — cannot see anything to decide on
  v_app  uuid := 'ba000000-0000-4000-8000-0000000000a1';
begin
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);

  insert into auth.users (id, instance_id, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role, aud)
  select u, '00000000-0000-0000-0000-000000000000', u::text || '@hr.test', 'x', now(),
    '{"provider":"email","providers":["email"]}', '{}', now(), now(), 'authenticated', 'authenticated'
  from unnest(array[v_founder, v_reviewer, v_decider, v_payer, v_susp, v_other, v_applicant, v_decideonly]) u
  on conflict (id) do nothing;

  insert into public.profiles (id, full_name, role)
  values
    (v_founder,  'HR Founder',  'admin'::public.user_role),
    (v_reviewer, 'HR Reviewer', 'traveler'::public.user_role),
    (v_decider,  'HR Decider',  'traveler'::public.user_role),
    (v_payer,    'HR Payer',    'traveler'::public.user_role),
    (v_susp,     'HR Suspended','traveler'::public.user_role),
    (v_other,    'HR Other',    'traveler'::public.user_role),
    (v_applicant,'HR Applicant','traveler'::public.user_role),
    (v_decideonly,'HR DecideOnly','traveler'::public.user_role)
  on conflict (id) do update set role = excluded.role;

  insert into public.staff_members (user_id, status, scopes)
  values
    (v_founder, 'active', array['hosts:review','hosts:decide','bookings:read','payments:read',
                               'payments:act','finance:read','content:manage','staff:manage']),
    (v_reviewer, 'active',    array['hosts:review']),
    (v_decider,  'active',    array['hosts:review','hosts:decide']),
    (v_decideonly,'active',   array['hosts:decide']),
    (v_payer,    'active',    array['payments:read']),
    (v_susp,     'suspended', array['hosts:review','hosts:decide'])
  on conflict (user_id) do update set status = excluded.status, scopes = excluded.scopes;

  -- an application whose application_data carries document paths -> the
  -- sync_host_documents trigger derives host_documents rows
  insert into public.host_applications (id, user_id, status, title, application_data)
  values (v_app, v_applicant, 'submitted'::public.host_app_status, 'HR App', jsonb_build_object(
    'identity_front_path', v_applicant::text || '/id-front.jpg',
    'identity_back_path',  v_applicant::text || '/id-back.jpg',
    'business_document_paths', jsonb_build_array(v_applicant::text || '/reg.pdf'),
    'photo_paths', jsonb_build_array(v_applicant::text || '/p1.jpg', v_applicant::text || '/p2.jpg')
  ))
  on conflict (id) do nothing;

  -- a review row as the service-role backend would write it
  insert into public.host_application_reviews (application_id, reviewer_id, from_status, to_status, decision, note)
  values (v_app, v_decider, 'submitted'::public.host_app_status, 'under_review'::public.host_app_status, 'under_review', 'looking into it');
end $$;

create or replace function pg_temp.count_as(p_user uuid, p_sql text)
returns bigint language plpgsql as $$
declare v bigint;
begin
  set local role authenticated;
  perform set_config('request.jwt.claims',
    json_build_object('sub', p_user::text, 'role', 'authenticated')::text, true);
  begin execute p_sql into v; exception when insufficient_privilege then v := 0; end;
  reset role;
  return coalesce(v, 0);
end $$;

create or replace function pg_temp.write_blocked(p_user uuid, p_sql text)
returns boolean language plpgsql as $$
begin
  set local role authenticated;
  perform set_config('request.jwt.claims',
    json_build_object('sub', p_user::text, 'role', 'authenticated')::text, true);
  begin
    execute p_sql;
    reset role;
    return false;               -- write succeeded -> NOT blocked
  exception when others then
    reset role;
    return true;                -- any error -> blocked
  end;
end $$;

do $$
declare
  v_app text := 'ba000000-0000-4000-8000-0000000000a1';
begin
  -- reads
  if pg_temp.count_as('ba000000-0000-4000-8000-000000000002',
       'select count(*) from public.host_application_reviews') < 1
     then raise exception 'FAIL: hosts:review cannot read review history'; end if;
  if pg_temp.count_as('ba000000-0000-4000-8000-000000000002',
       'select count(*) from public.host_documents') < 1
     then raise exception 'FAIL: hosts:review cannot read host_documents'; end if;
  if pg_temp.count_as('ba000000-0000-4000-8000-000000000003',
       'select count(*) from public.host_application_reviews') < 1
     then raise exception 'FAIL: hosts:decide cannot read review history'; end if;

  -- documents derived from application_data (identity front+back, 1 business doc, 2 photos = 5)
  if pg_temp.count_as('ba000000-0000-4000-8000-000000000001',
       'select count(*) from public.host_documents where application_id = ''' || v_app || '''') <> 5
     then raise exception 'FAIL: host_documents not derived from application_data as expected'; end if;

  -- wrong scope reads nothing
  if pg_temp.count_as('ba000000-0000-4000-8000-000000000004',
       'select count(*) from public.host_application_reviews') <> 0
     then raise exception 'FAIL: payments:read read review history'; end if;
  if pg_temp.count_as('ba000000-0000-4000-8000-000000000004',
       'select count(*) from public.host_documents') <> 0
     then raise exception 'FAIL: payments:read read host_documents'; end if;

  -- hosts:decide WITHOUT hosts:review sees nothing to decide on (detail route is hosts:review-gated too)
  if pg_temp.count_as('ba000000-0000-4000-8000-000000000008',
       'select count(*) from public.host_application_reviews') <> 0
     then raise exception 'FAIL: decide-only staff read review history'; end if;
  if pg_temp.count_as('ba000000-0000-4000-8000-000000000008',
       'select count(*) from public.host_documents') <> 0
     then raise exception 'FAIL: decide-only staff read host_documents'; end if;

  -- suspended staff: nothing
  if pg_temp.count_as('ba000000-0000-4000-8000-000000000005',
       'select count(*) from public.host_application_reviews') <> 0
     then raise exception 'FAIL: suspended staff read review history'; end if;

  -- traveler + anon: nothing
  if pg_temp.count_as('ba000000-0000-4000-8000-000000000006',
       'select count(*) from public.host_application_reviews') <> 0
     then raise exception 'FAIL: traveler read review history'; end if;

  -- WRITE BOUNDARY 1: hosts:review cannot insert a decision row via direct JWT
  if not pg_temp.write_blocked('ba000000-0000-4000-8000-000000000002',
       'insert into public.host_application_reviews (application_id, reviewer_id, decision) values (''' || v_app || ''', ''ba000000-0000-4000-8000-000000000002'', ''approve'')')
     then raise exception 'FAIL: hosts:review wrote a decision row via direct JWT'; end if;

  -- WRITE BOUNDARY 2: hosts:decide also cannot (all writes go via service-role)
  if not pg_temp.write_blocked('ba000000-0000-4000-8000-000000000003',
       'insert into public.host_application_reviews (application_id, reviewer_id, decision) values (''' || v_app || ''', ''ba000000-0000-4000-8000-000000000003'', ''approve'')')
     then raise exception 'FAIL: hosts:decide wrote a decision row via direct JWT'; end if;

  -- WRITE BOUNDARY 3: hosts:decide cannot move host_applications.status via
  -- direct JWT — whether by trigger exception or by RLS filtering it to 0 rows,
  -- the status must not change.
  perform pg_temp.write_blocked('ba000000-0000-4000-8000-000000000003',
    'update public.host_applications set status = ''approved'' where id = ''' || v_app || '''');
  if pg_temp.count_as('ba000000-0000-4000-8000-000000000001',
       'select count(*) from public.host_applications where id = ''' || v_app || ''' and status = ''submitted''') <> 1
     then raise exception 'FAIL: host_applications.status moved via direct JWT'; end if;

  -- and the decision row count is unchanged (started at 1)
  if pg_temp.count_as('ba000000-0000-4000-8000-000000000001',
       'select count(*) from public.host_application_reviews where application_id = ''' || v_app || '''') <> 1
     then raise exception 'FAIL: a direct-JWT decision row leaked through'; end if;

  -- staff_members others-read is now has_scope(staff:manage) ALONE
  if pg_temp.count_as('ba000000-0000-4000-8000-000000000003',
       'select count(*) from public.staff_members') <> 1
     then raise exception 'FAIL: hosts:decide staff sees more than their own staff row'; end if;
  if pg_temp.count_as('ba000000-0000-4000-8000-000000000001',
       'select count(*) from public.staff_members') < 5
     then raise exception 'FAIL: founder (staff:manage) cannot read the staff roster'; end if;
end $$;

rollback;
