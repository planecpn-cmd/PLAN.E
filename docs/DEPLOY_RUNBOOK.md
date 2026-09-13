# Deploying the admin panel — runbook

For a founder to execute, in order. Each step: the command, what success
looks like, what to do if it fails, and whether it can be undone. Read
**Step 0** before anything else — skipping it means every later step runs
against a `main` that doesn't have this work on it yet.

Do not skip ahead. Do not run a later step "just to see" if an earlier one
hasn't actually succeeded — several of these are irreversible or expensive
to undo, and they're flagged **⚠ IRREVERSIBLE** where that's true.

---

## Step 0 — get the code onto `main` first

**None of this admin panel work is on `main` yet.** It lives on the branch
`admin-panel/p0-test-harness`, and there is currently no open pull request
for it. Everything below assumes the code exists on `main` — if you run
`supabase db push` or deploy the admin Worker before this step, you will
be pushing an empty or stale admin panel.

1. Open a pull request: `admin-panel/p0-test-harness` → `main`.
2. There is a second open PR, `infra/pipeline` (#6), which adds the CI
   pipeline (`gates.yml`, `deploy.yml`, `agent.yml`) and two of its own
   migrations (§ Step 2 below). It also needs to land on `main`. Read
   `../PLAN-E-automation/SETUP.md` (a sibling worktree, not inside this
   repo checkout) — it has the exact secrets and merge order for that
   pipeline, written by the same effort. **Merge order matters**: get
   `admin-panel/p0-test-harness` in first, or reconcile the two PRs
   together, so `main` ends up with every migration file both branches
   added. Do this by reading both diffs, not by guessing — they touch
   different tables and shouldn't actually conflict, but confirm before
   merging either.
3. **Do not merge blind.** Both branches have been tested locally (SQL
   suite, edge suite, admin typecheck/lint/vitest/build all green as of
   2026-09-12), but nobody has run CI against them together, because CI
   doesn't exist on `main` until `infra/pipeline` lands. Read the diffs.

**Not irreversible** — a PR merge to `main` can be reverted with a further
commit if something's wrong, same as any other merge. But every step after
this one assumes it happened, so don't proceed until it has.

---

## (a) `supabase login` + link

```sh
supabase login
supabase link --project-ref dtebgbrqynxahuzmbtbc
```

**Success looks like:** `login` opens a browser, confirms in the terminal.
`link` prints "Finished supabase link." with no error.

**If it fails:** a 403 on `link` means the logged-in account doesn't have
Owner/Admin on this project — use a different account. This exact failure
happened once before in this project's history (noted in
`../PLAN-E-automation/SETUP.md` §5); it is not unusual.

**Reversible:** yes, this only sets local CLI state.

---

## (b) See what's actually on hosted before touching anything

```sh
supabase migration list --linked
```

**What you're looking at:** a table with a `Local` column (every file in
`supabase/migrations/`) and a `Remote` column (a timestamp if hosted has
already run it, blank if not). This is the only trustworthy source of
truth — trust this output over anything below, including this document,
if they disagree.

**What you should expect to see, and why — so nothing here causes panic:**

- **7 files should already show a `Remote` timestamp**, even though they
  will look "new" if you're only skimming file dates:
  - `20260907100000_category_driven_listing_drafts.sql`
  - `20260907101000_protect_moderated_accommodation_content.sql`
  - `20260907102000_complete_listing_submission_validation.sql`
  - `20260907103000_listing_review_rules.sql`
  - `20260910100000_return_submitted_listing_id.sql`
  — these 5 were applied directly to production by an earlier session,
  before the files existed anywhere in this repo (see PR #9, "chore:
  reconcile 5 migrations already applied to production," for exactly how
  that was confirmed). They add an accommodation/listing-drafts vertical
  nothing in the app calls yet — harmless, already there, don't re-run.
  - `20260910200000_close_past_departures_unpublish_demo.sql` and
    `20260910200100_recategorise_mislabelled_listings.sql` — the two
    P0-CRIT demo-data-cleanup migrations from `infra/pipeline`. Per that
    branch's own `SETUP.md`, these were meant to be applied **by hand**
    (`supabase db push --project-ref dtebgbrqynxahuzmbtbc --include-all`,
    run once, separately, before `infra/pipeline` itself merges) — if
    that already happened, they'll show as applied here too. **If either
    of these two does NOT show a `Remote` timestamp, stop and check with
    whoever ran that step before proceeding** — don't assume and don't
    just push blindly; these two specifically unpublish a demo listing
    and close 90 past-dated departures, which you want to know is
    intentional before it happens under `db push` instead of by hand.
  - Everything else with a `Local` file and a `Remote` blank is genuinely
    new and is what step (c) below is for. As of 2026-09-12 that's
    **16 files**, all from this admin panel effort (`20260908090000`
    through `20260912090000` — staff/scopes, host review, the photo
    bucket, N1 experience review, D1 revisions, the P3 ops console
    schema, and the two access-control fixes from 2026-09-12). If the
    count you see doesn't match, that's fine — this list will have moved
    on from whenever this was written; the point is what `Remote` says,
    not this number.

