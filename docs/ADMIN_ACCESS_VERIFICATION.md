# Admin access control — verified, not assumed

Every admin page and API route was hit directly (no nav clicks) as five real
identities, against the local stack reset + seeded fresh
(`supabase db reset` + `supabase/tests/seed_test.sql`), on 2026-09-11. This
records what actually happened, checked by re-running twice (once after
discovering and fixing a stale dev-server cache — see the note under
"How this was run"). Nothing here is inferred from reading the code; the
static analysis (grep-ing every `withAdmin("scope", ...)` and
`requireScope("scope")` call) was used only to build the test matrix — every
cell was then executed for real.

**Result: no route let a, b, c, or d through, on any of the 22 API route
files (23 method+path combinations) or 10 gated pages. HALT condition never
triggered.** Two non-security documentation/behavior mismatches were found
and are reported below (§ Findings) — neither is an access-control failure.
**Both have since been fixed in code and re-verified live on 2026-09-12**
(migration `20260912090000_decide_scopes_can_read_their_queue.sql`,
`admin/src/lib/session.ts`'s `requireAnyScope`, and `admin/src/proxy.ts`) —
see the "Fixed" note under each finding.

---

## Identities used

| # | Identity | How it was made | Expected |
|---|---|---|---|
| a | Signed out | No session at all | Blocked everywhere |
| b | Traveler | Real user, `traveler@planetest.local` (seed), **no `staff_members` row** | Blocked everywhere |
| c | Suspended staff | New user `avc-suspended@planetest.local`, `staff_members.status = 'suspended'`, **holding all ten scopes** | Blocked everywhere, despite full scopes — proves suspension is checked independently of scope |
| d | Wrong scope | New user `avc-wrongscope@planetest.local`, `status = 'active'`, `scopes = {finance:read}` only | Blocked everywhere except `/` (which needs only "any active staff", not a specific scope) — `finance:read` gates nothing in the app today, so this one account is provably "wrong" for every route |
| e | Right scope | The seed founder, `admin@planetest.local`, scopes **narrowed to exactly one scope at a time** via direct SQL (8 rounds: `content:manage`, `content:decide`, `hosts:review`, `hosts:decide`, `bookings:read`, `payments:read`, `payments:act`, `users:manage`), restored to all ten afterward | Only the routes that scope actually gates should pass; every other route in the same round should still be blocked |

Testing "right scope" as one scope at a time (rather than the founder's
usual full set) is a stronger proof than "someone with everything works" —
it proves each scope is independently sufficient and that nothing is
over-granted by another scope in the same round.

## How this was run

Both layers were hit with a real signed-in browser session's cookies (this
app authenticates via Supabase SSR cookies only — no bearer-token path
exists, confirmed by reading `admin/src/lib/supabase/server.ts`), using
`fetch()` executed inside the page via the browser's JS console — a raw
request, not a button click, exactly as required. Mutating (POST/PATCH)
routes were called with an **empty JSON body** and, for pages with an
`[id]`, a **nonexistent UUID** (`00000000-0000-0000-0000-000000000000`),
never real seed IDs — this proves whether the request got *past* the
`withAdmin`/`requireScope` gate (any response other than 401/403) without
ever completing a real mutation, since every mutating route's own body/
existence validation runs strictly after its scope check and fails cleanly
(400 "reason required", 404 "not found", etc.) before touching real data.
For `bookings:read`'s read-only round, real seed IDs were used to confirm
actual data renders, since there is no mutation risk there.

**One artifact hit and resolved before trusting any result:** partway
through identity (b), two nested-dynamic-segment routes
(`/api/experiences/[id]/photos/url`, `/api/host-applications/[id]/documents/[docId]/url`)
returned Next's own framework 404 HTML instead of ever reaching
`withAdmin` — meaning that specific request was neither blocked nor
granted, it just never routed. This traced to a stale Turbopack dev-server
route manifest (this exact project directory was affected by an unrelated
concurrent-session incident earlier in the day — see
`../PLAN-E-automation/SETUP.md`). Clearing `admin/.next` and restarting the
dev server fixed it immediately; both routes then answered normally. **All
results below are from the clean, post-restart run**, and both routes were
independently re-confirmed working in every identity that followed.

## Full results

Legend: 🔒 = blocked (page → `/not-authorized` or `/login`; API → 401/403
JSON). ✅ = passed the auth gate (page rendered or 404'd on the fake ID
after rendering; API returned its own business status — 200 with real data,
or 400/404/503 from validation/business logic, never 401/403).

### Pages

