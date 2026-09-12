# AUDIT.md — N1 Truth audit (read-only)

- **Run:** 2026-09-10, branch `admin-panel/p0-test-harness`, after P0 commit `8f7840f`.
- **Lens:** Supabase **anon key** over PostgREST, the same view the marketing site gets. No service key was used. Tables the anon key cannot read get the verdict **not readable by anon key**.
- **Runtime checks:** `next dev` on `localhost:3000`, reading the SSR HTML.
- **Scope:** read-only. This audit fixed nothing.
- **"Today":** `2026-09-10`. **"This week":** `2026-09-10 … 2026-09-16`.

**GATE H1: NOT APPROVED.** A human must approve the P0 list in §8 before N3–N9.

---

## 0. P0 pre-work outcome (requested before N1)

| # | Request | Outcome |
|---|---|---|
| 1 | Remove `/ai-planner`, `/notifications`, `/profile/help` from nav and footer | **Done** in `8f7840f`. Removed `/notifications` from both TopNav branches, `/profile/help` from the Footer, and `/ai-planner` from the home hero button (the only place it was linked). No stub pages were created. Checked on the dev server: none of the three hrefs appear on `/`. |
| 2 | Unpublish `demo-ram-mardi-himal-trek` | **NOT DONE. Blocked.** This is a data write. The anon key cannot update `experiences`, `supabase db query --linked` returns 403, and CI (`.github/workflows/db.yml`) only runs against a local stack. It never pushes to the remote. Someone with DB or admin access must run the SQL in `BLOCKED.md`. The commit subject names the demo listing because that is the message you specified. The commit body states that the unpublish was not done. |
| 3 | Normalise the family name to "Mind & Soul" in the webapp | **Done** in `8f7840f`. Changed `lib/data/home.ts:31` and `app/(main)/collection/[slug]/page.tsx:17`. Flutter was not touched. It still contains `'Soul & Mind'` at `lib/features/home/home_discovery.dart:58`. |
| 4 | What is the 6th family? Is there an active flag? | See below. |

**Item 4, the 6th family:** it is **`trips-tours` "Trips & Tours"** (`sort_order` 1, the *first* row). Its description is "Day trips, guided tours, packages, and sightseeing." The homepage already shows only 5 families (`home.ts` omits `trips-tours`), which is where the spec's "5" comes from.

- **No active or published flag on families.** `experience_families` has these columns only: `id, slug, name_en, name_ne, description, icon, cover_image_url, sort_order, created_at` (migration `20260821090000_experience_families.sql:5-15`). `categories` has no flag either (`0004_taxonomy.sql:30-39`). The only switch is at experience level: `experiences.status experience_status`, which defaults to `'draft'`. Anon RLS already returns only `published` rows (31 of 31 visible).
- **What should filter it:** its published-experience count. `trips-tours` owns 4 categories (day-trip, guided-tour, multi-day-tour, travel-package), and **0 published experiences** sit in them. The same applies to `meet-people` (0) and `give-back` (0). The real filter is "family has ≥1 published experience". It is derivable from existing data, so it needs no new flag.

---

## (a) Claims table

These are the claims the marketing homepage would need to make.

