# First admin session — start here

The admin panel is deployed and the database is live. This is what to check
before you assume anything works, and what's already known to be broken.

## Where

**https://admin.planenepal.com**

**Cloudflare Access is not configured yet** — anyone who reaches the URL
today gets the app's own login screen (Supabase Auth: email/password or
Google), not an extra network-level gate. Setting up Access is on you,
dashboard-only; until it's on, the app's own auth is the only thing
standing between the URL and a login attempt.

## Test 1 — do scopes actually gate what you see

Log in with `raunakshah1244@gmail.com`. You should land with full access —
`profiles.role = 'admin'` plus a `staff_members` row with all ten scopes.
That's the whole point of the access-control work this session verified:
confirm the UI actually reflects it, not just that the row exists in the
database.

- Every section (experiences, host applications, bookings, payments, users,
  config) should be visible and actionable.
- If you later create a second staff account with a narrower scope set,
  confirm the sections it *can't* touch are actually hidden or disabled,
  not just visually de-emphasized.

## Test 2 — the two actions nobody has clicked yet

Both exist in code, passed their local tests, but have never been exercised
through the real deployed UI by a human. Click each once and report what
you see:

1. **Cancel a booking** — find any booking, use the cancel action, confirm
   the booking's status actually changes and nothing else breaks around it.
2. **Toggle a config value** — `/config`, flip one flag, confirm it saves
   and the `config_audit_log` records who changed what.

## Known gaps — expected, not new bugs you're finding

- **Notifications send nothing.** Hosts get no signal when their listing is
  approved or rejected; travelers get no signal when a booking is
  cancelled. The code path exists and writes an in-app `notifications` row,
  but the actual message copy was deliberately left unfilled (a GATE in
  `admin/src/lib/host-notifications.ts`) — it warns to the console instead
  of sending anything. Not silently broken, just not written yet.
- **The refunds screen doesn't show existing refunds.** After creating a
  refund, the "Create refund" button just sits there — nothing on screen
  indicates one already exists for that payment. You *can* click it again
  and create a second refund request for the same payment with no warning.
  The `admin_create_refund` backstop still caps the total at the refundable
  balance, so it can't over-refund — but the UI gives no visual signal.
  Documented in `ADMIN_SMOKE_CHECKLIST.md`, not fixed yet pending a founder
  call on whether it's worth a UI change before real use.
- **Re-verify shows "ADMIN_REVERIFY_SECRET is not configured"** until you
  either give that value to set on the Worker, or run
  `wrangler secret put ADMIN_REVERIFY_SECRET` yourself with the same value
  you set on the Supabase function secrets. Expected until that's done, not
  a deploy bug.

## What the data actually looks like right now

The hosted database just went through B6/B7 (the P0-CRIT departure cleanup)
and the founder bootstrap. Expect screens to look emptier than local dev:

- **92 departures closed** (90 from the fixed past-date cutoff, plus the
  demo listing's own departure).
- **2 departures still open**, both dated in October 2026 — that's the
  entire live inventory of bookable dates right now.
- **The demo listing (`demo-ram-mardi-himal-trek`) is unpublished** —
  `status='draft'`, won't show anywhere a traveler would look.

If a screen looks unexpectedly empty, check whether it's actually filtering
on `status='open'`/`published` before assuming something's broken — most of
the time, it's this.

## Where to report what you find

Whatever you hit — a scope that doesn't gate correctly, either of the two
never-clicked actions behaving oddly, anything beyond the known gaps above —
bring it back to this thread so it goes through the same review this deploy
did, rather than getting fixed ad hoc.
