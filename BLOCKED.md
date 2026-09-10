# BLOCKED.md

Entries are appended by nodes that halt or cannot complete an item. Each entry names the node, the item, the exact failing query or command, and what unblocks it.

---

## B1: P0 #2, unpublish `demo-ram-mardi-himal-trek` (pre-N1, 2026-09-10)

**Status:** blocked on credentials. It is a data write, not a code change.

What was tried:

| Attempt | Command | Result |
|---|---|---|
| Linked CLI | `supabase db query --linked -f counts.sql` | `unexpected login role status 403: Your account does not have the necessary privileges to access this endpoint` |
| Anon REST | n/a. The anon key has no UPDATE on `experiences` (RLS), and an anon write was deliberately not attempted. | — |
| CI | `.github/workflows/db.yml` runs `supabase start` + tests against a **local** stack only. It never pushes migrations to the remote project. | a migration file would not reach production |

**To unblock:** someone with DB access (SQL editor, or `SUPABASE_DB_PASSWORD`) runs:

```sql
update public.experiences
set status = 'draft'            -- experience_status; confirm 'archived'/'rejected' if preferred
where slug = 'demo-ram-mardi-himal-trek'
returning id, slug, status;
-- expected: e1000000-0000-4000-8000-000000000001
```

**Side effect to accept first:** this listing owns the platform's **only** open future departure (2026-09-18). After the update, zero experiences are bookable. See AUDIT.md (c).

---

## B2: N1 sections that could not be verified with the anon key

These are recorded per instruction. They are not blocking N1.

| Claim | Query | Result |
|---|---|---|
| Review counts backed by rows | `GET /rest/v1/reviews?select=*` | `401 42501 permission denied for table reviews` |
| Booking volume / "trending" | `GET /rest/v1/bookings?select=*` | `401 42501 permission denied for table bookings` |
| Host verification | `GET /rest/v1/host_accounts?select=*` | `401 42501 permission denied for table host_accounts` |

Verdict in AUDIT.md: **not readable by anon key**. Any homepage section that depends on these stays omitted in `SECTIONS.json`.

---

## B3: Sections omitted because the data source returned empty

Rule 1: render nothing and log the exact query.

| Section | Query (anon) | Rows |
|---|---|---|
| N6 happening_this_week | `experience_departures?status=eq.open&start_date=gte.2026-09-10&start_date=lte.2026-09-16` | 0 |
| N8 app_showcase | `app_versions?select=*`, plus repo grep `apps.apple\|play.google` (only an update-intent URL template in `lib/core/native_intents.dart:26`) | 0 |
| N5 families: trips-tours, meet-people, give-back | published experiences whose `category_id` has `family_id` of that family | 0 each |
| (site-wide) legal pages | `legal_documents?select=slug,is_current` | 0 |