**If `Local` is missing files you expected** (e.g. the two P0-CRIT ones
aren't in your working tree at all): that means Step 0's merge didn't
actually bring both branches' migrations together. Go back and fix that
before continuing — don't hand-copy files across.

**Reversible:** yes, this is read-only.

---

## (c) Apply the migrations

```sh
supabase db push --linked --dry-run
```

Read the dry-run output. It should list only the genuinely-new files from
step (b) — nothing you already confirmed is `Remote`-applied. If it lists
one of the 7 "should already be applied" files, **stop** — that means
step (b) found something unexpected and you need to resolve that first,
not push through it.

If the dry-run list looks right:

```sh
supabase db push --linked --yes
```

**Success looks like:** each migration in the list prints as applied, no
errors. Re-run `supabase migration list --linked` afterward — every file
should now show a `Remote` timestamp.

**⚠ Partially irreversible.** Most of these migrations are additive
(new tables, new columns, new functions) and safe. Two are not, and you
should know which before you run this:
- If the two P0-CRIT migrations from (b) have **not** already been applied
  by hand, this step will apply them: it **unpublishes a real demo listing**
  and **closes 90 real departures** whose dates have passed. That's the
  intended, correct behavior (closing past dates is the actual fix) — but
  it is a real, immediate change to what travelers see, not a schema
  no-op. Confirm that's expected before running this if you're not certain
  it already happened.
- The rest — new tables, new RLS policies, new functions — are safe to
  apply and don't change any existing row.

**If it fails partway:** `supabase db push` applies migrations one at a
time and stops at the first failure; migrations already applied before
the failure stay applied (this is normal Postgres transaction behavior
per-migration, not a rollback of everything). Read the error, fix the
specific migration or the mismatch it's complaining about, then re-run —
it will skip what already succeeded and resume from the failure.

---

## (d) Deploy the edge functions

Three functions matter for this deploy specifically:

```sh
supabase functions deploy create-booking-intent --project-ref dtebgbrqynxahuzmbtbc
supabase functions deploy admin-reverify-payment --project-ref dtebgbrqynxahuzmbtbc
supabase functions deploy expire-stale-bookings-cron --project-ref dtebgbrqynxahuzmbtbc
```

- **`create-booking-intent` carries the past-departure fix** — it now
  rejects a booking attempt for any departure whose date has already
  passed (checked against Nepal local time, not the server's own clock).
  This is the one server-side fix from the P0-CRIT batch; deploying it is
  the point of redeploying this specific function, not a routine refresh.
- **`admin-reverify-payment`** and **`expire-stale-bookings-cron`** are
  brand new — the admin panel's stuck-payment re-verify button and the
  pending-booking-expiry job both depend on them existing.

**Before deploying any of these, set the secrets they need** (these apply
to every function in the project, not per-function):

```sh
supabase secrets set --project-ref dtebgbrqynxahuzmbtbc \
  KHALTI_API_BASE_URL=https://khalti.com/api/v2 \
  KHALTI_SECRET_KEY=<live Khalti secret key> \
  KHALTI_PUBLIC_KEY=<live Khalti public key> \
  ESEWA_MERCHANT_CODE=<live eSewa merchant code> \
  ESEWA_SECRET_KEY=<live eSewa secret key> \
  TRIP_MESSAGE_PUSH_WEBHOOK_SECRET=<long random value> \
  COMPLETE_TRIPS_CRON_SECRET=<a different long random value> \
  EXPIRE_STALE_BOOKINGS_CRON_SECRET=<yet another long random value> \
  ADMIN_REVERIFY_SECRET=<yet another long random value>
```

(`supabase/functions/.env.example` lists the full set including
Firebase/APNs push credentials — those are for the Flutter trip-message
push feature, not the admin panel, and aren't required for this deploy.)

**⚠ One real gap, found and not silently patched over:** `ADMIN_REVERIFY_SECRET`
was never added to `.env.example` or to the admin Worker's own documented
secrets list (`admin/wrangler.jsonc`'s comment only names two). It has to
be set in **two places with the same value** — here, as a function secret,
and again on the admin Worker itself in step (f) — or the re-verify button
will show "ADMIN_REVERIFY_SECRET is not configured" in production exactly
the way it does locally today. Pick the value now, set it in both places,
and update `admin/wrangler.jsonc`'s secrets comment while you're there.

**Success looks like:** each `deploy` command prints a function URL and
"Deployed Functions." Test one Khalti/eSewa booking end to end afterward on
the live site to confirm `create-booking-intent` didn't regress anything
else.

**If it fails:** a deploy failure doesn't touch the previously-deployed
version — the old function keeps serving until a deploy actually succeeds.
Safe to retry.

**Reversible:** yes — redeploy the previous version from git history if
something's wrong (`git checkout <previous-commit> -- supabase/functions/<name>` then redeploy).

---

## (e) Run the founder bootstrap migration, with real emails

`supabase/migrations/20260908130000_founder_bootstrap.sql` ships with an
**intentionally empty** `v_emails` array — it was skipped in step (c)
because an empty array is a no-op, so it applied and did nothing. That's
correct; it's not meant to run for real until this step.

1. Edit the file locally, filling in the actual founder email addresses
   exactly as they'll sign in (Google OAuth or password — whatever matches
   their `auth.users.email`):
   ```sql
   v_emails text[] := array[
     'founder-one@realdomain.com',
     'founder-two@realdomain.com'
   ]::text[];
   ```
2. Each email needs a matching `auth.users` row already — meaning that
   person needs to have signed in at least once (via the admin login page,
   which will currently reject them with "Not authorized" until this step
   runs — that's expected, sign in once first to create the row, then run
   this). An email with no matching row is skipped with a `NOTICE`, not an
   error — check the output for any you expected to see and didn't.
3. Commit this change (do **not** leave real founder emails sitting only
   in an uncommitted local file — commit it, this is meant to be
   permanent, versioned proof of who was granted founder access and when).
4. Push and apply just this one migration:
   ```sh
   supabase db push --linked --yes
   ```

**⚠ IRREVERSIBLE in effect, not in mechanism.** Re-running this file later
with different emails does not revoke the old ones — `profiles.role =
'admin'` and full `staff_members` scopes stick until someone with
`staff:manage` explicitly revokes them (there is no admin UI for that yet
— see `admin/README.md`'s "Deliberately NOT built yet"; it's a direct SQL
update: `update staff_members set status='suspended' where user_id = ...`).
Get the email list right before running this — every address in it gets
**all ten scopes**, unconditionally, with no review step.

**Success looks like:** a `NOTICE` per email — `founder bootstrap: <email>
-> admin + all scopes`. Confirm in the database:
```sql
select p.id, u.email, p.role, s.scopes
from public.profiles p
join auth.users u on u.id = p.id
join public.staff_members s on s.user_id = p.id
where p.role = 'admin';
```

---

## (f) Deploy the admin Worker: both secrets, hostname binding

```sh
cd admin
npx wrangler secret put NEXT_PUBLIC_SUPABASE_ANON_KEY --name plan-e-admin
npx wrangler secret put SUPABASE_SERVICE_ROLE_KEY --name plan-e-admin
npx wrangler secret put ADMIN_REVERIFY_SECRET --name plan-e-admin
npm run deploy
```

- `NEXT_PUBLIC_SUPABASE_ANON_KEY` — the project's public anon key (Supabase
  dashboard → Project Settings → API). Not secret in the sense of needing
  protection from users' browsers (it's public by design, RLS is the real
  guard), but it's still set as a Worker secret here rather than a plain
  var so it isn't sitting in the committed `wrangler.jsonc`.
- `SUPABASE_SERVICE_ROLE_KEY` — the real service-role key. This one
  matters: `admin/src/lib/service-role.ts` is the only file that reads it,
  and it must never end up in `NEXT_PUBLIC_*` or in any client-shipped
  bundle. `docs/ADMIN_ACCESS_VERIFICATION.md` already confirmed the built
  output doesn't leak it — this step is what actually gives the Worker the
  real value to work with.
- `ADMIN_REVERIFY_SECRET` — same value set on the edge function in step
  (d). Without this the re-verify button is permanently broken in
  production, not just in local dev.

The hostname (`admin.planenepal.com`) and the anon key's project URL are
already committed in `admin/wrangler.jsonc` — nothing to configure there.

**Success looks like:** `npm run deploy` runs `opennextjs-cloudflare
build && opennextjs-cloudflare deploy` and ends with a deployed Worker URL.
Visiting `admin.planenepal.com` should show the sign-in page — **do not
stop here**, go straight to step (g) before telling anyone this URL
exists.

**If it fails:** a failed deploy doesn't take down anything — Cloudflare
keeps serving the last successful deploy until a new one succeeds. Check
the build output; a `next build` failure here should have already been
caught locally (`npm run build` is part of the check suite) — if it
passes locally and fails here, it's almost always a missing secret or an
account/permissions issue with Cloudflare, not the code.

**Reversible:** yes — `npx wrangler rollback --name plan-e-admin` returns
to the previous deployed version.

---

## (g) Configure Cloudflare Access — **do this immediately after (f), before anyone else knows the URL exists**

**Until this step is done, anyone on the internet who finds or guesses
`admin.planenepal.com` reaches the real staff sign-in page.** The app's
own layers (session check, `staff_members` lookup, scope checks) still
stop them from doing anything without a real staff account — but they can
see the login page exists, see its exact copy and behavior, and hammer it
with sign-in attempts. Cloudflare Access is a second factor that runs
*before* any of that, blocking everyone who isn't pre-approved from
reaching the app at all. Ship this before the hostname is shared with
anyone, including internally.

From `admin/README.md`, verbatim:

1. Cloudflare dashboard → **Zero Trust** → **Access** → **Applications** →
   **Add an application** → **Self-hosted**.
2. Application domain: `admin.planenepal.com` (the whole hostname, no path).
3. **Session duration**: 24h or shorter.
4. **Policies** → add a policy named `staff`:
   - Action: **Allow**
   - Include: **Emails** → the founder/staff email addresses (or **Emails
     ending in** your company domain, or a Google Workspace group)
   - Require: **one-time PIN** or your identity provider
5. Add a second policy, **Block** / "everyone else", Include: **Everyone**,
   placed *below* the `staff` policy (policy order matters — first match
   wins).
6. Save.

**Success looks like:** visiting `admin.planenepal.com` from an
allow-listed email shows the Cloudflare Access challenge first, then the
app's own login page after passing it. Visiting from any other email (or
logged out of everything) is stopped by Cloudflare — it never reaches
Next.js at all. Test both cases before considering this done.

