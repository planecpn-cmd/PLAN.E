# Admin panel smoke checklist

For whoever holds the first founder account. Nothing in `admin/` has ever been
loaded in a browser — `npm run build` passing means the TypeScript compiles,
not that a page renders or a button works. This is a manual click-through,
screen by screen, against the local Supabase stack seeded with the automated
test fixtures (`supabase/tests/seed_test.sql` — referred to below as "the
seed"). Run it once before the first real deploy, and again after any change
that touches a page, an API route, or an RLS policy.

Budget ~30 minutes. If any "what should render" line doesn't match, stop and
file it — don't work around it in the panel.

---

## 0. Get in

```sh
supabase db reset          # migrations + supabase/seed.sql + seed_test.sql loads on top
```

`seed_test.sql` already creates a founder-scoped staff row for
`admin@planetest.local`, but its password field is a placeholder, not a real
hash — you can't sign in with it as-is. Give that account a real password
with the Auth admin API (needs the local **service role** key —
`supabase status` prints it):

```sh
curl -s -X PUT "http://127.0.0.1:54341/auth/v1/admin/users/11111111-1111-4111-8111-000000000004" \
  -H "apikey: $SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"password": "smoke-test-password-1"}'
```

Then:

```sh
cd admin
cp .env.local.example .env.local   # if you haven't already
npm install
npm run dev                        # http://localhost:3000
```

Sign in at `http://localhost:3000/login` with `admin@planetest.local` /
`smoke-test-password-1`. You should land on `/` with a sidebar showing all
six links (Host applications, Experiences, Bookings, Payments, Users, Config
& feature flags) — the seed's staff row holds all ten scopes.

**Checking a moderator's restricted view.** The seed only creates one staff
row (the founder). To see what a scoped-down moderator sees, temporarily
narrow it, reload, then put it back — don't create a second account for this:

```sql
-- narrow, look at the nav + each page's redirect, then restore:
update public.staff_members set scopes = array['bookings:read']::text[]
  where user_id = '11111111-1111-4111-8111-000000000004';
-- ... reload the app, confirm only what bookings:read grants is visible ...
update public.staff_members set scopes = array[
  'hosts:review','hosts:decide','bookings:read','payments:read','payments:act',
  'finance:read','content:manage','content:decide','users:manage','staff:manage']::text[]
  where user_id = '11111111-1111-4111-8111-000000000004';
```

**Checking the audit log after any action below** — every mutating action
writes exactly one row here:

```sql
select action, entity_type, entity_id, reason, scope_used, created_at
from public.admin_audit_log
order by created_at desc limit 5;
```

---

## 1. Config & feature flags — `/config`

**Scope:** `content:manage`.

**Should render:** four flags, alphabetical by key —
`ai_itinerary` (on), `payment_esewa` (on), `payment_khalti` (on),
`refund_gateway_live` (**off**). Each shows its description text and a
rollout percent of 100.

**Should be empty:** nothing on this screen is ever empty — four flags exist
from the base migrations regardless of the seed.

**Action to fire:** toggle `ai_itinerary` off, supply a reason ("smoke test"),
save.

**Expect after:**
- The row flips to off immediately in the list (no reload needed, or a
  reload shows it persisted).
- `admin_audit_log`: one new row, `action = 'config.update'`,
  `entity_type = 'feature_flags'`, `entity_id = 'ai_itinerary'`,
  `reason = 'smoke test'`, `before.enabled = true`, `after.enabled = false`.

**Clean up:** toggle it back on (reason required again) before moving on —
other screens/flows may read this flag.

---

## 2. Host applications — `/host-applications`

**Scope to open:** `hosts:review`. **Scope to decide:** `hosts:decide`.

**Should render (default "All" filter — no status filter applied, so it
shows both seeded applications):** two cards, oldest-submitted first —
"Test Host — trekking" (`approved`, Pokhara, 0 documents, ~20d old — it was
submitted 20 days ago, then approved) above "Test Applicant — trekking"
(`submitted`, Pokhara, 0 documents, ~5d old).

**Should be empty:** click the `under review`, `action required`, and
`rejected` filter chips — each shows "No applications". Only `submitted`
and `approved` have a row.

**Action to fire:** open the `submitted` one (Test Applicant). The seed
founder holds both `hosts:review` and `hosts:decide`, so the panel shows the
**Decision** buttons directly (Mark under review / Approve / Reject /
Request changes) — not a separate recommend step; that only appears for an
account with `hosts:review` and not `hosts:decide` (see §0's scope-narrowing
trick if you want to see that view). Click "Mark under review", then
"Approve".

**Expect after:**
- Each click writes an `admin_audit_log` row, `action = 'host_application.decide'`
  (both the under-review step and the approval go through the same decide
  endpoint for a `hosts:decide` account — there is no separate `.recommend`
  action logged here).
- The application's status ends at `approved`; the applicant's underlying
  profile role flips from `host_applicant` to `host`.

**Clean up:** this one is a real state change to seed data (submitted →
approved). Either re-run `supabase db reset` before your next pass through
this checklist, or accept the seed is now "used up" for this screen until
reset.

---

## 3. Experiences — `/experiences`

**Scope to open / recommend:** `content:manage`. **Scope to decide:**
`content:decide`.

**Should render:** the default filter is `pending_review` — **this is
empty.** The seed's only experience ("Test Mardi Himal Trek") is already
`published`. Click the `published` chip (or `all`) to actually see it:
one row, "Test Mardi Himal Trek", Kaski Nepal, NPR 12,500.

**Should be empty:** `pending_review`, `draft`, `paused`, `archived` all show
"No experiences in ..." — nothing in the seed is in any of those states.

**Action to fire:** there is no listing to recommend/decide on in the seed
(nothing is `pending_review`). Skip the mutating action here — the queue
being empty by default *is* the thing to verify. If you want to exercise the
recommend/decide forms end to end, that needs a host to submit a new draft
first (out of scope for this checklist; see `docs/H1_HOST_WRITE_PATH.md`'s
end-to-end test for that path already covered by automation).

---

## 4. Bookings — `/bookings`

**Scope to open:** `bookings:read`. **Scope to cancel:** `payments:act`.

**Should render (no filter):** three rows for the one seeded traveler —
`TEST-PENDING-0001` (2 people, NPR 26,250, pending), `TEST-CONFIRMED-01`
(1 person, NPR 13,125, confirmed), `TEST-COMPLETED-01` (3 people,
NPR 39,375, completed).

**Should be empty:** the `cancellation_requested`, `cancelled`, and
`expired` filter chips — nothing in the seed is in any of those states.

**Detail screen** (`TEST-PENDING-0001`): Departure line shows the seeded
open departure's dates; Payment line shows `khalti · NPR 26,250 · initiated`;
Timeline shows "Booking created" and "Payment initiated" only (no paid /
completed / cancelled entries — none happened). A "Cancel booking" button
appears (status is cancellable, and the seed founder has `payments:act`).

**Action to fire:** on `TEST-PENDING-0001`, click Cancel, type a reason
("smoke test"), confirm.

**Expect after:**
- Status flips to `cancelled`; a "Cancellation" section appears on the
  detail page (`staff: "smoke test" (from pending)`).
- `admin_audit_log`: one row, `action = 'booking.cancel'`,
  `entity_type = 'bookings'`, `entity_id` = the booking's id,
  `reason = 'smoke test'`, `before.status = 'pending'`,
  `after.status = 'cancelled'`.
- A new row in `booking_cancellations` for the same booking.

**Clean up:** this mutates seed data; reset before your next full pass if you
want the original three-status baseline back.

---

## 5. Payments — `/payments`

**Scope to open:** `payments:read`. **Scope to act:** `payments:act`.

**Should render (default "all" tab):** three rows, newest first —
`KHALTI · NPR 26,250` (we say `initiated`, gateway says `—`, since
`raw_response` has no `status` key), `KHALTI · NPR 13,125` (we say `paid`,
gateway says `Completed`), `ESEWA · NPR 39,375` (we say `failed`, gateway
says `CANCELED`).

**Should be empty:** click the "stuck (>30 min)" tab. The seed's one
`initiated` payment is ~9 minutes old, below the 30-minute cutoff — this
tab shows "No payments stuck right now."

**Action to fire (re-verify):** on the `initiated` row, click "Re-verify
with gateway".

**Expect:** this call reaches a real Khalti sandbox lookup
(`admin-reverify-payment` edge function) — it will not succeed against the
seed's fake `provider_ref`/`idempotency_key`, and that's fine to observe: you
should see a clear error surfaced in the UI (not a silent failure, not a
crash), and `admin_audit_log` should still get a row —
`action = 'payment.reverify'` — with an error-shaped `after` (per
`with-admin.server.ts`, an audit row is written even when the handler
throws or returns an error status). This is the one control that can't be
fully exercised locally without real gateway sandbox credentials; confirming
the error path is visible and audited is the useful local check.

**Action to fire (refund):** on the `paid` row (NPR 13,125), click "Create
refund", enter an amount ≤ 13,125, submit.

**Expect after:**
- A new row in `refunds` with `status = 'pending'` — no live gateway call
  happens (`refund_gateway_live` is off).
- `admin_audit_log`: one row, `action = 'payment.refund_create'`.
- The footnote under the list ("Refunds record a pending row only...") is
  accurate — there is nothing further to click to make the refund "real"
  from this screen; advancing it is `/api/refunds/[id]/settle`, not yet
  wired into this UI (mark that gap if you expect a settle button here).

---

## 6. Users — `/users`

**Scope:** `users:manage` (as of this pass — previously gated on
`bookings:read`, which handed a full spend-and-contact directory to anyone
triaging a single booking; see `docs/ADMIN_SCOPES.md`).

**Should render:** four rows (the search box starts unfiltered) — Test
Admin, Test Host, Test Applicant, Test Traveler, newest-created first. Only
Test Traveler shows nonzero numbers: **3 bookings, NPR 52,500 spent**
(the confirmed + completed totals; the pending one doesn't count toward
spend). The other three show 0 bookings, NPR 0. Every row shows
"country: not collected" — this is correct, not a bug; the product doesn't
collect it anywhere yet.

**Should be empty:** search for a phone number or name that doesn't exist
("zzz-nobody") — "No users."

**Action to fire:** Suspend Test Applicant (a user not involved in any
other check on this list, so it doesn't disturb the rest of the checklist),
with a reason.

**Expect after:**
- The row shows a red "suspended — <reason>" badge; the button changes to
  "Reactivate".
- `admin_audit_log`: one row, `action = 'user.suspend'`,
  `entity_type` referencing the user, `reason` as typed.

**Clean up:** click Reactivate before finishing — leaves the seed clean for
the next pass, and exercises `action = 'user.reactivate'` too.

---

## After all six

Run the full local SQL + edge + admin suites once more — a passing click-
through doesn't replace them, it catches what they structurally can't (a
button that's misrouted, a query that 500s only through the browser's exact
request shape, an RLS policy that blocks the page's own session client
differently than a test's service-role client):

```sh
bash scripts/test-all.sh --sql
bash scripts/test-all.sh --edge
cd admin && npm run typecheck && npm run lint && npm run test && npm run build
```

If everything above matched, the panel is fit for the founders to actually
use against real data — not just fit to compile.
