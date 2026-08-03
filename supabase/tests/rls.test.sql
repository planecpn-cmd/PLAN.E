-- RLS Safety Test Assertions (Permanent test file)
-- Run via psql / pg_prove against the database to verify row level security policies.

begin;

-- 1. Verify RLS is enabled on all core tables
select count(*) = 19 as all_tables_rls_enabled
from pg_tables
where schemaname = 'public' and rowsecurity = true;

-- 2. Test: Anon role reading published experiences
set role anon;

-- Anon can query published experiences
select count(*) >= 1 as anon_can_read_published_experiences
from public.experiences
where status = 'published';

-- 3. Test: Anon role attempting to read bookings (must return 0 rows)
select count(*) = 0 as anon_cannot_read_bookings
from public.bookings;

-- 4. Test: Anon role attempting to read payments (must return 0 rows)
select count(*) = 0 as anon_cannot_read_payments
from public.payments;

rollback;