| # | Claim | Query run (anon) | Result | Verdict |
|---|---|---|---|---|
| 1 | "Experiences across Nepal" (non-zero catalogue) | `GET experiences?status=eq.published` count | 31 | TRUE |
| 2 | Listed experiences are bookable (have an upcoming date) | `experience_departures?status=eq.open&start_date=gte.2026-09-10` | 1 row, which belongs to the demo listing. 30 of 31 published experiences have **no** future departure. | FALSE |
| 3 | "Happening this week" | `experience_departures?status=eq.open&start_date=gte.2026-09-10&start_date=lte.2026-09-16` | 0 | FALSE |
| 4 | Current home rail "Happening This Week" reflects dates | code `webapp/src/lib/data/home.ts:141` | `rank(list).slice(0, 8)` sorts by rating and never looks at dates | FALSE |
| 5 | No past departure is presented as available | `experience_departures?status=eq.open&start_date=lt.2026-09-10` | **90** of 91 departures are `open` with dates 2026-08-14 … 2026-09-09. `/experience/everest-base-camp-trek` renders "10 spots available for Aug 14" / "Next departure Aug 14, 2026" / JOIN NOW. `create-booking-intent/index.ts:109-115` has no `start_date >= today` check. | FALSE |
| 6 | Star ratings / "N reviews" reflect real reviews | `GET reviews?select=*` | 401 `permission denied for table reviews` | **not readable by anon key**. See (b). |
| 7 | Review count on detail page matches reviews shown | SSR `/experience/everest-base-camp-trek` | Page shows "Reviews (124)" then "No reviews yet. Be the first to join!" JSON-LD emits `"aggregateRating":{"ratingValue":4.9,"reviewCount":124}` | FALSE (self-contradicting on the page) |
| 8 | "Local / verified hosts" | `experiences?select=host_id` | `host_id` is null on **30 of 31**. Only the demo listing has a host. | FALSE (no host attached to 30 listings) |
| 9 | Host verification status | `GET host_accounts` | 401 | **not readable by anon key** |
| 10 | "N travellers booked" / "trending" | `GET bookings` | 401. `/collection/trending` is `order rating_avg`, not booking data (`collection/[slug]/page.tsx:13,58-59`). | **not readable by anon key**. Existing "What travelers are booking right now" copy is FALSE. |
| 11 | "5 ways to experience Nepal" (families) | `GET experience_families` | 6 rows | FALSE (it is 6) |
| 12 | Every family has experiences | published experiences joined to category→family | adventure-together 23, live-like-a-local 6, mind-soul 2, **trips-tours 0, meet-people 0, give-back 0** | FALSE |
| 13 | "Curated Trips" (hero CTA → `/collection/trips-tours`) | SSR `/collection/trips-tours` | "0 experiences available / Nothing here yet" | FALSE |
| 14 | Category labels describe the experience | manual review of 31 title/summary vs category | 5 clear mismatches (see §2) | FALSE |
| 15 | Family naming is consistent | grep web + Flutter vs DB | Web is now "Mind & Soul" everywhere. Flutter has both (`collection_screen.dart:33` "Mind & Soul", `home_discovery.dart:58` "Soul & Mind"). | TRUE (web) / FALSE (Flutter, out of scope) |
| 16 | Transparent policies / Terms available | `GET legal_documents?select=slug,is_current` | `[]` (0 rows). `/legal` renders "No policies are published yet". All 13 `/legal/<slug>` return **404**. | FALSE |
| 17 | "Get the app" (live on stores) | grep repo for store URLs + `GET app_versions` | No App Store or Play listing URL. `app_versions` 0 rows. | UNVERIFIABLE (treat as absent) |
| 18 | Secure local payments (Khalti / eSewa) | `GET feature_flags` | `payment_khalti` and `payment_esewa` `enabled: true`, all platforms | TRUE (flag only, not tested end to end) |
| 19 | "Plan with AI" | `feature_flags.ai_itinerary` + web route | Flag `enabled: true`. No web route (`/ai-planner` 404). Link removed in P0. | FALSE on web |
| 20 | Photos are real Nepal imagery | `experiences.cover_image_url` host | 30 on project Supabase storage (origin not provable from the URL). Demo uses `images.unsplash.com` (stock). | UNVERIFIABLE (30) / FALSE (demo) |
| 21 | Booking contact must be a Nepal phone | `BookingForm.tsx:170-175`, `create-booking-intent/index.ts:66,72` | Label says "Nepali Phone Number". Only check is trimmed length 7–24. Any format is accepted. | FALSE (accepts non-Nepal formats) |
| 22 | Host commission is X% | grep code + DB | Not in code or DB. See (f). | UNVERIFIABLE |
| 23 | Price shown is the price paid | `BookingForm.tsx:56`, `create-booking-intent/index.ts:159` | A 5% fee is added on top at booking. Cards show the base `price_paisa`. | TRUE with caveat (fee disclosed only at checkout) |
| 24 | Home "points" badge meaningful | `(main)/page.tsx:40` | Literal text `0 pts`, rendered to everyone | FALSE (hardcoded) |

## (b) rating_count vs actual reviews

**No review rows are reachable with the anon key.** `GET /rest/v1/reviews` returns `401 permission denied for table reviews`, so none of the counts below can be backed by a row the marketing site can see.

Supporting evidence that the counts are not derived from reviews:

- The recompute trigger exists: `supabase/migrations/0010_reviews.sql:19-35` recomputes `rating_avg/rating_count` from `reviews`. It fires only when a review is inserted, updated or deleted.
- `supabase/seed.sql` sets `rating_avg, rating_count` directly in the experience inserts (e.g. lines 50, 70, 90) and contains **zero** `insert into reviews`.
- Anon is denied on `reviews`, so every detail page renders "Reviews (N)" above "No reviews yet". The JSON-LD also emits `aggregateRating`, which sends these counts to search engines.

Published experiences with `rating_count > 0` (30 of 31, sum = **2,683**):