**Reversible:** yes, policies can be edited or removed at any time in the
dashboard. Not irreversible, but every minute it's undone after step (f)
is a minute the raw login page is exposed.

---

## (h) First login and what to verify immediately

1. Sign in at `admin.planenepal.com` as one of the founder emails from
   step (e), through the Cloudflare Access challenge from step (g).
2. **Verify the menu shows all six links**: Host applications, Experiences,
   Bookings, Payments, Users, Config & feature flags. If any are missing,
   that founder's `staff_members.scopes` isn't the full ten — check step
   (e)'s query again.
3. **Open each screen once** and confirm it loads without an error —
   you're checking for a 500, a blank page, or a stuck spinner, not
   auditing every field. Real data should now appear (real bookings, real
   payments, real host applications) — if a screen that showed real data
   in local testing now shows nothing, check that the RLS migrations from
   step (c) actually applied (`select * from pg_policies where tablename =
   'experiences';` should show policies mentioning `has_scope`, not
   `is_admin()`).
4. **Check `admin_audit_log` is reachable and, ideally, still empty**
   (`select count(*) from admin_audit_log;` as the founder, or via SQL
   editor with the service role) — a non-zero count on a fresh production
   deploy would mean something already wrote to it, worth understanding
   before real staff start using the panel.
5. **Do one real, low-stakes write** to confirm the full path works end to
   end in production, not just that pages render: toggle a feature flag on
   `/config` and back off, with a reason each time. Confirm both toggles
   show up as separate rows in `admin_audit_log` with your name and the
   reasons you typed. This is the cheapest possible real proof that
   `withAdmin`, the service-role client, and the audit trail all actually
   work against the live database, not just the local one.
6. **Do not yet rely on**: booking cancellation or the config toggle
   working all the way through without watching closely — per
   `docs/ADMIN_SMOKE_CHECKLIST.md`, both are the two actions that were
   never confirmed end-to-end by an automated check before this deploy
   (a browser-dialog limitation in the tool used to test, not a known
   defect) — they're expected to work, since step 5 above exercises the
   exact same code path as the config toggle, but they're the first two
   things worth a founder actually clicking through here in production
   before trusting the rest.

If all of the above checks out: the admin panel is live and ready for
staff to actually use.
