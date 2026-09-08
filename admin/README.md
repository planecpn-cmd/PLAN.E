# Plan E — Admin panel

Separate Next.js 16 app, separate Cloudflare Worker (`plan-e-admin`), bound to
`admin.planenepal.com`. **Not** a route group inside `webapp/` — the service-role
key must never share a bundle with public pages.

## Security model (P1)

- **`profiles.role = 'admin'`** — the coarse gate the `is_admin()` RLS policies use.
- **`staff_members.scopes`** — the fine gate, enforced in the backend by
  `withAdmin()`. Scopes: `hosts:review`, `hosts:decide`, `bookings:read`,
  `payments:read`, `payments:act`, `finance:read`, `content:manage`,
  `staff:manage` (mirrors the DB CHECK in
  `supabase/migrations/20260908120000_*`).
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
-- as postgres, local only
select set_config('request.jwt.claims', '{"role":"service_role"}', true);
update public.profiles set role = 'admin' where id = '<your-local-auth-uid>';
insert into public.staff_members (user_id, status, scopes)
values ('<your-local-auth-uid>', 'active', array[
  'hosts:review','hosts:decide','bookings:read','payments:read',
  'payments:act','finance:read','content:manage','staff:manage'])
on conflict (user_id) do update set scopes = excluded.scopes;
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
