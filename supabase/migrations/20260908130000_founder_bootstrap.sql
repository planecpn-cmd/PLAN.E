-- P1 Step 4 — founder bootstrap. The ONLY path to a staff_members row in P1;
-- every later change goes through the service-role backend under staff:manage.
--
-- ┌─────────────────────────────────────────────────────────────────────────┐
-- │  GATE 2 PLACEHOLDER — v_emails is intentionally EMPTY.                   │
-- │  Fill it with the founder email addresses exactly as they appear in     │
-- │  auth.users, then this migration grants each of them profiles.role =    │
-- │  'admin' + a staff_members row with all eight scopes.                   │
-- │  An empty list is a clean no-op (the FOREACH body never runs).          │
-- │  An email with no matching auth.users row is skipped with a NOTICE,     │
-- │  never an error.                                                        │
-- └─────────────────────────────────────────────────────────────────────────┘

do $$
declare
  v_emails text[] := array[
    -- 'founder-one@example.com',
    -- 'founder-two@example.com'
  ]::text[];
  v_all_scopes constant text[] := array[
    'hosts:review', 'hosts:decide',
    'bookings:read', 'payments:read', 'payments:act',
    'finance:read', 'content:manage', 'staff:manage'
  ];
  v_email text;
  v_uid uuid;
begin
  -- A migration is a trusted administrative operation: identify it so the
  -- prevent_profile_role_escalation guard allows the role update.
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);

  foreach v_email in array coalesce(v_emails, '{}'::text[]) loop
    select id into v_uid
    from auth.users
    where lower(email) = lower(btrim(v_email))
    limit 1;

    if v_uid is null then
      raise notice 'founder bootstrap: no auth.users row for %, skipped', v_email;
      continue;
    end if;

    update public.profiles
       set role = 'admin'::public.user_role, updated_at = now()
     where id = v_uid;

    insert into public.staff_members (user_id, status, scopes, created_by)
    values (v_uid, 'active', v_all_scopes, v_uid)
    on conflict (user_id) do update
      set status = 'active',
          scopes = excluded.scopes,
          suspended_at = null,
          suspended_reason = null,
          updated_at = now();

    raise notice 'founder bootstrap: % -> admin + all scopes', v_email;
  end loop;
end $$;