| slug | rating_avg | rating_count |
|---|---|---|
| pokhara-paragliding | 4.9 | 215 |
| pokhara-peace-stupa-hike | 4.7 | 180 |
| nagarkot-sunrise-hike | 4.7 | 165 |
| panauti-community-homestay | 4.9 | 142 |
| bhaktapur-pottery-workshop | 4.9 | 130 |
| everest-base-camp-trek | 4.9 | 124 |
| tilicho-lake-annapurna-circuit | 4.9 | 115 |
| mardi-himal-trek | 4.8 | 112 |
| chitwan-jungle-safari | 4.8 | 110 |
| bhotekoshi-whitewater-rafting | 4.8 | 105 |
| annapurna-base-camp-trek | 4.8 | 98 |
| australian-camp-overnight | 4.8 | 93 |
| dhulikhel-namobuddha-hike | 4.8 | 91 |
| bandipur-cultural-walk | 4.7 | 88 |
| himalayan-sound-healing | 4.9 | 87 |
| ghandruk-homestay-experience | 4.9 | 84 |
| gokyo-lakes-trek | 4.9 | 79 |
| langtang-valley-trek | 4.7 | 76 |
| shivapuri-peak-hike | 4.6 | 75 |
| manaslu-circuit-trek | 4.9 | 67 |
| kakani-trout-strawberry | 4.7 | 63 |
| phulchowki-mountain-biking | 4.8 | 59 |
| upper-mustang-trek | 4.9 | 54 |
| helambu-circuit-trek | 4.7 | 51 |
| bardia-tiger-tracking | 4.9 | 45 |
| island-peak-climbing | 4.9 | 42 |
| rara-lake-wilderness-trek | 4.8 | 38 |
| mera-peak-climbing | 4.9 | 36 |
| everest-heli-tour | 5.0 | 31 |
| tiji-festival-mustang | 5.0 | 28 |

The only one with `rating_count = 0` is `demo-ram-mardi-himal-trek`.

Where these counts are rendered today: `ExperienceCard.tsx:82-83` (every card), `experience/[slug]/page.tsx:97-102` (JSON-LD), `:138-140` (stars), `:206` ("Reviews (N)"), plus sorting in `home.ts:92-97`, `collection/[slug]/page.tsx:59`, `search.ts:73`, `experiences.ts:56`.

## (c) Departures

| Measure | Count |
|---|---|
| Total `experience_departures` (anon-visible) | **91** |
| `status` values | `open`: 91 (nothing is ever closed) |
| Date range | 2026-08-14 … 2026-09-18 |
| `open` AND `start_date < today`, still offered | **90** |
| `open` AND `start_date >= today` | **1** |
| `open` AND within this week (≤ 2026-09-16) | **0** |

**The one live departure** belongs to experience `e1000000-0000-4000-8000-000000000001`, which is **`demo-ram-mardi-himal-trek`** ("Mardi Himal Trek"). It runs 2026-09-18 → 2026-09-22 with 2 of 8 spots left.

The only live departure on the platform belongs to the listing P0 #2 asks to unpublish. Once it is unpublished, **zero** experiences are bookable.

The other 30 experiences each have exactly 3 departures, all in the past, all still `open`.

## (d) Hardcoded taxonomy lists in the webapp, diffed against DB

DB source of truth: `experience_families` (6), `categories` (27, each with `family_id`), enum `difficulty_level`. Moods have no DB table.

**D1. `webapp/src/lib/data/home.ts:16-90` `homeSections`, the 5 home families with filter chips**

| slug | web title | DB name_en | web description | DB description |
|---|---|---|---|---|
| adventure-together | Adventure Together | Adventure Together ✓ | Group trips, shared adventures, new connections | Outdoor adventures made for sharing. ✗ |
| mind-soul | Mind & Soul (fixed in P0) | Mind & Soul ✓ | Wellness, reflection, healing and creativity | Wellness, reflection, healing, and creativity. ~ |
| meet-people | Meet People | Meet People ✓ | Connect, socialize, make new friends | Meetups, activities, events, and communities. ✗ |
| give-back | Give Back | Give Back ✓ | Help communities, share and contribute | Community, conservation, and meaningful impact. ✗ |
| live-like-a-local | Live Like a Local | Live Like a Local ✓ | Local life, traditions and authentic experiences | Food, homes, villages, culture, and crafts. ✗ |
| *(trips-tours)* | *missing* | Trips & Tours | — | — |

- **Filter category slugs used:** trekking, hiking, climbing, wildlife, yoga, meditation, creative-workshop, craft-workshop, meetup, community-event, group-activity, homestay, village-stay, skill-sharing, volunteer-project, conservation-project, volunteering, farm-experience, food-experience, culture. All 20 exist in DB.
- **Categories never reachable from home:** camping, wellness, wellness-retreat, day-trip, guided-tour, multi-day-tour, travel-package.
- **Filters that cross family boundaries**, so home sections do not follow `categories.family_id`:
  - Mind & Soul → "Creative Workshops" includes `craft-workshop` (DB: live-like-a-local).
  - Meet People → "Join an Activity" includes `creative-workshop` (mind-soul) and `craft-workshop` (live-like-a-local).
  - Meet People → "Local Connections" includes `homestay` and `village-stay` (live-like-a-local).
  - Live Like a Local → "Learn" includes `skill-sharing` (give-back).
