-- =============================================================================
-- P0-CRIT data fix (AUDIT.md (c), BLOCKED.md B6 + B7). Data only, no schema.
--
-- Part 1 (B6) runs before Part 2 (B7), in this one transaction.
--
-- Idempotent: both parts only move rows out of the state they fix
-- (status = 'open' / 'published'). A re-run matches zero rows.
--
-- Part 1 uses a FIXED cutoff (2026-09-10, the audit date), not now(). It
-- closes exactly the audited set: 90 open departures dated 2026-08-14 ..
-- 2026-09-09. That keeps the effect reproducible and the rollback exact
-- whenever this is applied. Departures that pass their date later are
-- handled in code: create-booking-intent and the experience page both
-- treat start_date < today (Asia/Kathmandu) as closed.
--
-- ROLLBACK (run manually, in one transaction, Part 2 first):
--   -- undo Part 2
--   update public.experiences set status = 'published'
--     where id = 'e1000000-0000-4000-8000-000000000001' and slug = 'demo-ram-mardi-himal-trek';
--   update public.experience_departures set status = 'open'
--     where id = 'd1000000-0000-4000-8000-000000000001';
--   -- undo Part 1 (at the audit, no departure dated before 2026-09-10 was
--   -- 'closed'; every row matching this was closed by Part 1)
--   update public.experience_departures set status = 'open'
--     where status = 'closed' and start_date < date '2026-09-10';
-- =============================================================================

-- Part 1 (B6): close past-dated departures that are still open.
update public.experience_departures
set status = 'closed'
where status = 'open'
  and start_date < date '2026-09-10';

-- Part 2 (B7): unpublish the demo listing and close its only departure.
-- Both ids are fixed by 20260813111000_seed_ram_shrestha_demo_host.sql.
update public.experiences
set status = 'draft'
where id = 'e1000000-0000-4000-8000-000000000001'
  and slug = 'demo-ram-mardi-himal-trek'
  and status = 'published';

update public.experience_departures
set status = 'closed'
where id = 'd1000000-0000-4000-8000-000000000001'
  and status = 'open';
