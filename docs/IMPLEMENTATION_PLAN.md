# PLAN E — Complete Implementation Plan

Version 3.0 · 3 August 2026 · **Flutter / Dart** · For an autonomous AI coding agent (Antigravity)
Companion docs: App Flow Document v1.0, UI/UX Design Report v1.0, TRD.md v2.0, BACKEND_SCHEMA.md,
FEATURES_BACKLOG.md, ISOLATION.md.

> **v3.0 change:** rebuilt for Flutter. A React Native skeleton was built and audited first; it is
> deleted in Phase S-1. The SQL migrations and all product documents survive the switch unchanged.
> Verification rules are stricter than v2 because the v2 run marked three phases DONE on unverified
> criteria.

---

## 0. How to read this plan

| Stage | Phases | Goal |
|---|---|---|
| **STAGE A — Skeleton** | S-1 – S4 | Every screen exists, navigates, and renders real data from a real database. Nothing is transactional. **This is what we build now.** |
| **STAGE B — Transactional** | 5 – 9 | Money, chat, reviews. The app becomes real. |
| **STAGE C — Production** | 10 – 12 | Host live, localization, accessibility, release. |

**Build Stage A only. Stop after S4 and wait for review.** Stages B and C are written out so the
agent does not architect itself into a corner — not so it builds them early.

### The verification rule (this is the one that was broken last time)

A phase is **DONE** only when every one of its Exit criteria has been verified by running something
and pasting the real output. If a criterion cannot be verified — no database, no device, no
credentials — the phase is marked **BLOCKED**, not DONE, and the agent says exactly what it needs.

`dart analyze` and `flutter test` passing is **not** evidence that the app runs, that a migration
applies, or that a screen shows data. Those need `flutter run` and `supabase db reset`.

### Non-negotiables in every phase

1. One phase at a time. Never start N+1 before N's exit checks pass with real output.
2. Each phase ends: `dart analyze --fatal-infos` clean, `flutter test` green, app runs on a device,
   one commit `feat(phase-N): <summary>`, `docs/PROGRESS.md` updated.
3. Missing detail? Authority: App Flow → UI/UX Report → TRD → Backend Schema → agent judgement.
   Log it in `docs/OPEN_QUESTIONS.md`, pick the smallest default, mark `// ASSUMPTION:` in code,
   continue. Never stall.
4. Every screen file opens with `// PL-XX <Screen Name>` or `// RM-XX <Screen Name>`, and lives at
   `lib/features/<area>/<name>_screen.dart`.
5. Never invent a screen absent from the App Flow inventory.
6. Layering: **widget → provider → repository → Supabase.** A widget never touches
   `Supabase.instance` directly.
7. No secrets committed. Service-role key never in the app.

---

# STAGE A — THE SKELETON

Definition: you can install the app, pass onboarding, browse real Nepal experiences from a real
database, reach all 34 screens through normal navigation, and see correct loading / empty / error
states. Booking stops at a "coming soon" wall. No payment, no chat, no reviews, no host submission.

---

## Phase S-1 — Remove the React Native scaffold

A React Native skeleton exists in this repo from a previous decision. It is dead. Delete it — do
not port it, do not consult it.

**Build**
```bash
git rm -r --cached node_modules 2>/dev/null; true
rm -rf app/ src/ node_modules/ package.json package-lock.json tsconfig.json \
       babel.config.js eslint.config.js .prettierrc app.json .env.example
git add -A && git commit -m "chore: remove React Native scaffold, switching to Flutter"
```

**Keep, untouched:** `supabase/` (1012 lines of migrations — the real asset), `docs/`, `.git/`.

**Exit:** `git status` clean · `supabase/migrations/` still holds 15 files · `docs/` intact ·
no `.tsx`, `.ts`, or `package.json` anywhere in the tree (`find . -name "*.tsx" | wc -l` → 0).

---

## Phase S0 — Flutter project, tooling, route skeleton

**Build**

- `flutter create --org com.plane --platforms=android,ios .` inside the existing repo.
- `pubspec.yaml` dependencies: `flutter_riverpod`, `go_router`, `supabase_flutter`,
  `cached_network_image`, `intl`, `timezone`, `shared_preferences`, `flutter_localizations`.
  Dev: `flutter_lints`, `mocktail`, `integration_test`.