- Chips also match on free-text `terms` (e.g. "rafting", "paragliding", "sound healing"). That is why Meet People renders on home even though the family has 0 experiences. The rail is filled by keyword hits from other families.

**D2. `webapp/src/app/(main)/collection/[slug]/page.tsx:11-30`: `COLLECTION_META` (9 entries) + `FAMILY_SLUGS` (6)**

- `FAMILY_SLUGS` = the 6 DB family slugs ✓.
- Family titles match DB after P0 ✓.
- Descriptions:
  - trips-tours, adventure-together, give-back and live-like-a-local match DB ✓.
  - mind-soul differs by one comma.
  - meet-people differs: "Connect, socialize, make new friends." vs DB "Meetups, activities, events, and communities." ✗
- Non-DB collections: `recommended`, `trending` (both rating sort) and `homestays`.
- Unknown slugs fall through to an unfiltered list: `/collection/nonexistent-slug` returns 200 with 30 experiences, not 404.

**D3. `webapp/src/lib/data/families.ts:15-25` `familyCompactSubtitle`.** Six slugs, all matching the DB. The subtitles have no DB column; they are a copy of `lib/widgets/experience_family_card.dart:86-88`.

**D4. `webapp/src/lib/data/taxonomy.ts:11-18` `experienceMoods`.**

- Relax→mind-soul
- Explore→trips-tours
- Learn→live-like-a-local
- Connect→meet-people
- Taste→live-like-a-local
- Help→give-back

There is no DB table. It is a copy of `lib/widgets/experience_mood_grid.dart`. All 4 referenced slugs exist, but **Explore, Connect and Help point to families with 0 experiences**.

**D5. `webapp/src/components/FilterPanel.tsx:18-21` difficulty.** `easy, moderate, challenging, strenuous` = enum `difficulty_level` ✓ (matches `database.types.ts:127`).

**D6. `webapp/src/lib/data/presentation.ts:5-7`.** Hardcodes `"adventure-together"` as the only family that shows difficulty. The rule lives in code, not the DB.

**D7. `webapp/src/components/Footer.tsx:6-20` `LEGAL_TITLES`.** Hardcodes 13 document titles. The DB `legal_documents` is empty for anon, so there is nothing to diff against yet.

Per rule 3, none of these were changed. There are 4 web copies (D1–D4) plus Flutter's own copies (RECON §4).

## (e) Internal links that 404 or render a stub

Method: I crawled SSR HTML from 13 seed pages, then fetched each target. I also grepped `href=` / `router.push` in `webapp/src`. Links on client-only surfaces (signed-in profile menu) come from static analysis.

| Target | Result | Linked from |
|---|---|---|
| `/legal/terms-of-service` and **all 12 other** `/legal/<slug>` | **404** (`legal_documents` empty for anon) | Footer on every page (`Footer.tsx:49-53`); `CookieConsent.tsx:61`; `BookingForm.tsx:194` (`/legal/payment-policy`); `experience/[slug]/page.tsx:254,262`; `booking/confirmation/[bookingId]/page.tsx:73,76`; `AcceptanceLine.tsx:18` |
| `/legal` | 200, **stub**: "No policies are published yet." | `legal/layout.tsx:17,28`; `host/application/page.tsx:126` |
| `/profile/my-reviews` | 404 | `profile/page.tsx:23` |
| `/profile/payment-methods` | 404 | `profile/page.tsx:24` |
| `/profile/notifications` | 404 | `profile/page.tsx:25` |
| `/profile/language` | 404 | `profile/page.tsx:26` |
| `/profile/help` | 404 | `profile/page.tsx:27` (still linked here; P0 removed only the footer link) |
| `/profile/settings` | 404 | `profile/page.tsx:28` |
| `/profile/edit` | 404 | `profile/page.tsx:98` |
| `/host/dashboard` | 404 | `host/page.tsx:48` |
| `/collection/trips-tours` | 200, **empty**: "0 experiences available" | home hero "Curated Trips" (`(main)/page.tsx:55`) |
| `/collection/meet-people`, `/collection/give-back` | 200, empty (0) | not linked directly; reachable via sitemap |
| `/search?family=trips-tours` (and give-back, meet-people) | 200, "0 experiences found" | `FamilyTile.tsx:12`, `MoodGrid.tsx:20` (Explore / Connect / Help moods), `HomeCategorySection.tsx:19` "See All" |
| `/host/status` | 200, thin. Defaults to "submitted" when no application exists (`host/status/page.tsx:12-13`). | `host/page.tsx:51`, `host/application/page.tsx:38,76` |
| `/ai-planner`, `/notifications` | 404. **No longer linked** (removed in P0). | — |
| Marketing IA: `/how-it-works`, `/about`, `/help`, `/safety`, `/for-hosts` | 404 (not built yet) | not linked |

