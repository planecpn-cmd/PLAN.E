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

1. **Signed-out API calls redirect to an HTML login page rather than
   returning a JSON 401.** `admin/src/proxy.ts` intercepts every request
   (its matcher excludes only static assets) when there is no session at
   all, and issues an HTTP redirect to `/login` — including for `/api/*`.
   `withAdmin`'s own clean `401` JSON response (confirmed real in
   `with-admin.test.ts`) never gets a chance to run for a fully signed-out
   caller, because middleware answers first. The result is still fully
   blocked (no data leaks — the body is generic login HTML, byte-identical
   across every route tried), but a programmatic API caller with no
   session gets a redirect + HTML instead of a clean 401 JSON error. Worth
   a small fix for API hygiene (skip the middleware redirect for `/api/*`
   and let `withAdmin` answer with its own 401 there), but not urgent and
   not a security gap.

2. **`content:decide`, `hosts:decide`, and `payments:act`, held alone,
   cannot open their own screens — despite `docs/ADMIN_SCOPES.md` implying
   they can.** All three route pages (`/experiences`, `/host-applications`,
   `/payments`) are gated on the paired read/manage/review scope only
   (`content:manage`, `hosts:review`, `payments:read` respectively) — not
   on the decide/act scope. A moderator holding *only* `content:decide`
   (or `hosts:decide`, or `payments:act`) can genuinely approve a listing /
   decide a host application / cancel a booking or create a refund via a
   direct API call (verified: each passed its scope gate and hit real
   business validation) — but cannot load the page to do it through the
   UI at all; the page redirects them to `/not-authorized` first.
   `ADMIN_SCOPES.md` currently says `content:decide` "(Same as above.)"
   for what it can see, and `payments:act` "(Also sees payments.)" — both
   read as if the decide/act scope alone grants the view, which it does
   not in the running code. **This needs a decision, not a silent fix**:
   either (a) also grant page access when the staff member holds the
   paired decide/act scope without the read/review/manage one — which
   changes who can see what, a security-relevant choice — or (b) correct
   `ADMIN_SCOPES.md` to say plainly that a decide/act-only moderator needs
   the paired scope too to use the panel at all, which is how every
   founder has in fact been granting these in practice (`ADMIN_SCOPES.md`'s
   own "rule of thumb" already says to grant the read scope alongside).
   Recommend (b) — it matches actual granting practice and is a one-line
   doc fix — but flagging rather than changing it unilaterally, since it's
   a decision about intended behavior, not a bug in behavior.

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