- `analysis_options.yaml` with `flutter_lints` plus `strict-casts`, `strict-raw-types`, and
  `dart analyze --fatal-infos` wired into a `Makefile`/script.
- `.gitignore` covering `env/*.json`, `build/`, `.dart_tool/`, `*.jks`, `google-services.json`.
- `env/local.json.example` with `SUPABASE_URL`, `SUPABASE_ANON_KEY`.
- `lib/router.dart` — **the full route tree as placeholder screens**, one file per App Flow ID,
  each rendering its own ID and name. This is the most valuable thing in S0: the whole app becomes
  navigable on day one.

```
lib/features/
  onboarding/ splash_screen.dart              PL-01
              onboarding_slide_screen.dart    PL-02..04  (one widget, index param)
              interests_screen.dart           PL-05
  auth/       sign_up_screen.dart             RM-01
              login_screen.dart               RM-02
              forgot_password_screen.dart     RM-03
              reset_result_screen.dart        RM-04
              auth_required_sheet.dart        RM-05
  home/       home_screen.dart                PL-06
  explore/    explore_screen.dart             PL-07
              map_screen.dart                 RM-08
  search/     search_results_screen.dart      PL-08
              collection_screen.dart          RM-06
              filter_sheet.dart               RM-07
  experience/ experience_detail_screen.dart   PL-09
  booking/    booking_screen.dart             PL-10
              confirmation_screen.dart        PL-11
  saved/      saved_screen.dart               PL-12
  plans/      plans_screen.dart               PL-13 / PL-14 (tabs)
              itinerary_screen.dart           RM-10
              trip_chat_screen.dart           RM-11
              gear_checklist_screen.dart      RM-12
              budget_tracker_screen.dart      RM-13
              delete_draft_dialog.dart        RM-25
  trips/      trips_screen.dart               PL-15 / PL-16 (tabs)
              leave_review_screen.dart        RM-14
              review_submitted_screen.dart    RM-15
  profile/    profile_screen.dart             PL-17
              edit_profile_screen.dart        RM-16
              payment_methods_screen.dart     RM-17
              notifications_screen.dart       RM-18
              language_region_screen.dart     RM-19
              help_support_screen.dart        RM-20
              more_settings_screen.dart       RM-21
              my_reviews_screen.dart          RM-27
              logout_dialog.dart              RM-26
  host/       become_host_screen.dart         PL-18
              host_step_1_screen.dart         RM-22
              host_step_2_screen.dart         PL-19
              host_step_3_screen.dart         RM-23
              host_step_4_screen.dart         RM-24
              application_submitted_screen.dart PL-20
  dev/        routes_screen.dart              dev index listing all 34 IDs
```

- `ShellRoute` for the 5-item bottom navigation (Home, Explore, My Plans, My Trips, Profile).

**Exit — paste output for each**
- `dart analyze --fatal-infos` → 0 issues
- `flutter test` → passes (even if trivial at this point)
- **`flutter run` on a real device or emulator** → app launches, bottom nav switches all 5
  destinations, `/dev/routes` lists all 34 IDs and each one opens. Paste the run log and describe
  what you saw. If no device is available: **BLOCKED**, say so.

---

## Phase S1 — Design system

**Build**

- `lib/theme/tokens.dart` — colors from UI/UX Report §5.2: `forest #18372D`, `deep #01251C`,
  `ivory #F6F2E9`, `sage #E7ECE7`, `ink #24312D`, and **`gold #8F5E1B`** (the report's `#B7802B`
  fails WCAG AA on ivory; the corrected value measures 5.07:1 — record this in `PROGRESS.md`).
  Spacing 4/8/12/16/20/24/32/40. Radii 8/16/24/pill. Elevation levels.
- `lib/theme/typography.dart` — serif display family for the wordmark, headings and destination
  titles; sans for body, labels, buttons. Display 32/28, heading 24/20, body 16/14, caption 12.
  Line heights ≥1.4. Bundle the fonts in `pubspec.yaml`; do not rely on system defaults.
- `lib/theme/app_theme.dart` — a single `ThemeData` assembled from tokens. **Every widget reads
  colors from `Theme.of(context)` or `tokens.dart`. A raw `Color(0xFF…)` outside `theme/` is a
  lint failure**, enforced by a custom `dart analyze` exclusion check in the graph audit.
