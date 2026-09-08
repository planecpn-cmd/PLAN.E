# Plan E — Admin panel

Separate Next.js 16 app, separate Cloudflare Worker (`plan-e-admin`), bound to
`admin.planenepal.com`. **Not** a route group inside `webapp/` — the service-role
key must never share a bundle with public pages.

## Security model (P1)

- **`staff_members.status` + `staff_members.scopes`** — the authorization
  record. A staff member is `active` with a set of scopes:
  `hosts:review`, `hosts:decide`, `bookings:read`, `payments:read`,
  `payments:act`, `finance:read`, `content:manage`, `staff:manage` (mirrors the
  DB CHECK in `20260908120000_*` and `src/lib/scopes.ts`).
- **Every business-table read is gated by the matching scope, in RLS.**
  `20260908140000` replaced bare `is_admin()` with
  `public.has_scope(<scope>)` on `bookings` / `booking_participants` /
  `experience_departures` / `legal_acceptances` (`bookings:read`), `payments`
  (`payments:read`), `host_applications` / `host_accounts` (`hosts:review`),
  `experiences` / `reviews` (`content:manage`). So a `hosts:review`-only
  moderator hitting the REST API with their own JWT reads host applications and
  **nothing else** — the scope model is no longer withAdmin-only.
- **`staff_members` self-read** (`user_id = auth.uid()`) lets a staff member log
  in and see their own scopes **without** `profiles.role = 'admin'`. Reading
  *other* staff rows needs `is_admin()` or the `staff:manage` scope.
- **`profiles.role = 'admin'` is founder-only.** The founder bootstrap
  (`20260908130000`) sets it for founders and gives them all eight scopes.
  Moderators get a `staff_members` row with a subset of scopes and **never**
  `role = 'admin'`. `role = 'admin'` still gates: `config_audit_log` /
  `admin_audit_log` reads, direct-JWT config-table writes, and the Flutter
  message-moderation RPCs (`get_trip_moderation_queue` etc.).
- **`withAdmin()`** re-checks the scope for every API route regardless — the RLS
  scope gate and the withAdmin scope gate are defence in depth, not either/or.
- **`src/lib/service-role.ts`** — the only module that reads
  `SUPABASE_SERVICE_ROLE_KEY`. Reachable only through `src/lib/with-admin.server.ts`.
  Enforced by `eslint` (`no-restricted-imports`) **and**
  `src/lib/no-service-role-import.test.ts` (a test — cannot be silenced with an
  inline comment).
- **`withAdmin(scope, handler, { mutating })`** (`src/lib/with-admin.ts`) — every
  API route goes through it: verify session JWT → load `staff_members` → check
  scope → build `AdminContext` (with the service-role `db`) → run handler →
  write `admin_audit_log` for mutating handlers, even on throw.
- Pages use `requireAdmin()` / `requireScope()` (`src/lib/session.ts`), which read
  `staff_members` with the **anon session client** (its RLS is `is_admin()`), so
  the service-role client never enters the render tree.

## Local dev

```sh
cp .env.local.example .env.local        # points at the local supabase stack
npm install
npm run dev                              # http://localhost:3000
```

You need a local staff member. With the local stack running, either fill
`supabase/migrations/20260908130000_founder_bootstrap.sql`'s `v_emails` and
`supabase db reset`, or run once against the local DB:

```sql
-- as postgres, local only.
select set_config('request.jwt.claims', '{"role":"service_role"}', true);
insert into public.staff_members (user_id, status, scopes)
values ('<your-local-auth-uid>', 'active', array[
  'hosts:review','hosts:decide','bookings:read','payments:read',
  'payments:act','finance:read','content:manage','staff:manage'])
on conflict (user_id) do update set status = 'active', scopes = excluded.scopes;

-- role = 'admin' is NOT required to sign in (staff_members self-read handles
-- that). Add it only if you also need config_audit_log / admin_audit_log reads
-- or the message-moderation RPCs locally:
-- update public.profiles set role = 'admin' where id = '<your-local-auth-uid>';
```

## Checks

```sh
npm run typecheck     # tsc --noEmit
npm run lint          # eslint (incl. the service-role import ban)
npm run test          # vitest — withAdmin suite + service-role import boundary
npm run build         # next build
```

## Deploy (not automated here)

```sh
npx wrangler secret put NEXT_PUBLIC_SUPABASE_ANON_KEY   --name plan-e-admin
npx wrangler secret put SUPABASE_SERVICE_ROLE_KEY       --name plan-e-admin
npm run deploy                                          # opennextjs-cloudflare build + deploy
```

## Cloudflare Access — put it in front of the hostname (manual, dashboard)

Do this **before** the panel handles anything real. It is a second factor that
runs before the app even loads.

1. Cloudflare dashboard → **Zero Trust** → **Access** → **Applications** → **Add
   an application** → **Self-hosted**.
2. Application domain: `admin.planenepal.com` (whole hostname, no path).
3. **Session duration**: 24h or shorter.
4. **Policies** → add a policy `staff`:
   - Action: **Allow**
   - Include: **Emails** → the founder / staff email addresses (or **Emails
     ending in** your company domain, or a Google Workspace group).
   - Require: **one-time PIN** or your IdP.
5. Add a second policy **Block** / `everyone else` with Include **Everyone**,
   below `staff`.
6. Save. Verify: an allowed email gets the Access challenge then the app; anyone
   else is stopped by Cloudflare before Next runs.

Access is defence-in-depth on top of the app's own session + `staff_members` +
scope checks — not a replacement for them.

## Deliberately NOT built yet (P1 scope)

- Any host-review, bookings, payments, finance, or staff-management screen (P2/P3).
- Editing `app_config` / `remote_content` / `app_versions` (only `feature_flags`
  toggling is wired, to prove the `withAdmin` write path).
- Admin INSERT/UPDATE/DELETE RLS policies — there are none; all writes are
  service-role via `withAdmin` with an audit row.
- A generic table browser, charts, analytics (see plan §4).
