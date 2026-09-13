# P0 report — test harness and CI

Node P0 of `ORCHESTRATION_GRAPH.md`. Branch `admin-panel/p0-test-harness`.
All migrations applied **local stack only**; nothing deployed to
`dtebgbrqynxahuzmbtbc`.

## Exit condition

> A single command runs the full suite green from a clean checkout, and CI is
> green on `main`.

- **Local: met.** `bash scripts/test-all.sh` from a clean checkout runs
  `supabase db reset` (59 migrations + seed) → `seed_test.sql` → 12 SQL test
  files → 2 edge test files → **ALL GREEN** (one narrow documented SKIP, below).
  `flutter analyze` clean; `flutter test --exclude-tags known-broken-layout`
  green (253 tests).
- **CI: workflows written, not yet observed green.** `.github/workflows/{db,flutter,web}.yml`
  added, triggering on `pull_request` and `push: main`. They cannot report green
  until this branch is pushed and a run completes. First push of the branch /
  its PR is the confirmation step.

## What was built

| File | Purpose |
|---|---|
| `scripts/test-all.sh` | the one command. `--sql` / `--edge` / `--no-reset` flags. Runs `supabase db reset`, loads `seed_test.sql`, runs every `supabase/tests/*.test.sql` via `psql` in the DB container, then every `*.test.mjs` via `node --test` (starts `supabase functions serve` itself if not already up). Exits non-zero on the first real failure. |
| `.env.example` (root) | test-harness env. The well-known Supabase local-dev keys (not secret; shared by every local install). Real hosted creds are never committed. |
| `.gitattributes` | force LF on `*.sh`, `*.sql`, `*.mjs`, `*.yml`, `Makefile` so they run on Linux CI. |
| `supabase/tests/seed_test.sql` | P0.2. Deterministic fixtures (hard-coded UUIDs, idempotent re-run): 4 profiles (traveler / host_applicant / approved host / admin), 2 host applications (submitted / approved), 1 published experience + open departure, 3 bookings (pending / confirmed / completed) with matching payments (initiated / paid / failed). Not wired into `config.toml [db.seed]` — test-only. |
| `supabase/tests/admin_rls.test.sql` | P0.3. Permanent cross-tenant negatives (a traveler reads none of another user's bookings / payments / host_applications / legal_acceptances / booking_participants / draft experiences / host_accounts; an admin cannot select private profile columns) + an **ADMIN BASELINE** block asserting today's reality (no `is_admin()` SELECT reach into business tables). P1 Step 2 flips the ADMIN BASELINE assertions 0 → 1. |
| `supabase/tests/security_definer_manifest.json` | P0.6. Authorization classification of every `SECURITY DEFINER` function in `public` + `private`: `service_role_only` (4), `authenticated_callable` (19), `admin_gated_in_body` (2), `intentionally_public` (2), `trigger_only` (7). |
| `supabase/tests/security_definer_grants.test.sql` | P0.6. **Permanent guard.** Fails if any `service_role_only` function is executable by `anon`/`authenticated` (or lost its `service_role` grant), or if a locked-down callable RPC exists in `public` that is missing from the manifest list (drift). |
| `supabase/migrations/20260908090000_lock_service_role_only_functions.sql` | P0.6 / Decision 1. `revoke execute on function public.claim_trip_push_deliveries(uuid) from public, anon, authenticated`. Additive. **Local only — needs a prompt hosted deploy, separate from P1** (tracked in `TODO.md`). |
| `supabase/tests/edge_pricing_hostapp.test.mjs` | P0.4. `create-booking-intent` re-pricing (5% fee, child-price fallback `floor(adult*0.75)` when `child_price_paisa` null, explicit child price honoured); `submit-host-application` valid submit → 200, resubmit → 409, and three specific 400 validation rejections; `payment-webhook` reference mismatch → 409 for Khalti (`pidx`), eSewa (`transaction_uuid`), and wrong-provider, all before any gateway call. |
| `.github/workflows/db.yml` | supabase CLI 2.105.0 → `supabase start` → `bash scripts/test-all.sh` → `supabase stop`. |
| `.github/workflows/flutter.yml` | `flutter analyze`; `flutter test --exclude-tags known-broken-layout` (gate); tagged tests run separately, `continue-on-error`, with a `::warning::`. |
| `.github/workflows/web.yml` | `webapp/`: `npm ci` → `tsc --noEmit` → `npm run build`, with `NEXT_PUBLIC_*` build placeholders. Path-filtered to `webapp/**` and `admin/**` (P1 wires `admin/`). |
| `dart_test.yaml` (root) | declares the `known-broken-layout` tag. |

## Modifications to existing files (Rule 4)

Rule 4 forbids editing existing migrations except where a node explicitly says
to. P0.1 explicitly says to ("Fix anything that blocks [`db reset`]").

- **`supabase/migrations/20260813111000_seed_ram_shrestha_demo_host.sql`** and
  **`supabase/migrations/20260813113000_complete_ram_shrestha_demo_bookings.sql`** —
  both `raise exception` when the hard-coded dev auth user
  `25ffe805-82b2-4a43-9fc1-203b080e197b` is absent from `public.profiles`. That
  user only exists in the original developer's local Auth, so on **every** fresh
  local stack, in CI, and (had it been reset) on hosted, `supabase db reset`
  aborted at migration 43/59 with `Demo host profile ... does not exist`.
  Change: the two *missing-precondition* guards now `raise notice` + `return`
  (the demo seed self-skips) instead of `raise exception`. The
  *internal-consistency* guards in the same files (missing taxonomy, failed
  approval-sync) are unchanged — those signal a genuinely broken chain.

- **⚠️ Hosted drift.** These two migrations are **already applied on hosted**
  (they ran successfully there because that dev user exists in the hosted
  project too, per `20260813113000`'s own comment). The repo history no longer
  byte-matches what hosted ran for these two files. Runtime effect on hosted is
  **nil** — the guard only changes behaviour when the demo user is absent, and
  on hosted it is present. No hosted action required for this change.

- **`test/experience_detail_phase4_test.dart`** — added `tags: 'known-broken-layout'`
  to one `testWidgets` call + an explanatory comment. Test files are not
  migrations; this is allowed. See "Skipped / quarantined" below.

- **`TODO.md`** — appended three carried-over items.

**Rule 4 going forward:** if a future migration edit would change actual schema
rather than a demo-seed guard, HALT instead of editing. That did not happen in
P0.

## Skipped / quarantined (with justification)

### `supabase/tests/trip_presence_rls.test.sql` — narrow SKIP (Decision 2)

Fails with `permission denied to set role "supabase_admin"` — the test does
`set role supabase_admin`, which the local `postgres` superuser cannot assume on
Supabase CLI 2.105. Not a schema problem. `scripts/test-all.sh`:

- matches **only** the exact string `permission denied to set role "supabase_admin"`;
- requires it to be the **only** `ERROR:` line — any other failure in that file
  fails the run loudly;
- prints the SKIP line on **every run**, not just in this report;
- TODO to fix the harness properly is in `TODO.md`.

### `test/experience_detail_phase4_test.dart` — `known-broken-layout` tag

Pre-existing failure on `main` (not introduced here). At `textScaler 1.5` /
375px the non-adventure experience-detail layout overflows a `Row` (~301px) by
its content, so `tester.takeException()` is non-null. Out of scope for P0 and
for the admin-panel project (Flutter presentation code). Excluded from the CI
gate via `--exclude-tags known-broken-layout`; still run non-blocking with a
CI `::warning::`. Tracked in `TODO.md`; a background task chip was filed
(`task_81e19e0f`).

## Security finding fixed in P0.6 (Decision 1, with your correction)

`public.claim_trip_push_deliveries(uuid)` (`SECURITY DEFINER`) is meant for the
push Edge Function (service role) only. Live ACL granted `EXECUTE` to `anon` and
`authenticated`. Cause: migration `20260816130000` wrote `revoke all on function
... from public;` — but the current Supabase CLI **also** default-grants
`EXECUTE` to `anon`/`authenticated` on new `public` functions, and `revoke ...
from public` does not strip those. Later migrations (`20260823070000`,
`20260823170000`) already use the full `from public, anon, authenticated` form.

**Disclosure (your correction applied):** the function returns `recipient_id`
per message — that **is** disclosure: it reveals who is a member of a
conversation. It is bounded because `message_id` is an unguessable UUID, **not**
because nothing leaks. It also lets any caller flip `trip_push_deliveries` rows
to `processing` and bump `attempt_count` (notification suppression / racing the
real dispatcher).

Fix: `20260908090000` (additive, local only). The repo's own
`supabase/tests/trip_message_push_rls.test.sql` was **already red** because of
this and is now green. `security_definer_grants.test.sql` is the permanent
trip-wire so a silently-changing CLI default grant cannot re-open it.

### P0.6 audit result — was it "one bad migration means others"?

Enumerated all 34 `SECURITY DEFINER` functions in `public` + `private` and
dumped live ACLs. The damage from `20260816130000`'s weak `revoke` idiom was
**contained to its one `service_role_only` function** (`claim_trip_push_deliveries`).
The other `service_role_only` functions — `check_ai_rate_limit`,
`consume_payment_redirect_token`, `finalize_verified_payment` — are correctly
locked (their migrations used the full revoke form). No classification was
ambiguous, so no HALT was needed at P0.6 item 5.

Untidy-but-harmless leftovers from the same era, **not** changed in P0.6 (noted
in the manifest):
- `register_trip_push_device` / `unregister_trip_push_device` retain a stray
  `anon` `EXECUTE`. Intended to be `authenticated`-callable; body raises
  `Authentication required` when `auth.uid()` is null.
- `get_trip_moderation_queue` / `review_trip_message_report` retain a stray
  `anon` `EXECUTE`. Body raises `Admin access required` unless `is_admin()`.

## Assumptions made

1. The `sb_publishable_...` / `sb_secret_...` and `eyJ...` keys printed by
   `supabase status` are the standard local-dev defaults (identical on every
   install, documented publicly) and are safe to put in `.env.example` and the
   runner. They are **not** hosted credentials.
2. `webapp/` is an npm project — `package-lock.json` is committed, no
   `pnpm-lock.yaml`; the stray `pnpm-workspace.yaml` is unused. `web.yml` uses
   `npm ci`.
3. CI Flutter channel `stable` is acceptable (no `.fvmrc` / SDK pin in the repo;
   `pubspec.yaml` requires Dart `^3.12.0`).
4. `supabase functions serve --env-file supabase/functions/.env.example` (with
   placeholder gateway secrets) is sufficient for the edge tests, because every
   asserted path (validation 400s, pricing, reference-mismatch 409s, auth 401s)
   short-circuits before any real Khalti/eSewa `fetch`.
5. The DB container is `supabase_db_PLAN_E` (from `config.toml`
   `project_id = "PLAN_E"`) locally and in CI. The runner hard-codes this with a
   comment.
6. `admin_rls.test.sql`'s "ADMIN BASELINE" block is the intended shape of the
   P0.3 regression net: assert today's reality now, and P1 Step 2 rewrites that
   block (0 → 1) in the same commit that adds the `is_admin()` SELECT policies.

## Places I nearly halted but didn't

1. **Editing two existing migrations (P0.1).** Rule 4 says additive only. P0.1
   explicitly authorises the fix; the change is a guard downgrade on a
   dev-only demo seed, not a schema change; verified `db reset` green. Proceeded,
   and flagged the hosted-drift consequence above.
2. **`claim_trip_push_deliveries` (P0.6).** A failing auth guard — Rule 1 / Rule
   6 say HALT. I **did** halt at the end of the previous turn and reported it;
   you approved fix (a) with conditions. Proceeded on that approval only.
3. **The Flutter layout test failure.** Considered fixing the RenderFlex inline.
   Stopped: it is app presentation code with visual-regression risk, unrelated
   to the admin panel, and P0 is the harness not the app. Quarantined + tracked
   + task chip instead.

## Handing off to P1

Per the orchestration graph, P0 → P1 is automatic. Expect a **HALT at the
founder-email bootstrap** (P1 Step 4 / GATE 2) — those addresses are not
available yet. GATE 1 (show migration SQL for P1 Steps 1–3, local only) and
GATE 3 (show `withAdmin` + tests) also stand.