- Primitives in `lib/widgets/`:
  `AppScaffold`, `AppButton` (primary/secondary/text/disabled), `AppCard`, `ExperienceCard`,
  `FilterChipPill` (active state uses fill **and** a check icon — never colour alone),
  `AppTabs`, `AppTextField`, `CounterField`, `RatingStars`, `SectionHeader`, `ContentRail`,
  `AppSkeleton`, `EmptyStateView`, `ErrorStateView`, `AppToast`, `PriceBottomBar`, `ProgressSteps`.
- **`AsyncValueView<T>`** — a shared widget taking a Riverpod `AsyncValue` plus an `emptyWhen`
  predicate, rendering skeleton / data / empty / error+retry. Every list screen uses it. This makes
  the App Flow's three-state requirement structural instead of a checklist item that gets skipped.
- `lib/features/dev/components_screen.dart` — a gallery rendering every primitive in every state.

**Rules:** every tap target ≥48 dp (`kMinInteractiveDimension`). Selected state communicated by
more than colour. No literal user-facing strings — ARB keys from now on.

**Exit:** `dart analyze` clean · `flutter run` → `/dev/components` renders every primitive in every
state, screenshot or description pasted · contrast of gold-on-ivory computed and shown.

---

## Phase S2 — Database, actually applied

**This phase was faked in the previous run. The SQL existed and had never touched a database.**

**Build**

- `supabase init`, `supabase start` (Docker), then apply `supabase/migrations/0001`–`0015`
  exactly as ordered in BACKEND_SCHEMA.md §7. Fix whatever breaks — a thousand lines of unrun SQL
  always has errors. Every fix is a commit.
- Seed ~30 real Nepal experiences with real photos, integer-paisa prices, real regions and
  difficulties (Everest Base Camp, Annapurna Base Camp, Poon Hill, Langtang, Mardi Himal, Manaslu
  Circuit, Shivapuri, Nagarkot, Chitwan, Rara Lake, Ghandruk homestay, Bandipur, Pokhara
  paragliding, Lumbini, Bhaktapur pottery …). Never demo this app with lorem ipsum.
- Rewrite `supabase/tests/rls.test.sql` so that it **can fail**. The current file only prints
  booleans. Every assertion must be:
  ```sql
  do $$ begin
    if not ( <condition> ) then
      raise exception 'FAIL: <what broke>';
    end if;
  end $$;
  ```
  Required assertions:
  1. every table in `public` has `rowsecurity = true` and ≥1 policy
  2. `anon` can select published experiences
  3. `anon` selects zero rows from `bookings` and `payments`
  4. user A selects zero of user B's bookings
  5. an authenticated role **cannot** update `bookings.status`
  6. an authenticated role **cannot** update `experience_departures.spots_left`
  7. an authenticated role **cannot** insert or update `payments`
  8. an authenticated role **cannot** update `host_applications.status`
  9. `reviews` rejects a second row for the same `booking_id`
  10. `payments` rejects a duplicate `idempotency_key`
- Generate Dart models from the schema (`freezed` + `json_serializable`, or hand-written — but they
  must match the migrations exactly).

**Exit — paste output for each**
- `supabase db reset` completes from zero with no error
- `psql -f supabase/tests/rls.test.sql` → runs, all 10 assertions pass
- deliberately break one policy, re-run, show the test **failing**, then restore it. A test that has
  never been seen to fail is not known to work.
- `select count(*) from experiences where status='published'` → ~30

**This test file is permanent. Never delete it, only extend it.**

---

## Phase S3 — Data layer

**Build**

- `lib/core/supabase_client.dart` — initialised from `--dart-define`, session persisted, refresh
  on resume.
- `lib/core/format.dart`:
  - `formatNpr(int paisa)` → `Rs. 12,50,000` (Nepali lakh grouping — `intl`'s default grouping is
    wrong, write it by hand)
  - `toKathmandu(DateTime)` / `formatTripDate` via the `timezone` package with `Asia/Kathmandu`.
    Never a hardcoded +05:45, never `toLocal()`.
  - `isNepaliPhone(String)` → `^(\+977)?9[678]\d{8}$`
  - `formatDuration(int hours)` → hours under 24, days at or above
