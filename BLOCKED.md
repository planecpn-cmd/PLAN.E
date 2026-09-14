# BLOCKED.md

Entries are appended by nodes that halt or cannot complete an item. Each entry names the node, the item, the exact failing query or command, and what unblocks it.

---

## B1: P0 #2, unpublish `demo-ram-mardi-himal-trek` (pre-N1, 2026-09-10)

**Status:** blocked on credentials. It is a data write, not a code change. **Superseded by B7**, which runs the same update and must run *after* B6.

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

---

# P0-CRIT (2026-09-10)

**Update (INFRA node):** B6 and B7 now ship as `supabase/migrations/20260910200000_close_past_departures_unpublish_demo.sql`. B8 ships as `supabase/migrations/20260910200100_recategorise_mislabelled_listings.sql`, commented out until you decide. `deploy.yml` applies them on merge to `main`, so **do not also run the SQL below by hand**. Two differences from the SQL below:
- The migration's past-departure cutoff is the fixed audit date `2026-09-10`, not `now()`. This makes it exact and reversible.
- B8 matches rows with `is distinct from`, so re-running it is a no-op.

Pushing and PR setup is in `SETUP.md`.

Original instructions (kept for reference): run B6, then B7, then (after your decision) B8. Each block is a single transaction. Run them in the Supabase SQL editor as `postgres`. The anon key cannot write any of this.

## B4: PRs for items 1–4 could not be opened

The branches exist locally, one per item, each cut from `main`:

| Item | Branch | Commit |
|---|---|---|
| 1 Reject past departures in `create-booking-intent` + test | `p0crit/1-reject-past-departure` | `543963a` |
| 2 Drop `aggregateRating` from JSON-LD | `p0crit/2-jsonld-no-rating` | `f1f13e0` |
| 3 Remove rating badges / review counts | `p0crit/3-remove-rating-badges` | `5e8983c` |
| 4 Past departures render as closed | `p0crit/4-past-departures-closed` | `59db403` |

What failed:
- `git push -u origin p0crit/1-reject-past-departure` returned `fatal: could not read Username for 'https://github.com': terminal prompts disabled`.
- The `gh` CLI is logged in as `agrawalsamaj838-blip` with `viewerPermission: READ` on `planecpn-cmd/PLAN.E`.

Merge check: an octopus merge of all four onto `main` is conflict-free and passes `tsc`. The temp branch was deleted.

**To unblock:** someone with write access runs, per branch:

```bash
git push -u origin p0crit/1-reject-past-departure
gh pr create --base main --head p0crit/1-reject-past-departure --fill
```

Deploy note: item 1 is an edge function. Merging does not deploy it. Run `supabase functions deploy create-booking-intent`; the linked CLI here returns 403.

## B5: Item 5, legal + cookie-banner links. Finding: EMPTY, not RLS-blocked

| Probe (anon key, production) | Result | Meaning |
|---|---|---|
| `GET legal_documents?select=id` | `200`, `content-range */0` | anon has SELECT (a missing grant returns 401, as `reviews` and `legal_acceptances` do) |
| `GET legal_documents?select=id&is_current=eq.true` | `200`, `*/0` | the anon policy is `using (is_current)` (`20260905120000_legal_documents_and_acceptances.sql:76-78`), so every current row would be visible. Zero current rows exist. |

**Verdict:**
- **Zero current rows; not RLS-blocked.** The migration is applied in production (the table and grant exist), and there are **no `is_current = true` rows**.
- **Non-current rows can't be ruled out from anon.** Any draft rows would be hidden by the policy. They would not render either way, because the web only queries `is_current = true` (`webapp/src/lib/data/legal.ts:20,33`).
- **Probable cause:** nothing has been seeded. `supabase/scripts/seed-legal.mjs` refuses documents with unfilled `[PLACEHOLDER]`s, and `supabase/legal/placeholders.json` has **22 of 23** values empty.

**To unblock:**
1. Fill `supabase/legal/placeholders.json`. This is legal content, and N1 did not write it.
2. Run the seed with DB credentials.

Until then, all 13 `/legal/<slug>` pages 404: the footer links, the cookie-banner "Cookie Policy" link, and the experience, checkout and confirmation page links. No code change was made.

## B6: Item 6, close the 90 past-dated open departures (run FIRST)

`experience_departures.status` is free text. `'closed'` is the value already used by the demo seed (`20260813111000_seed_ram_shrestha_demo_host.sql:192`). "Past" is judged by Nepal's calendar date, the same rule as the code fix in item 1.

