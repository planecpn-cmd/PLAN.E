-- P0.6 — lock down SECURITY DEFINER functions that must be service-role only.
--
-- 20260816130000 wrote `revoke all on function ... from public;` for its
-- service-role-only helper. On the current Supabase CLI, newly created public
-- functions receive a default EXECUTE grant to `anon` and `authenticated`, and
-- `revoke ... from public` does NOT strip those. Later migrations
-- (20260823070000, 20260823170000) already use the full form; this migration
-- back-fills the one function that slipped through.
--
-- Audit: supabase/tests/security_definer_manifest.json. Guard:
-- supabase/tests/security_definer_grants.test.sql. Additive; safe to re-run.
--
-- claim_trip_push_deliveries leases rows in trip_push_deliveries and returns
-- recipient_id per message — i.e. it discloses conversation membership. It is
-- bounded only because message_id is an unguessable UUID, not because nothing
-- leaks. It must be callable by the push Edge Function (service_role) alone.

revoke execute on function public.claim_trip_push_deliveries(uuid)
  from public, anon, authenticated;

-- The service_role grant from 20260816130000 stands. Assert the end state.
do $$
begin
  if has_function_privilege('anon', 'public.claim_trip_push_deliveries(uuid)', 'EXECUTE')
     or has_function_privilege('authenticated', 'public.claim_trip_push_deliveries(uuid)', 'EXECUTE') then
    raise exception 'claim_trip_push_deliveries is still executable by anon/authenticated after revoke';
  end if;
  if not has_function_privilege('service_role', 'public.claim_trip_push_deliveries(uuid)', 'EXECUTE') then
    raise exception 'claim_trip_push_deliveries lost its service_role EXECUTE grant';
  end if;
end $$;