- `lib/models/` — data classes for every table the app reads.
- `lib/repositories/` — `ExperienceRepository`, `BookingRepository`, `ProfileRepository`,
  `SavedRepository`, `TaxonomyRepository`. All Supabase calls live here and nowhere else.
- `lib/providers/` — Riverpod providers exposing `AsyncValue`:
  `experiencesProvider(filters)`, `experienceProvider(id)`, `homeRailsProvider`,
  `categoriesProvider`, `regionsProvider`, `savedProvider`, `bookingsProvider(status)`,
  `profileProvider`; plus `sessionProvider`, `guestProvider`, `deferredActionProvider`
  (`StateNotifier`s).

**Exit:** `flutter test` green, covering — lakh formatting (`Rs. 500`, `Rs. 1,00,000`,
`Rs. 12,50,000`, `Rs. 1,00,00,000`), Kathmandu conversion across a UTC-midnight boundary,
phone accept/reject cases, duration formatting · plus **one live-data test**: a script or widget
test that fetches from the running local Supabase and prints a real seeded experience title. If
that returns nothing, the data layer is not done.

---

## Phase S4 — Skeleton screens with real data

Every screen gets its real layout and real data. Nothing writes money.
**A screen is not done until it is built on tokens, uses `AsyncValueView`, and has been seen
running.** Last time 21 of 45 files used the design system and 9 of 45 fetched data, and the phase
was still marked DONE. Do not repeat that.

**S4.1 Entry (PL-01 – PL-05, RM-01 – RM-05)**
Splash with the NEPAL→PLAN E transition and a reduced-motion path · 3 onboarding slides with page
dots and the three entry actions · **real Supabase Auth** on Sign Up / Login / Forgot Password /
Reset Result (email+password and phone OTP — a button that routes to Home is not a login) ·
guest session · Select Interests reading `interests` from the DB, minimum-3 rule, Continue disabled
below three, selection persisted · RM-05 sheet writing and replaying the deferred action per TRD §5.

**S4.2 Discovery (PL-06, PL-07, PL-08, RM-06, RM-07)**
Home: hero + rails (Recommended for You, Trending Treks, Homestays Near You, Community and
Volunteering) personalised by the user's stored interests · Explore: search field, activity chips,
category grid, Popular Regions, Map FAB · Search Results with filter and sort · Collection /
See All · Filter & Sort bottom sheet. Search runs as a client-side `tsvector` query for now; the
Edge Function lands in Phase 5 and the query shape does not change.

**S4.3 Detail and saving (PL-09, PL-12, RM-08)**
Experience Details in the exact section order of App Flow §5.7 — cover, spots-left, title/location/
rating/date, duration/difficulty/group size, trip overview, price, what's included, what to bring,
meeting point + map, participants, things to know, reviews, organizer, `PriceBottomBar` with Join.
Share via deep link (`go_router` path). View on Map with a permission-denied fallback to the text
meeting point. Optimistic heart save with rollback. Saved: two-column grid, All/Treks/Stays/
Available filters.

**S4.4 Booking form, walled (PL-10)**
Full form — departure date from `experience_departures`, Adults/Children counters, add-ons, Full
Name + Phone with validation, live price breakdown from real DB prices in integer paisa. Proceed to
Payment opens a **"Payments coming soon"** sheet and creates nothing. Mark the pricing
`// TEMP: client pricing, server re-price lands in Phase 7`.

**S4.5 Plans, Trips, Profile (PL-13 – PL-17, RM-10 – RM-13, RM-16 – RM-21, RM-25 – RM-27)**
My Plans with Upcoming/Drafts tabs on real bookings (empty is the correct state — show the empty
state) · My Trips with Completed/Cancelled · Itinerary reading `itinerary_items` for real ·
Chat, Gear, Budget as laid-out screens with a "coming soon" body · Profile with real counters from
the DB, avatar, Edit Profile, every settings destination reachable as a titled screen · logout and
delete-draft dialogs.

**S4.6 Host shell (PL-18 – PL-20, RM-22 – RM-24)**
Become a Host built fully (hero, benefits, 4-step how-it-works, testimonial, CTA) · the 4-step
application with `ProgressSteps` and Back/Next; step 2 exactly as wireframed, steps 1/3/4 to their
stated purpose with `// ASSUMPTION:` markers · Submit writes a `draft` row only · Application
Submitted status tracker.

