-- =============================================================================
-- security_definer_grants.test.sql  —  PERMANENT guard (P0.6 item 4)
-- =============================================================================
-- The 20260816130000 bug happened because a CLI default grant changed under a
-- `revoke` idiom silently. This test is the trip-wire so it cannot happen again.
--
--   1. Every function classified service-role-only in
--      supabase/tests/security_definer_manifest.json must NOT be executable by
--      anon or authenticated (and must keep its service_role grant).
--   2. Drift: any SECURITY DEFINER function in `public` that is a callable RPC
--      (takes real args, does not return `trigger`) and is executable by NEITHER
--      anon NOR authenticated is de-facto service-role-only and must appear in
--      the list below — otherwise the manifest is stale.
--
-- Keep v_service_role_only in sync with manifest.service_role_only. Signatures
-- are resolved to OIDs, so identity-argument spelling does not matter.
-- =============================================================================

begin;

do $$
declare
  -- mirrors security_definer_manifest.json -> "service_role_only"
  v_service_role_only text[] := array[
    'public.check_ai_rate_limit(text, integer, integer)',
    'public.consume_payment_redirect_token(text)',
    'public.finalize_verified_payment(uuid, uuid, payment_provider, text, jsonb)',
    'public.claim_trip_push_deliveries(uuid)',
    'public.admin_apply_experience_revision(uuid, uuid, jsonb)'
  ];
  v_sig text;
  v_allow_oids oid[] := '{}';
  v_oid oid;
  v_bad text[] := '{}';
  v_missing text[] := '{}';
  v_drift text[] := '{}';
  r record;
begin
  -- resolve + (1) each declared service-role-only function is locked down
  foreach v_sig in array v_service_role_only loop
    v_oid := to_regprocedure(v_sig);
    if v_oid is null then
      v_missing := v_missing || v_sig;
      continue;
    end if;
    v_allow_oids := v_allow_oids || v_oid;
    if has_function_privilege('anon', v_oid, 'EXECUTE')
       or has_function_privilege('authenticated', v_oid, 'EXECUTE') then
      v_bad := v_bad || v_sig;
    end if;
    if not has_function_privilege('service_role', v_oid, 'EXECUTE') then
      v_bad := v_bad || (v_sig || ' [missing service_role grant]');
    end if;
  end loop;

  if array_length(v_missing, 1) is not null then
    raise exception 'FAIL: manifest lists unknown function(s): %', v_missing;
  end if;
  if array_length(v_bad, 1) is not null then
    raise exception 'FAIL: service-role-only function(s) reachable by anon/authenticated (or missing service_role): %', v_bad;
  end if;

  -- (2) drift check
  for r in
    select p.oid,
           n.nspname || '.' || p.proname
             || '(' || pg_get_function_identity_arguments(p.oid) || ')' as sig
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.prosecdef
      and p.prorettype <> 'pg_catalog.trigger'::regtype
      and p.pronargs > 0
      and not has_function_privilege('anon', p.oid, 'EXECUTE')
      and not has_function_privilege('authenticated', p.oid, 'EXECUTE')
  loop
    if not (r.oid = any (v_allow_oids)) then
      v_drift := v_drift || r.sig;
    end if;
  end loop;

  if array_length(v_drift, 1) is not null then
    raise exception 'FAIL: service-role-only function(s) missing from the manifest list: % — add them to security_definer_manifest.json and this test', v_drift;
  end if;

  raise notice 'security_definer_grants: % service-role-only function(s) verified locked', array_length(v_service_role_only, 1);
end $$;

rollback;