**Sitemap** (`app/sitemap.ts`) advertises `/legal/*` (13 × 404) and `/collection/<category>` for all 27 categories. Many of those are empty or match nothing.

## (f) Commission and payout

| Where | What | Kind |
|---|---|---|
| `docs/REQUIREMENTS_DELTA.md:14-27` | Client doc: "PLAN E COMMISSION 10–15%", a **host-side deduction**. Flagged as wrong rate and wrong direction vs code. Rate "moves to `app_config`, per-category or per-host". | doc |
| `docs/ADMIN_PANEL_CONTEXT.md:1477-1498, 1549-1581, 1708-1733` | "Commission logic: NOT PRESENT". The only fee is a hardcoded 5% platform fee. Proposes `commission_config` / `host_accounts.commission_rate` (not built). | doc |
| `docs/HOST_SURFACE_AUDIT.md:134-152` | No `payouts` / `settlements` / `ledger` table. Commission direction undecided. | doc |
| `docs/FEATURES_BACKLOG.md:46`, `docs/TRD.md:219` | Host payout "out of v1 … manual, off-app". | doc |
| `supabase/legal/06-payment-policy.md:86-91` | Hosts are paid "net of the platform's commission". **No rate stated.** Payout timing is an unresolved placeholder `[PAYOUT TIMING — CONFIRM …]` (also in `supabase/legal/placeholders.json:18`). | legal doc (not published, see (e)) |
| **`supabase/functions/create-booking-intent/index.ts:159`** | `Math.round(subtotalPaisa * 0.05) // 5% platform fee`. Added **on top, to the traveller**. | **code** |
| **`webapp/src/components/BookingForm.tsx:56`** | Same `* 0.05` literal, client-side preview | **code** |
| DB | No commission or payout column or table. `app_config` has 0 rows for anon. | none |

**Verdict:**
- **Only a 5% traveller-side fee exists, and it is in code.** No host commission percentage exists in code or the DB.
- **The only host commission figure is a client range in a doc.** It is 10–15% and unresolved.
- **N10 `/for-hosts` must use a TODO marker.** Neither number can be stated as a host commission.

## (g) Proposed `SECTIONS.json`

```json
{
  "generated": "2026-09-10",
  "source": "AUDIT.md (N1)",
  "sections": [
    { "id": "hero", "node": "N3", "enabled": true, "data_source": "static", "omit_if_empty": false,
      "note": "Static copy + search are fine. Do NOT carry over the 'Curated Trips' CTA (/collection/trips-tours = 0 results) or the hardcoded '0 pts' badge." },
    { "id": "brand_proposition", "node": "N4", "enabled": true, "data_source": "static", "omit_if_empty": false },
    { "id": "families", "node": "N5", "enabled": true, "data_source": "experience_families JOIN categories JOIN experiences(status=published)", "omit_if_empty": true,
      "note": "DB has 6 families, not 5. Render only families with >=1 published experience: today 3 (adventure-together 23, live-like-a-local 6, mind-soul 2). trips-tours, meet-people, give-back = 0. Human decides whether '5' becomes 'data-driven N'." },
    { "id": "happening_this_week", "node": "N6", "enabled": false, "data_source": "experience_departures(status=open, start_date between today and today+6)", "omit_if_empty": true,
      "omit_reason": "0 open departures in 2026-09-10..2026-09-16. Only 1 future departure exists at all (2026-09-18, demo-ram-mardi-himal-trek, pending unpublish). Section must query dates, not rating rank as home.ts:141 does today." },
    { "id": "why_plan_e", "node": "N7", "enabled": false, "data_source": "static (each pillar must pass a data check)", "omit_if_empty": false,
      "omit_reason": "No approved pillar list yet. Of the likely pillars, 'verified local hosts' is FALSE (30/31 listings have no host), 'transparent policies' is FALSE (legal_documents empty, 13 legal 404s), 'real reviews' is not readable by anon key. Only 'local payments (Khalti/eSewa)' is TRUE. Re-enable once 4 pillars each map to a TRUE row in AUDIT (a)." },
    { "id": "app_showcase", "node": "N8", "enabled": false, "data_source": "store URLs", "omit_if_empty": true,
      "omit_reason": "No App Store / Play listing URL anywhere in repo; app_versions has 0 rows." },
    { "id": "host_cta", "node": "N9", "enabled": true, "data_source": "static", "omit_if_empty": false,
      "note": "Links to /host (200). Must not state a commission % — see AUDIT (f)." },
    { "id": "final_cta", "node": "N9", "enabled": true, "data_source": "static", "omit_if_empty": false,
      "note": "CTA target must not be 'Get the App' while app_showcase is omitted; use /explore." },

    { "id": "explore_by_feeling", "enabled": false, "omit_reason": "Deferred by spec. Moods have no DB table; 3 of 6 moods point at empty families." },
    { "id": "editorial_story", "enabled": false, "omit_reason": "Deferred by spec. No editorial content source." },
    { "id": "destinations_grid", "enabled": false, "omit_reason": "Deferred by spec. regions has 10 rows but no per-region availability check yet." },
    { "id": "meet_the_hosts", "enabled": false, "omit_reason": "Deferred by spec. host_accounts not readable by anon; 30/31 listings have null host_id." },
    { "id": "ai_planner", "enabled": false, "omit_reason": "Deferred by spec. No web route; ai_itinerary flag is on but web has nothing behind it." },
    { "id": "community_proof", "enabled": false, "omit_reason": "Deferred by spec. Reviews/bookings not readable by anon; rating_count values are not backed by visible review rows." }
  ]
}
```