**Exit for Stage A — every line needs evidence**
- All 34 App Flow IDs implemented and reached through **normal navigation**, not just `/dev/routes`
- Zero raw `Color(0xFF…)` outside `lib/theme/` (paste the grep count)
- Every list and detail screen uses `AsyncValueView`; verify empty and error by stopping the local
  Supabase mid-session and showing what renders
- Home rails reflect the interests chosen in onboarding
- A guest tapping Save is gated by RM-05, logs in, and the save completes automatically
- A deep link opens the right experience from a cold start
- `dart analyze --fatal-infos` clean · `flutter test` green · `rls.test.sql` passing
- Commit, `PROGRESS.md` updated, and the Graph prompt run

**Then stop. Review before Stage B.**

---

# STAGE B — TRANSACTIONAL

## Phase 5 — Search hardening
`search-experiences` Edge Function with ranked full-text, filters, sort. Pagination, recent
searches, no-results recovery. **Exit:** "Everest" returns ranked results under 1 s on staging;
back-from-detail restores scroll position.

## Phase 6 — Map
`google_maps_flutter` with markers from published experiences, marker → detail, static fallback
when tiles fail, permission denial handled per App Flow §5.7. **Exit:** pins render; denying
location still shows the meeting-point text.

## Phase 7 — Booking and payment · highest risk
`create-booking-intent` (server re-price, 15-min quote, unique idempotency key) ·
`khalti_checkout_flutter` and eSewa handoff · `payment-webhook` verifying with the gateway then in
**one transaction** setting `payments.paid`, `bookings.confirmed`, decrementing `spots_left`,
inserting participants, seeding the gear checklist · PL-11 with `booking_ref`.
**Exit:** happy path confirms · duplicate webhook creates no second booking · expired quote
re-prices · failed payment leaves the booking `pending` and recoverable · the client success
callback alone never confirms anything · pricing unit tests cover children, add-ons, zero-child.

## Phase 8 — Trip tools
Trip Chat on Supabase Realtime with a local outbox that queues offline and resends · Gear Checklist
with custom items · Budget Tracker · Drafts resume + delete confirmation.
**Exit:** two devices exchange messages live; airplane mode queues and resends.

## Phase 9 — Trips and reviews
Cron Edge Function flips past confirmed bookings to `completed` · Leave a Review · Review Submitted
· My Reviews · rating aggregate trigger verified end to end.
**Exit:** a completed trip offers a review exactly once; `rating_avg` moves after submission.

---

# STAGE C — PRODUCTION

## Phase 10 — Host application, live
`submit-host-application` validating all four steps · uploads to the **private** `host-documents`
bucket · status tracker from the real row · admin review done manually in the Supabase dashboard
for v1. **Exit:** the ID document is unreachable without an admin signed URL.

## Phase 11 — Localization, accessibility, resilience
Complete `app_ne.arb`, zero literals left · optional Bikram Sambat display · `Semantics` labels
everywhere · `textScaler` pass with no clipping · reduced motion · offline banner · retry on every
network surface · Sentry + PostHog.
**Exit:** usable end to end in Nepali; largest text scale clips nothing; airplane mode never shows
a blank screen.

## Phase 12 — Release
Icon, splash, store listings in en and ne · privacy policy · signing config and flavors · Khalti
live keys · `integration_test` suite green (onboarding, book, chat, review, host apply) ·
Play internal testing + TestFlight · crash-free baseline.

---

## Dependency graph

```
S-1 ─► S0 ─┬─► S1 ─┐
           │       ├─► S4 ─► [STAGE A REVIEW] ─┬─► 5 ─► 6 ─► 7 ─► 8 ─► 9 ─┐
           └─► S2 ─► S3 ─┘                     └─► 10 ───────────────────┤
                                                                          ├─► 11 ─► 12
```
S1 and S2 run in parallel. S3 needs S2 **applied**, not merely written. S4 needs S1 + S3.

---

## What Stage A deliberately does NOT do

Payments, real bookings, chat, reviews, host submission, notifications, Nepali translation, map
tiles, refunds, admin tooling. Each is listed with a trigger condition in `FEATURES_BACKLOG.md`.
Nothing there gets built early just because it looks easy.
