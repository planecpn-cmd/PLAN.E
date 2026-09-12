# RECON.md — N0 (read-only)

Generated 2026-09-10 on branch `admin-panel/p0-test-harness` @ `7306fc3`. No source files written.

**Stack correction to the spec:** the "React web app" is **Next.js 16.3.4 (App Router, React 19, Tailwind v4)** in `webapp/`, deployed to Cloudflare Workers via OpenNext. Per `webapp/AGENTS.md`, this Next version has breaking changes — read `webapp/node_modules/next/dist/docs/` before writing code. Flutter app is at repo root (`lib/`). Supabase project ref `dtebgbrqynxahuzmbtbc`.

**Access limits hit:** `supabase db query --linked` returned 403 (account lacks Management API privilege; no `SUPABASE_DB_PASSWORD`). Row counts below are taken via the **anon key over PostgREST** — i.e. exactly what the public marketing site can see under RLS. Tables marked `RLS-denied` need a privileged query (service role or DB password) in N1.

The spec file `plan-e-marketing-agent-graph.md` is not in the repo. Recommend committing it at root so every node can cite it.

---

## 1. Web routes (`webapp/src/app`)

| Route | File | State |
|---|---|---|
| `/` | `(main)/page.tsx` | Real page. Hero + "Happening This Week" rail + 5 family sections. See issues §6. |
| `/explore` | `(main)/explore/page.tsx` | Real |
| `/search` | `(main)/search/page.tsx` (+ `loading.tsx`) | Real |
| `/map` | `(main)/map/page.tsx` | Real (Leaflet) |
| `/experience/[slug]` | `(main)/experience/[slug]/page.tsx` | Real |
| `/booking/[slug]` | `(main)/booking/[slug]/page.tsx` | Real — **booking code, do not touch without asking** |
| `/booking/confirmation/[bookingId]` | `(main)/booking/confirmation/[bookingId]/page.tsx` | Real — booking |
| `/collection/[slug]` | `(main)/collection/[slug]/page.tsx` | Real; any slug renders (unknown slug → unfiltered published list, no 404) |
| `/plans` | `(main)/plans/page.tsx` | Real (auth) |
| `/saved` | `(main)/saved/page.tsx` | Real (auth) |
| `/profile` | `(main)/profile/page.tsx` | Real (auth) |
| `/host` | `(main)/host/page.tsx` | Real (host landing) |
| `/host/application` | `(main)/host/application/page.tsx` | Real |
| `/host/status` | `(main)/host/status/page.tsx` | Thin (14 lines); defaults status to `submitted` when no row exists |
| `/welcome` | `welcome/page.tsx` | Real |
| `/auth/{login,sign-up,forgot-password,otp-verify,required,set-new-password}` | `auth/*` | Real — **auth, do not touch without asking** |
| `/legal`, `/legal/[slug]` | `legal/*` | Real (13 docs) |
| `robots.txt`, `sitemap.xml` | `robots.ts`, `sitemap.ts` | Real |

**Linked but not registered on web (will 404):**

| Link target | Linked from |
|---|---|
| `/ai-planner` ("Plan with AI") | `(main)/page.tsx:60` hero button |
| `/notifications` | `components/Nav.tsx:68`, `:86` (shown even when signed out) |
| `/profile/help` ("Help") | `components/Footer.tsx:39` |

Marketing IA routes that do not exist yet: `/how-it-works`, `/for-hosts` (closest: `/host`), `/about`, `/help`, `/safety`, "Why PLAN E".

Middleware: `webapp/src/proxy.ts`.

## 2. Component inventory (reusable)

`components/ui/`: `Button`, `Card`, `ChipPill`, `ContentRail`, `CounterField`, `EmptyState`, `ErrorState`, `ExperienceCard` (poster/horizontal), `FamilyTile`, `GoogleMark`, `Icon`, `Logo`, `MoodGrid`, `OrnamentDivider`, `ProgressSteps`, `RatingStars`, `SectionHeader`, `Skeleton`, `TextField`.