---

## 1. Rendered claims that are live on production today

These are not new-build issues. They affect what planenepal.com currently serves.

1. Star ratings and "(N reviews)" on every card and detail page, plus `aggregateRating` in JSON-LD. The review rows behind them are not readable.
2. "Happening This Week" rail: a rating sort, not dates.
3. "10 spots available for Aug 14 … JOIN NOW" on past departures. The booking function does not reject past dates.
4. 13 legal links in the global footer that 404. The cookie banner links to a 404 too.
5. "Curated Trips" CTA leads to an empty collection.
6. Hardcoded "0 pts" badge.

## 2. Category vs content mismatches

Flagged only. **Humans decide the correct category.**

| slug | title | DB category (family) | Mismatch signal |
|---|---|---|---|
| everest-heli-tour | Everest Base Camp Helicopter Tour with Champagne Breakfast | wellness (Mind & Soul) | helicopter / scenic flight, not wellness |
| bhotekoshi-whitewater-rafting | Bhotekoshi Class III-IV White Water Rafting Adventure | camping (Adventure Together) | rafting, not camping |
| pokhara-paragliding | Pokhara Tandem Paragliding over Fewa Lake | hiking (Adventure Together) | paragliding, not hiking |
| phulchowki-mountain-biking | Phulchowki 2,760m Mountain Bike Singletrack Descent | hiking (Adventure Together) | mountain biking, not hiking |
| kakani-trout-strawberry | Kakani Hilltop Rainbow Trout & Organic Strawberry Tasting | homestay (Live Like a Local) | food tasting; `food-experience` exists |
| bhaktapur-pottery-workshop *(weak)* | Bhaktapur Living Heritage & Pottery Workshop | culture | `craft-workshop` exists and fits better |

There are no categories for rafting, paragliding or biking. The first four mismatches may mean the taxonomy is missing categories, not that the listings are wrong. Only 8 of 27 categories are used by any published experience.

## 3. Naming drift (all occurrences)

| Surface | File:line | Value |
|---|---|---|
| DB | `experience_families.name_en` (slug `mind-soul`); migration `20260821090000_experience_families.sql:23` | Mind & Soul |
| Web | `webapp/src/lib/data/home.ts:31` | Mind & Soul (was "Soul & Mind" before `8f7840f`) |
| Web | `webapp/src/app/(main)/collection/[slug]/page.tsx:17` | Mind & Soul (was "Soul & Mind" before `8f7840f`) |
| Flutter | `lib/models/experience_family.dart:91` | Mind & Soul |
| Flutter | `lib/features/search/collection_screen.dart:33` | Mind & Soul |
| Flutter | `lib/features/home/home_discovery.dart:58` | **Soul & Mind** (F1/F2 scope) |

Other drift found:
- Interest `climbing` is "Peak Climbing" while category `climbing` is "Climbing" (`0004_taxonomy.sql:46` vs `:70`).
- Interest `wellness` is "Yoga & Wellness" while category `wellness` is "Wellness".
- `interests` (10) and `categories` (27) are parallel lists with overlapping slugs.

## 4. Anon-visibility summary

| Table | Anon result |
|---|---|
| experiences | 31 (all published) |
| experience_families | 6 |
| categories | 27 |
| experience_departures | 91 |
| itinerary_items | readable |
| regions / interests / tags | 10 / 10 / 16 |
| experience_tags | 0 |
| legal_documents | **0** |
| app_versions / app_config | 0 / 0 |
| remote_content | 1 (`onboarding_slides`) |
| feature_flags | 3 (payment_khalti, payment_esewa, ai_itinerary; all enabled) |
| reviews, bookings, host_accounts, profiles, host_applications, payments | **not readable by anon key** (401) |