| Page | Scope | a | b | c | d | e (matching scope) |
|---|---|---|---|---|---|---|
| `/` | any active staff | 🔒→`/login` | 🔒→`/not-authorized` | 🔒→`/not-authorized` | ✅ 200 (finance:read is enough — it's "any active staff") | ✅ 200, every round |
| `/config` | `content:manage` | 🔒 | 🔒 | 🔒 | 🔒 | ✅ 200 |
| `/host-applications` | `hosts:review` | 🔒 | 🔒 | 🔒 | 🔒 | ✅ 200 |
| `/host-applications/[id]` | `hosts:review` | 🔒 | 🔒 | 🔒 | 🔒 | ✅ 404 (fake id, right scope) |
| `/experiences` | `content:manage` | 🔒 | 🔒 | 🔒 | 🔒 | ✅ 200 |
| `/experiences/[id]` | `content:manage` | 🔒 | 🔒 | 🔒 | 🔒 | ✅ 404 (fake id, right scope) |
| `/bookings` | `bookings:read` | 🔒 | 🔒 | 🔒 | 🔒 | ✅ 200, real rows |
| `/bookings/[id]` | `bookings:read` | 🔒 | 🔒 | 🔒 | 🔒 | ✅ 200, real booking |
| `/payments` | `payments:read` | 🔒 | 🔒 | 🔒 | 🔒 | ✅ 200 |
| `/users` | `users:manage` | 🔒 | 🔒 | 🔒 | 🔒 | ✅ 200, real rows |
| `/login` | public | ✅ 200 | ✅ 200 | ✅ 200 | ✅ 200 | ✅ 200 |
| `/not-authorized` | public (signed-in landing) | ✅ 200 | ✅ 200 | ✅ 200 | ✅ 200 | ✅ 200 |

### API routes

`GET`/list/detail routes:

| Route | Scope | a | b | c | d | e |
|---|---|---|---|---|---|---|
| `GET /api/bookings` | `bookings:read` | 🔒 | 🔒 403 | 🔒 403 | 🔒 403 | ✅ 200, real rows |
| `GET /api/bookings/[id]` | `bookings:read` | 🔒 | 🔒 403 | 🔒 403 | 🔒 403 | ✅ 200, real booking |
| `GET /api/config/feature_flags` | `content:manage` | 🔒 | 🔒 403 | 🔒 403 | 🔒 403 | ✅ 200, real flags |
| `GET /api/experiences` | `content:manage` | 🔒 | 🔒 403 | 🔒 403 | 🔒 403 | ✅ 200 |
| `GET /api/experiences/[id]` | `content:manage` | 🔒 | 🔒 403 | 🔒 403 | 🔒 403 | ✅ 404 (fake id) |
| `GET /api/experiences/[id]/photos/url` | `content:manage` | 🔒 | 🔒 403 | 🔒 403 | 🔒 403 | ✅ 404 (fake id) |
| `GET /api/host-applications` | `hosts:review` | 🔒 | 🔒 403 | 🔒 403 | 🔒 403 | ✅ 200, real rows |
| `GET /api/host-applications/[id]` | `hosts:review` | 🔒 | 🔒 403 | 🔒 403 | 🔒 403 | ✅ 404 (fake id) |
| `GET /api/host-applications/[id]/documents/[docId]/url` | `hosts:review` | 🔒 | 🔒 403 | 🔒 403 | 🔒 403 | ✅ 404 (fake id) |
| `GET /api/payments` | `payments:read` | 🔒 | 🔒 403 | 🔒 403 | 🔒 403 | ✅ 200, real rows |
| `GET /api/users` | `users:manage` | 🔒 | 🔒 403 | 🔒 403 | 🔒 403 | ✅ 200, real rows |

`POST`/`PATCH` mutating routes (all right-scope tests below used an empty
body + fake id — the status shown is what the request got *past the gate
to*, not a completed mutation):

| Route | Scope | a | b | c | d | e |
|---|---|---|---|---|---|---|
| `POST /api/bookings/[id]/cancel` | `payments:act` | 🔒 | 🔒 403 | 🔒 403 | 🔒 403 | ✅ 400 "a cancellation reason is required" |
| `PATCH /api/config/feature_flags` | `content:manage` | 🔒 | 🔒 403 | 🔒 403 | 🔒 403 | ✅ 400 "key and patch are required" |
| `POST /api/experiences/[id]/decision` | `content:decide` | 🔒 | 🔒 403 | 🔒 403 | 🔒 403 | ✅ 400 "decision must be ..." |
| `POST /api/experiences/[id]/recommendation` | `content:manage` | 🔒 | 🔒 403 | 🔒 403 | 🔒 403 | ✅ 400 "decision must be ..." |
| `POST /api/host-applications/[id]/decision` | `hosts:decide` | 🔒 | 🔒 403 | 🔒 403 | 🔒 403 | ✅ 400 "decision must be ..." |
| `POST /api/host-applications/[id]/documents/[docId]/verify` | `hosts:review` | 🔒 | 🔒 403 | 🔒 403 | 🔒 403 | ✅ 400 "verified (boolean) is required" |
| `POST /api/host-applications/[id]/recommendation` | `hosts:review` | 🔒 | 🔒 403 | 🔒 403 | 🔒 403 | ✅ 400 "decision must be ..." |
| `POST /api/payments/[id]/refund` | `payments:act` | 🔒 | 🔒 403 | 🔒 403 | 🔒 403 | ✅ 400 "a refund reason is required" |
| `POST /api/payments/[id]/reverify` | `payments:act` | 🔒 | 🔒 403 | 🔒 403 | 🔒 403 | ✅ 503 "ADMIN_REVERIFY_SECRET is not configured" — passed the scope gate; local env has no gateway secret, so this is as far as it can go without real sandbox creds (see § What could not be fully exercised) |
| `POST /api/refunds/[id]/settle` | `payments:act` | 🔒 | 🔒 403 | 🔒 403 | 🔒 403 | ✅ 400 "toStatus must be one of ..." |
| `POST /api/users/[id]/reactivate` | `users:manage` | 🔒 | 🔒 403 | 🔒 403 | 🔒 403 | ✅ 400 "user not found" (fake id — reached the RPC) |
| `POST /api/users/[id]/suspend` | `users:manage` | 🔒 | 🔒 403 | 🔒 403 | 🔒 403 | ✅ 400 "a suspension reason is required" |

For (a), every one of the 34 rows above resolved to `finalPath: "/login"`,
`status: 200`, with an **identical generic login-page HTML body** — this
was checked explicitly (not assumed): no API route, when hit fully signed
out, returned any fragment of real data before redirecting. This is Next's
own `proxy.ts` middleware intercepting the request before it reaches the
page or API handler at all (see § Findings for the one wrinkle this causes
for API callers).

## Findings

**None are access-control failures — nothing here let an unauthorized
identity see or do more than intended.**

1. ~~Signed-out API calls redirect to an HTML login page rather than
   returning a JSON 401.~~ **FIXED (2026-09-12).** `admin/src/proxy.ts`
   intercepted every request (its matcher excludes only static assets) when
   there was no session at all, and issued an HTTP redirect to `/login` —
   including for `/api/*`, ahead of `withAdmin`'s own clean 401. Was never a
   security gap (no data leaked — the body was generic login HTML,
   byte-identical across every route), just poor API hygiene for a
   programmatic caller. Fix: `proxy.ts` now checks `path.startsWith("/api/")`
   and returns `Response.json({error:"not authorized"}, {status:401})`
   directly for that case, before the redirect branch; a page request still
   redirects to `/login` as before. Re-verified live, signed out:
   `fetch('/api/bookings')` → `401`, body `{"error":"not authorized"}`,
   `res.type === "basic"` (a real response, not an opaque redirect). Page
   behavior unchanged: `fetch('/bookings')` still lands on `/login`, 200.

2. ~~`content:decide`, `hosts:decide`, and `payments:act`, held alone,
   cannot open their own screens.~~ **FIXED (2026-09-12), option (a) from
   the original write-up — page access widened, not the doc corrected**,
   per explicit instruction: the whole point of a decide-only scope is that
   someone can be trusted to decide without also being trusted to
   review/triage, and the old behavior defeated that split by making the
   scope practically unusable alone.

   **The fix has two layers, both required** — widening the page gate alone
   is not enough, because these Server Components read their business data
   through the anon session client, which is itself bound by RLS:
   - `admin/src/lib/session.ts` gained `requireAnyScope(scopes[])`; the 5
     affected pages (`/experiences`, `/experiences/[id]`,
     `/host-applications`, `/host-applications/[id]`, `/payments`) now use
     it in place of `requireScope`, accepting either scope in the pair.
   - Migration `20260912090000_decide_scopes_can_read_their_queue.sql`
     widens the matching RLS SELECT policies (`experiences`,
     `experience_reviews`, `experience_departures`, `host_applications`,
     `host_documents`, `host_application_reviews`, `payments`) to accept
     the paired scope too.
   - No component change was needed: `ExperienceReviewPanel` and
     `ReviewPanel` already rendered the Decision-only controls (taxonomy +
     decide buttons, no recommend controls) whenever `canDecide` was true —
     that split was already correct, it just never got the chance to run
     for a decide-only session before now.

   **Re-verified live**, narrowing the founder to exactly one scope at a
   time (same methodology as the original pass):
   - `content:decide` alone: `/experiences?status=published` renders all
     30 real published listings (200, real data, not empty); opening
     `/experiences/33333333-3333-4333-8333-000000000001` renders the full
     submitted-listing detail, departure, and a **"DECISION"** section
     with the taxonomy pickers and Approve/Reject/Request changes/Mark
     under review buttons — no "Recommendation" section, confirming the
     panel shows decide controls only, never the recommend ones, for a
     decide-only session.
   - `hosts:decide` alone: `/host-applications` renders both seed
     applications; the submitted one's detail page renders the full
     application and documents section plus the same **"DECISION"**
     button set.
   - `payments:act` alone: `/payments` renders all real payment rows
     (initiated/paid/failed) with the Re-verify / Create refund action
     forms visible and usable.
   - The now-unrelated GET `/api/experiences` route (queried by nothing in
     the admin frontend — grepped, no consumer) still 403s for
     `content:decide`-only; harmless, since the page never calls it, and
     out of scope for this fix (it wasn't part of what the page needed).

   SQL test files `experience_review_rls.test.sql` and
   `host_review_rls.test.sql` had asserted the *old* (bug) behavior as
   correct — a decide-only session reading 0 rows — updated to assert the
   new intended behavior (≥1 row) instead. Full suite re-run green
   (26 pass + 1 documented skip; edge 4/4) after the migration.

## What could not be fully exercised

- **Payment re-verify** (`POST /api/payments/[id]/reverify`) passed its
  scope gate cleanly (503, not 401/403) but cannot go further locally: the
  local dev env has no `ADMIN_REVERIFY_SECRET` / Khalti-eSewa sandbox
  credentials configured (same limitation already noted in
  `docs/ADMIN_SMOKE_CHECKLIST.md`). The access-control boundary is proven;
  the feature behind it is not exercised end-to-end here.

## No admin route reachable from `planenepal.com`

Checked directly, not assumed:

- `webapp/src` (the public site) contains **zero** references to
  `admin.planenepal.com`, `staff_members`, `admin_audit_log`, or any
  `/api/users`-, `/host-applications`-, `/experiences`-review-shaped path —
  confirmed by grep across the whole tree.
- `webapp/wrangler.jsonc` routes only `planenepal.com` and
  `www.planenepal.com` to the public Worker.
- `admin/wrangler.jsonc` routes only `admin.planenepal.com`, to a
  **separate** Cloudflare Worker (`plan-e-admin`) — confirmed in
  `admin/README.md`: "Separate Next.js 16 app, separate Cloudflare Worker
  ..., bound to `admin.planenepal.com`. **Not** a route group inside
  `webapp/`."

No shared code path, no shared route, no shared domain.

## Service-role key: absent from the client bundle

Ran a real production build (`npm run build`) and grepped the output, not
the source:

```
grep -rl "<the actual local service-role key literal>" admin/.next        # 0 matches anywhere in the build
grep -rl "SUPABASE_SERVICE_ROLE_KEY" admin/.next/static                    # 0 matches — this is the client bundle
grep -rl "SUPABASE_SERVICE_ROLE_KEY" admin/.next                           # matches only under .next/server/** and
                                                                             # the turbopack dev cache — server-only
                                                                             # code, never shipped to a browser
```

The key literal appears **nowhere** in the entire build output, not even
server-side — it's read live from `process.env` at request time
(`admin/src/lib/service-role.ts`), never inlined as a build-time constant.
Only `NEXT_PUBLIC_*`-prefixed variables are ever inlined into
`.next/static`, and `SUPABASE_SERVICE_ROLE_KEY` is not one of them. This
matches the existing structural guard (`eslint no-restricted-imports` +
`admin/src/lib/no-service-role-import.test.ts`) that already keeps every
other file from importing `service-role.ts` — this is the same guarantee,
confirmed against the actual compiled output rather than just the import
graph.

## A signed-out deep link never leaks a partial render

Confirmed directly: every one of the 10 gated pages, hit signed-out at its
exact URL (no nav, no home page first), landed on `/login` with
`response.redirected: true` and an identical generic login-page body. No
page rendered any fragment of its own content — no partial DOM, no data in
an inline script tag, no flash of real content — before the redirect. This
is enforced by `proxy.ts` running before any page component executes, not
by the page choosing to hide its own content after rendering.

## Cleanup

Two throwaway staff identities were created for this pass —
`avc-suspended@planetest.local` and `avc-wrongscope@planetest.local` — and
the founder's own scopes were temporarily narrowed through 8 rounds and
restored to all ten afterward (confirmed restored). All of this is wiped
by the next `supabase db reset`; nothing here persists as real state.
