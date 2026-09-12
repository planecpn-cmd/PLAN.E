-- Fix: a staff member holding only a *:decide / *:act scope (content:decide,
-- hosts:decide, payments:act) — deliberately without the paired
-- content:manage / hosts:review / payments:read scope — could decide via a
-- direct API call (the withAdmin gate on the decision/cancel/refund routes
-- already accepted the decide/act scope alone) but could not open the page
-- that hosts the decide control at all: the page itself gates on the
-- read/manage/review scope only, and even past that gate, every business
-- table read on that page runs through the ANON session client, which is
-- itself subject to these very RLS policies — so the page would render an
-- empty queue / a "not found" listing even if the page-level gate were
-- widened alone. Confirmed empirically in docs/ADMIN_ACCESS_VERIFICATION.md
-- (finding 2).
--
-- This defeats the four-eyes split by design: the whole point of a
-- decide-only scope is that one person can be trusted to decide without
-- also being able to review/triage, and vice versa. Widen each SELECT
-- policy to accept its paired scope too. Nothing about who can WRITE
-- changes here — every writing endpoint already checked the decide/act
-- scope on its own, correctly, and continues to.

drop policy if exists "Content managers can read all experiences" on public.experiences;
create policy "Content managers can read all experiences"
  on public.experiences for select to authenticated
  using (public.has_scope('content:manage') or public.has_scope('content:decide'));

drop policy if exists "Content managers read experience review history" on public.experience_reviews;
create policy "Content managers read experience review history"
  on public.experience_reviews for select to authenticated
  using (public.has_scope('content:manage') or public.has_scope('content:decide'));

drop policy if exists "Content managers read all departures" on public.experience_departures;
create policy "Content managers read all departures"
  on public.experience_departures for select to authenticated
  using (public.has_scope('content:manage') or public.has_scope('content:decide'));

drop policy if exists "Host reviewers can read all host applications" on public.host_applications;
create policy "Host reviewers can read all host applications"
  on public.host_applications for select to authenticated
  using (public.has_scope('hosts:review') or public.has_scope('hosts:decide'));

drop policy if exists "Host reviewers can read host documents" on public.host_documents;
create policy "Host reviewers can read host documents"
  on public.host_documents for select to authenticated
  using (public.has_scope('hosts:review') or public.has_scope('hosts:decide'));

drop policy if exists "Host reviewers can read review history" on public.host_application_reviews;
create policy "Host reviewers can read review history"
  on public.host_application_reviews for select to authenticated
  using (public.has_scope('hosts:review') or public.has_scope('hosts:decide'));

drop policy if exists "Payment readers can read all payments" on public.payments;
create policy "Payment readers can read all payments"
  on public.payments for select to authenticated
  using (public.has_scope('payments:read') or public.has_scope('payments:act'));