---

## 8. Proposed P0 list for GATE H1

A human must approve these. **None were done by N1.**

1. **Unpublish `demo-ram-mardi-himal-trek`.** It was requested; SQL is in `BLOCKED.md`. Side effect: zero bookable experiences remain.
2. **Close or remove the 90 past `open` departures, or add real future departures.** Otherwise nothing on the site is bookable and N6 stays omitted.
3. **Decide the fate of seeded `rating_avg/rating_count`.** Either reset to what `reviews` actually contains, or stop rendering them until real reviews exist. This also affects JSON-LD.
4. **Publish `legal_documents`**, or confirm the anon RLS policy. There are 13 global-footer 404s; see the `legal-docs-system` go-live notes.
5. **Past-date guard in booking.** Both the UI (`getExperienceExtras` has no date filter) and `create-booking-intent` need it. This is **booking code, so rule 6 applies: ask first.**
6. **Recategorise or add categories** for the 5 mismatches in §2.
7. **Populate or hide empty families** (trips-tours, meet-people, give-back). This also fixes the "Curated Trips" CTA.
8. **Decide host commission rate and direction.** Blocks `/for-hosts` terms.
9. **Remove the dead profile-menu links** (7 × 404) and `/host/dashboard`. This was not in the P0 request scope.

---

## 9. STALE-BOOKINGS (read-only diagnosis, 2026-09-11)