`components/`: `Nav` (`TopNav` desktop ≥lg, `BottomNav` mobile), `Footer` (desktop only — `hidden lg:block`), `HomeCategorySection`, `SearchBar`, `SearchQueryInput`, `FilterPanel`, `MobileFiltersSheet`, `MapView`, `BookingForm`, `BookmarkButton`, `AuthSplitLayout`, `cookie/*`, `legal/*`.

Data layer (`lib/data/`): `home.ts` (`getHomeData`), `families.ts`, `experiences.ts`, `presentation.ts`, `search.ts`, `taxonomy.ts`, `legal.ts`. Supabase clients: `lib/supabase/{server,client}.ts`, generated types `lib/supabase/database.types.ts`.

Tooling present: `tsc`, `eslint` (`npm run lint`), `next build`. **No unit test runner installed in `webapp/`** (no vitest/jest) — N2's unit-test gate needs one added (or `node --test`).

## 3. Supabase

75 migrations in `supabase/migrations/`. Relevant tables and anon-visible row counts (2026-09-10):

| Table | Anon count | Notes |
|---|---|---|
| `experiences` | 31 (all `published`) | 30 of 31 have `rating_count > 0` |
| `experience_families` | 6 | see taxonomy below |
| `categories` | 27 | each has `family_id` |
| `tags` / `experience_tags` | 16 / 0 | tags unused |
| `regions` | 10 | |
| `interests` | 10 | |
| `experience_departures` | 91 | **only 1** with `status=open AND start_date >= 2026-09-10` |
| `reviews` | RLS-denied | N1 must count with privileged role |
| `bookings`, `host_accounts`, `profiles` | RLS-denied | |
| `app_versions` | 0 | no store-release rows |
| `app_config` | 0 | |
| `remote_content` | 1 | |
| moods | — | **no table**; hardcoded in both clients |
| hosts public profile | — | no public host table readable by anon |
| availability | = `experience_departures` (`start_date`, `status`) | |

Taxonomy in DB (`experience_families`, `sort_order`): `trips-tours` Trips & Tours · `adventure-together` Adventure Together · `live-like-a-local` Live Like a Local · `mind-soul` **Mind & Soul** · `meet-people` Meet People · `give-back` Give Back. **Six families, spec says five.**

Categories (27): trekking, hiking, camping, climbing, wildlife (adventure-together); homestay, culture, food-experience, village-stay, farm-experience, craft-workshop (live-like-a-local); wellness, yoga, meditation, wellness-retreat, creative-workshop (mind-soul); volunteering, volunteer-project, conservation-project, skill-sharing (give-back); day-trip, guided-tour, multi-day-tour, travel-package (trips-tours); meetup, group-activity, community-event (meet-people).

Rating mechanics: `0010_reviews.sql:19-35` trigger recomputes `experiences.rating_avg/rating_count` from `reviews` — but only on review insert/update/delete. `supabase/seed.sql` writes `rating_avg, rating_count` directly (e.g. lines 50/70/90) and contains **zero** `insert into reviews`. Strong signal that the displayed counts (e.g. `pokhara-paragliding` 215) are seed values, not real reviews. N1 must confirm with a privileged `count(*)` per experience.

Also: published listing `demo-ram-mardi-himal-trek` (slug says demo) is live.

Full schema reference: `supabase/full_schema_bundle.sql`, `supabase/dumps/schema_public.sql`.

## 4. Flutter taxonomy definitions (read-only)