```sql
begin;

-- Preview: expect 90 rows, all start_date < today (Nepal).
select count(*) as to_close, min(start_date), max(start_date)
from public.experience_departures
where status = 'open'
  and start_date < (now() at time zone 'Asia/Kathmandu')::date;

update public.experience_departures
set status = 'closed'
where status = 'open'
  and start_date < (now() at time zone 'Asia/Kathmandu')::date
returning id, experience_id, start_date;

-- Check: expect exactly 1 open future departure remaining
-- (2026-09-18, experience e1000000-0000-4000-8000-000000000001).
select id, experience_id, start_date, spots_left
from public.experience_departures
where status = 'open';

commit;   -- or rollback; if the preview count is not 90
```

The update only touches `status`. It does not delete departures, so existing bookings that reference them are unaffected.

## B7: Item 7, unpublish `demo-ram-mardi-himal-trek` (run AFTER B6)

```sql
begin;

update public.experiences
set status = 'draft'
where slug = 'demo-ram-mardi-himal-trek'
  and status = 'published'
returning id, slug, status;
-- expect: e1000000-0000-4000-8000-000000000001 | demo-ram-mardi-himal-trek | draft

-- Close its departure too, so it cannot be booked by id while unpublished.
update public.experience_departures
set status = 'closed'
where experience_id = 'e1000000-0000-4000-8000-000000000001'
  and status = 'open'
returning id, start_date;

commit;
```

**After B6 + B7, zero experiences have an open future departure.** Every detail page will show "Closed: no upcoming departures" (item 4), and booking is refused server-side (item 1). That is the correct state until real departures are added.

`draft` is the column default for `experience_status`. If you prefer another terminal value, check the enum first (`select unnest(enum_range(null::experience_status));`).

## B8: Item 8, recategorise mislabelled listings (YOUR DECISION; nothing run)

Existing adventure categories are `trekking, hiking, camping, climbing, wildlife`. None of them fits rafting, paragliding or biking. For those three, the honest choices are:
- **(a)** leave as-is,
- **(b)** move to the nearest existing category, or
- **(c)** add a new category. That is a schema/taxonomy change and needs a migration (rule 6), and it must be mirrored in the Flutter `experience_family.dart` map.

| slug | current | proposed (existing category) | alternative |
|---|---|---|---|
| everest-heli-tour | `wellness` (Mind & Soul) | `day-trip` (Trips & Tours) | `guided-tour` (Trips & Tours) |
| bhotekoshi-whitewater-rafting | `camping` (Adventure Together) | no good existing fit; keep `camping` or use `group-activity` (Meet People) | new `rafting` / `water-sports` under adventure-together |
| pokhara-paragliding | `hiking` (Adventure Together) | `day-trip` (Trips & Tours) | new `air-sports` under adventure-together |
| phulchowki-mountain-biking | `hiking` (Adventure Together) | keep `hiking` (closest outdoor day activity) | new `cycling` under adventure-together |
| kakani-trout-strawberry | `homestay` (Live Like a Local) | `food-experience` (Live Like a Local) | `farm-experience` (Live Like a Local) |
| *(weak)* bhaktapur-pottery-workshop | `culture` (Live Like a Local) | `craft-workshop` (Live Like a Local) | keep `culture` |

SQL template. Uncomment only the rows you approve; each resolves the category by slug:

```sql
begin;

-- update public.experiences set category_id = (select id from public.categories where slug = 'day-trip')
--   where slug = 'everest-heli-tour' returning slug, category_id;

-- update public.experiences set category_id = (select id from public.categories where slug = 'food-experience')
--   where slug = 'kakani-trout-strawberry' returning slug, category_id;

-- update public.experiences set category_id = (select id from public.categories where slug = 'craft-workshop')
--   where slug = 'bhaktapur-pottery-workshop' returning slug, category_id;

-- update public.experiences set category_id = (select id from public.categories where slug = 'day-trip')
--   where slug = 'pokhara-paragliding' returning slug, category_id;

-- bhotekoshi-whitewater-rafting / phulchowki-mountain-biking: decide (a)/(b)/(c) first.

commit;
```

Side effects to know:
- **The home family rails would change.** Moving the heli tour to `day-trip` leaves Mind & Soul with 1 experience and gives Trips & Tours its first. Moving paragliding would add a second. That also un-empties the "Curated Trips" target.
- **Sections that key on `category_id` would re-bucket.** `home.ts` filter chips match on category slug as well as free text. The `experiences.search_tsv` trigger (if any) is unaffected by `category_id`.