Node run after P0-VERIFY confirmed the past-departure guard live in production. Trigger: PLE-114405 and PLE-988971 (both created deliberately by P0-VERIFY's Test A/B, `create-booking-intent`) sat at `status: pending` well past their `quote_expires_at` with no automatic change. **No writes were made in this node. Nothing was cancelled, modified, or scheduled.**

### (a)-(d) Scale of the problem — cannot be measured from this environment

`bookings` has RLS restricting every row to `user_id = auth.uid()`; the anon key gets `401 permission denied for table bookings` (confirmed again this run), and `supabase migration list --linked` / any Management-API-backed DB access still 403s for this account (`unexpected login role status 403`, needs `SUPABASE_DB_PASSWORD` — still unset). That RLS is correct and desirable; it also means I have no way to see any booking except the two rows above, which belong to the test user I control. **I cannot report a-d for the whole platform without either `SUPABASE_DB_PASSWORD` or a service-role key, neither of which exists in this environment** (checked: no `supabase/functions/.env`, only the checked-in `.env.example` template with placeholder values).

What I can confirm, for the two rows I do have access to (via that user's own token):

| booking_ref | status | created_at | quote_expires_at | now (at last check) | past expiry by |
|---|---|---|---|---|---|
| PLE-114405 | pending | 2026-09-11T06:40:00.335Z | 2026-09-11T06:55:00.283Z | 2026-09-11T07:33:58Z | 38m 58s |
| PLE-988971 | pending | 2026-09-11T06:40:02.330Z | 2026-09-11T06:55:01.506Z | 2026-09-11T07:33:58Z | 38m 57s |

Both `updated_at` still equal `created_at` exactly — no process has touched either row since creation.

**To get the real platform-wide a-d, once DB access works, run:**

```sql
-- (a) total pending
select count(*) from public.bookings where status = 'pending';

-- (b) pending AND past quote_expires_at (exactly what expire_stale_pending_bookings() targets)
select count(*) from public.bookings
where status = 'pending' and quote_expires_at is not null and quote_expires_at < now();

-- (c) oldest such booking
select id, booking_ref, created_at, quote_expires_at
from public.bookings
where status = 'pending' and quote_expires_at is not null and quote_expires_at < now()
order by created_at asc limit 1;

-- (d) grouped by experience + departure, with the departure's own capacity for context
select b.experience_id, b.departure_id, d.start_date, d.total_spots, d.spots_left,
       count(*) filter (where b.status = 'pending' and b.quote_expires_at < now()) as expired_pending_count,
       sum(b.adults + b.children) filter (where b.status = 'pending' and b.quote_expires_at < now()) as guests_held
from public.bookings b
join public.experience_departures d on d.id = b.departure_id
group by b.experience_id, b.departure_id, d.start_date, d.total_spots, d.spots_left
having count(*) filter (where b.status = 'pending' and b.quote_expires_at < now()) > 0
order by expired_pending_count desc;
```

Given the two known rows already span two different experiences/departures created 30+ minutes ago from a single manual test run, and this repo's audit already found 90 past-dated departures that were `open` for weeks before P0-CRIT, it would not be surprising if real historical pending bookings exist too — but that is a guess, not a finding. The query above is the only way to know.

### (e) Does displayed availability count pending bookings as consumed seats? No.

Traced the full write path for `experience_departures.spots_left`:

| Where `spots_left` is written | What triggers it |
|---|---|
| `supabase/migrations/20260823080000_atomic_payment_finalization.sql:74` — `update ... set spots_left = spots_left - (adults + children) ... where spots_left >= (adults + children)`, inside `finalize_verified_payment()` | Called only from `payment-webhook/index.ts:271`, `verify-payment-return/index.ts:165`, and `admin-reverify-payment/index.ts:117` — i.e. only when a **payment is actually confirmed as paid**, moving the booking to `confirmed`. |
| Host-side capacity edits | `supabase/migrations/20260909160000_host_update_experience_availability.sql:99` and `20260909170000_host_save_experience_draft.sql:173` — host explicitly setting departure capacity, unrelated to bookings. |

`create-booking-intent/index.ts:111,129` only **reads** `spots_left` to validate there's room; it never decrements it. The same finalize function (line 65-66) also independently refuses to confirm a booking whose `quote_expires_at <= now()`, so an expired pending booking cannot silently become a paid one later even without the cron.

The webapp displays this same raw column, unchanged: `webapp/src/components/BookingForm.tsx:58,154` and `webapp/src/app/(main)/experience/[slug]/page.tsx:47,59,67` all read `departure.spots_left` directly.

**Conclusion: a pending or expired-but-unflagged booking does not hold a seat.** `spots_left` only ever drops when a payment is confirmed. The stale rows are a data-hygiene and (if a host or admin console ever sums pending totals) a possible-reporting-accuracy problem, not an overselling/availability problem.

## 10. Whether the cron ever ran

**Defined nowhere.** Checked every mechanism named in the task:

| Mechanism | Result |
|---|---|
| `pg_cron` extension / `cron.schedule(...)` | No match anywhere in `supabase/migrations/` |
| Supabase scheduled-function config | Not exposed by this config.toml version; `[functions.expire-stale-bookings-cron]` only sets `verify_jwt = false` — no schedule |
| GitHub Actions workflow | This branch has `db.yml`, `flutter.yml`, `web.yml` (pre-existing) and, on `infra/pipeline` (unmerged), `gates.yml`/`deploy.yml`/`agent.yml` — none reference `expire-stale-bookings` or cron |
| Cloudflare Cron Trigger | No `crons`/`triggers` block in `webapp/wrangler.jsonc` |

The function's own source says so directly, `supabase/functions/expire-stale-bookings-cron/index.ts:19-22`: "Wiring the actual scheduler (pg_cron / GitHub Actions cron / Cloudflare cron) that POSTs here on an interval is ops, same as `complete-trips-cron` today."

`complete-trips-cron` (the sibling job that flips completed trips) is in the exact same unwired state — this isn't unique to booking expiry.

**Function's own logic** (`supabase/functions/expire-stale-bookings-cron/index.ts`):
- Requires `POST` + a matching `X-Cron-Secret` header (constant-time compare against `EXPIRE_STALE_BOOKINGS_CRON_SECRET`), else `401`.
- On success, calls RPC `expire_stale_pending_bookings()` with the service-role key and returns its count.

**The RPC itself** (`supabase/migrations/20260910160000_ops_console_schema.sql:317-335`):

```sql
create or replace function public.expire_stale_pending_bookings()
returns integer
language plpgsql security definer set search_path = ''
as $$
declare v_count integer;
begin
  with expired as (
    update public.bookings
      set status = 'expired'::public.booking_status, updated_at = now()
    where status = 'pending'::public.booking_status
      and quote_expires_at is not null
      and quote_expires_at < now()
    returning 1
  )
  select count(*) into v_count from expired;
  return v_count;
end;
$$;
revoke execute on function public.expire_stale_pending_bookings()
  from public, anon, authenticated;
```

Selects exactly `status='pending' AND quote_expires_at < now()`, sets `status='expired', updated_at=now()`. It does not touch `spots_left` (consistent with §9(e) — expiry was never meant to free seats, because pending bookings never held any). `EXECUTE` is revoked from every client-facing role; only the service-role-authenticated Edge Function can call it, which is correct, and also means it genuinely cannot run unless something invokes that function with the right secret.

PLE-114405 and PLE-988971 match this `WHERE` clause exactly right now — they are precisely the rows this function would flip to `expired` the moment it is ever called. Per instruction, I have not called it.

## 11. Migration state — unavailable

`supabase migration list --linked`:
```
Initialising login role...
unexpected login role status 403: {"message":"Your account does not have the necessary privileges..."}
Connect to your database by setting the env var correctly: SUPABASE_DB_PASSWORD
```
Same permission gap as `functions list` earlier in this session. `SUPABASE_DB_PASSWORD` is not set in this environment. No diff against `main`'s migrations could be produced. Nothing was applied.