| What | Where | Kind |
|---|---|---|
| Families (fallback list incl. `nameEn: 'Mind & Soul'`) | `lib/models/experience_family.dart:69-91` | hardcoded const |
| Category→family map | `lib/models/experience_family.dart:125-140+` | hardcoded map (duplicates DB `categories.family_id`) |
| Family label switch (`'Mind & Soul'`) | `lib/features/search/collection_screen.dart:30-91` | hardcoded switch |
| Home rails (`'Soul & Mind'`) | `lib/features/home/home_discovery.dart:30-126` | hardcoded |
| Home rail rules | `lib/models/home_rail_rule.dart:27,41` | hardcoded |
| Family subtitles | `lib/widgets/experience_family_card.dart:86-88` | hardcoded |
| Moods | `lib/widgets/experience_mood_grid.dart` | hardcoded (no DB table) |
| Presentation rules | `lib/core/experience_presentation.dart` | hardcoded slug checks |

Flutter router (`lib/router.dart`) uses `/experience/:id` and `/booking/:id`; web uses `/experience/[slug]` and `/booking/[slug]` — deep-link param mismatch for F1.

## 5. Web taxonomy copies (rule 3 — log, do not add another)

| Copy | Where | Label used |
|---|---|---|
| Home sections + filters | `webapp/src/lib/data/home.ts:16-90` | **"Soul & Mind"** |
| Collection titles + family slug set | `webapp/src/app/(main)/collection/[slug]/page.tsx:11-30` | **"Soul & Mind"** |
| Family subtitles | `webapp/src/lib/data/families.ts:15-25` | — |
| Moods | `webapp/src/lib/data/taxonomy.ts` | — |

DB says "Mind & Soul"; web home + collection say "Soul & Mind"; Flutter says both. Full occurrence list is N1's job.

## 6. Design tokens

`webapp/src/design/tokens.ts` mirrored into `webapp/src/app/globals.css` `:root` + `@theme`; both transcribed from `lib/theme/tokens.dart`.

| Token | Spec | Web | Flutter | Match |
|---|---|---|---|---|
| forest (primary) | `#18372D` | `#18372D` | `0xFF18372D` | ✓ |
| deep | `#01251C` | `#01251C` | `0xFF01251C` | ✓ |
| sage | `#E7ECE7` | `#E7ECE7` | `0xFFE7ECE7` | ✓ |
| ink | `#24312D` | `#24312D` | `0xFF24312D` | ✓ |
| muted gold | `#8F5E1B` | `#8F5E1B` | `0xFF8F5E1B` | ✓ |

Also defined: `ivory` = `#FFFFFF` (named ivory but pure white), status colors, borders, card/skeleton. Spacing 4/8/12/16/20/24/32/40. Radii 8/16/24/pill. Type: Playfair Display (display) + Inter (body), 32/28/24/20/16/14/12. Breakpoints 768/1024/1440. **No token mismatches.** N2 can reuse these files rather than create a new token file.

## 7. Homepage issues spotted during recon (input to N1, not fixed)

- `lib/data/home.ts:141` — "Happening This Week" is `rank(list).slice(0, 8)`: top-rated experiences, **no date filter at all**. Mislabelled section.
- `(main)/page.tsx:40` — hardcoded "0 pts" badge.
- `(main)/page.tsx:60` — "Plan with AI" → `/ai-planner` 404.
- `/collection/recommended` and `/trending` both = rating sort; "What travelers are booking right now" copy has no booking query behind it (`collection/[slug]/page.tsx:13`).
- `ExperienceCard` shows `RatingStars` whenever `ratingCount > 0` — i.e. seed counts are rendered as real reviews site-wide.
- Store links: no App Store / Play Store listing URL anywhere in repo (only a `play.google.com/...?id=$packageName` update intent in `lib/core/native_intents.dart:26`); `app_versions` has 0 rows. N8 app showcase would be omitted.
- Commission terms: mentioned in `docs/REQUIREMENTS_DELTA.md`, `docs/HOST_SURFACE_AUDIT.md`, `docs/H1_HOST_WRITE_PATH.md`, `docs/ADMIN_PANEL_CONTEXT.md`, `supabase/legal/06-payment-policy.md` — N10 should source the number from there, not invent one.
