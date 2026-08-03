# PLAN E — Complete Implementation Plan

Version 2.0 · 3 August 2026 · For an autonomous AI coding agent (Antigravity)
Companion docs: App Flow Document v1.0, UI/UX Design Report v1.0, TRD.md, BACKEND_SCHEMA.md,
FEATURES_BACKLOG.md (everything deliberately deferred).

---

## 0. How to read this plan

The build is split into three stages:

| Stage | Phases | Goal | Time |
|---|---|---|---|
| **STAGE A — Skeleton** | S0 – S4 | Every screen exists, navigates, and renders real data. Nothing is transactional. This is what we are building right now. | first |
| **STAGE B — Transactional** | 5 – 9 | Money, chat, reviews, hosting. The app becomes real. | after skeleton is approved |
| **STAGE C — Production** | 10 – 12 | Localization, accessibility, resilience, release. | last |

**Right now: build STAGE A only.** Stop after S4 and wait for review. Stage B and C sections are
written out so the agent knows where things are heading and does not architect itself into a
corner — not so it builds them early.

Non-negotiables in every phase:

1. One phase at a time. Never start N+1 before N's exit checks pass with real output.
2. Each phase ends: typecheck clean, lint clean, tests pass, app boots on a device, one commit
   `feat(phase-N): <summary>`, `docs/PROGRESS.md` updated.
3. Missing detail? Authority order: App Flow → UI/UX Report → TRD → Backend Schema → agent
   judgement. Log it in `docs/OPEN_QUESTIONS.md`, pick the smallest default, mark
   `// ASSUMPTION:` in code, continue. Never stall.
4. Every screen file opens with `// PL-XX <Screen Name>` or `// RM-XX <Screen Name>` so coverage
   is greppable.
5. Never invent a screen absent from the App Flow inventory.
6. No secrets committed. Service-role key never in the app bundle.

---

# STAGE A — THE SKELETON

Definition of "skeleton": you can install the app, pass onboarding, browse real Nepal experiences
from a real database, open any of the 34 screens through normal navigation, and see correct
loading / empty / error states. Booking stops at a "coming soon" wall. No payment, no chat, no
reviews, no host submission.

Why this order: navigation and data shape are the expensive things to change later. Payments are
not — they bolt onto a correct booking row. Get the shape right first.

---

## Phase S0 — Repo, tooling, skeleton navigation

**Build**

- Expo (SDK 54+) + TypeScript + `expo-router`, EAS project initialised.
- ESLint + Prettier + Husky pre-commit running typecheck and lint.
- Absolute imports via `@/` (tsconfig paths + babel module-resolver).
- `.env.example` with `EXPO_PUBLIC_SUPABASE_URL`, `EXPO_PUBLIC_SUPABASE_ANON_KEY`.
- Git repo, `main` branch, `.gitignore` covering `.env*`, `node_modules`, `.expo`.
- **The full route tree as empty placeholder screens**, one file per App Flow ID. Each renders its
  own ID and name and nothing else. This is the single most valuable thing in S0 — it makes the
  entire app navigable on day one.

```
app/
  _layout.tsx                     root stack + providers
  index.tsx                       PL-01 Splash
  (onboarding)/
    slide-1.tsx  slide-2.tsx  slide-3.tsx      PL-02..04
    interests.tsx                              PL-05
  (auth)/
    sign-up.tsx  login.tsx  forgot-password.tsx  reset-result.tsx   RM-01..04
  (tabs)/
    _layout.tsx                   5-item bottom nav
    home.tsx                      PL-06
    explore.tsx                   PL-07
    plans.tsx                     PL-13 / PL-14 (tabs)
    trips.tsx                     PL-15 / PL-16 (tabs)
    profile.tsx                   PL-17
  search.tsx                      PL-08
  collection/[slug].tsx           RM-06
  experience/[id].tsx             PL-09
  booking/[id].tsx                PL-10
  booking/confirmation.tsx        PL-11
  saved.tsx                       PL-12
  map.tsx                         RM-08
  itinerary/[bookingId].tsx       RM-10
  chat/[bookingId].tsx            RM-11
  gear/[bookingId].tsx            RM-12
  budget/[bookingId].tsx          RM-13
  review/[bookingId].tsx          RM-14
  review/submitted.tsx            RM-15
  profile/edit.tsx                RM-16
  profile/payment-methods.tsx     RM-17
  profile/notifications.tsx       RM-18
  profile/language.tsx            RM-19
  profile/help.tsx                RM-20
  profile/settings.tsx            RM-21
  profile/my-reviews.tsx          RM-27
  host/index.tsx                  PL-18
  host/step-1.tsx .. step-4.tsx   RM-22, PL-19, RM-23, RM-24
  host/submitted.tsx              PL-20
src/
  components/  theme/  lib/  hooks/  stores/  types/  i18n/
```

**Deliverables:** app boots, bottom nav switches between 5 destinations, every route above is
reachable by typing its path or via a temporary `/dev/routes` index listing all of them.

**Exit:** `npx tsc --noEmit` clean · `npm run lint` clean · app runs on Android and iOS ·
`/dev/routes` lists all 34 IDs and each opens.

---

## Phase S1 — Design system

**Build**

- `src/theme/tokens.ts` — colors from UI/UX Report §5.2: `forest #18372D`, `deep #01251C`,
  `ivory #F6F2E9`, `gold #B7802B`, `sage #E7ECE7`, `ink #24312D`. Spacing scale
  (4/8/12/16/20/24/32/40). Radii (8/16/24/pill). Elevation levels.
- `src/theme/typography.ts` — serif display family for wordmark/headings/destination titles,
  sans family for body/labels/buttons. Sizes: display 32/28, heading 24/20, body 16/14,
  caption 12. Line heights ≥1.4.
- Primitives in `src/components/`:
  `Screen`, `Button` (primary / secondary / text / disabled), `Card`, `ExperienceCard`,
  `Chip` (filter pill, active + inactive), `Tabs`, `Input`, `Counter`, `RatingStars`,
  `SectionHeader`, `Rail` (horizontal list), `Skeleton`, `EmptyState`, `ErrorState`, `Toast`,
  `BottomBar` (fixed price + CTA), `ProgressSteps` (host application).
- `/dev/components` gallery route rendering every primitive in every state.

**Rules:** touch targets ≥44×44 pt even when the icon is smaller. No raw hex outside `theme/`.
Selected/active state must use more than color (checkmark, fill, border) — Design Report §8.2.

**Exit:** gallery renders all primitives · gold-on-ivory and gold-on-white contrast measured
against WCAG AA; if it fails, darken the gold token and record the change in `PROGRESS.md`.

---

## Phase S2 — Database

**Build:** Supabase project (staging), then `supabase/migrations/0001`–`0015` exactly as ordered
in BACKEND_SCHEMA.md §7 — extensions, enums, profiles + triggers, taxonomy + seeds, experiences +
departures + itinerary, saved, bookings, payments, trip tools, reviews, host applications,
notifications, **all RLS policies in one reviewable file**, views, dev seed.

Seed ~30 real Nepal experiences with real photos, prices in paisa, real regions and difficulties
(Everest Base Camp, Annapurna Base Camp, Poon Hill, Langtang Valley, Mardi Himal, Manaslu Circuit,
Shivapuri day hike, Nagarkot sunrise, Chitwan safari, Rara Lake, Ghandruk homestay, Bandipur
culture walk, Pokhara paragliding, Lumbini pilgrimage, Bhaktapur pottery workshop, …). Never demo
this app with lorem ipsum.

Generate types: `supabase gen types typescript --project-id … > src/types/database.ts`.

**Exit:** `supabase db reset` rebuilds everything from zero · seed data present ·
`supabase/tests/rls.test.sql` proves:
anon reads published experiences · anon cannot read any booking · user A cannot read user B's
bookings · no client role can update `bookings.status`, `payments.*`, or
`experience_departures.spots_left`.
**This test file is permanent. It is never deleted, only extended.**

---

## Phase S3 — Data layer

**Build**

- `src/lib/supabase.ts` — typed client, session persisted in `expo-secure-store`, auto-refresh on
  app foreground.
- TanStack Query provider with sane defaults: `retry: 2`, `staleTime: 60s`,
  `refetchOnReconnect: true`.
- Zustand stores: `sessionStore` (user, role), `guestStore` (guest id, local interests),
  `deferredActionStore` (`{screenId, entityId, action, params}` for the RM-05 replay).
- Query hooks: `useExperiences(filters)`, `useExperience(id)`, `useHomeRails()`, `useCategories()`,
  `useRegions()`, `useSaved()`, `useBookings(status)`, `useProfile()`.
- Zod schemas in `src/lib/schemas.ts`, shared later with Edge Functions.
- `src/lib/format.ts`:
  - `formatNpr(paisa)` → `Rs. 12,50,000` (Nepali lakh grouping, not western thousands)
  - `toKathmandu(date)` / `formatDate` using a real tz library with `Asia/Kathmandu`
    — never a hardcoded +05:45 offset
  - `isNepaliPhone(v)` → `^(\+977)?9[678]\d{8}$`
  - `formatDuration(hours)` → hours under 24, days above

**Exit:** unit tests green for lakh formatting (incl. 1,00,000 and 12,50,000), timezone conversion
across a DST-free boundary, phone validation accept/reject cases, duration formatting.

---

## Phase S4 — Skeleton screens with real data

This is the big one. Every screen gets its real layout and real data. Nothing writes money.

**S4.1 Entry (PL-01 – PL-05, RM-01 – RM-05)**
Splash with the NEPAL→PLAN E transition and a reduced-motion path · 3 onboarding slides with page
dots and the three entry actions · Sign Up / Login / Forgot Password / Reset Result (real Supabase
Auth: email+password and phone OTP) · guest session · Select Interests with minimum-3 rule and a
disabled Continue below three · RM-05 Authentication Required modal writing and replaying the
deferred action per TRD §5.

**S4.2 Discovery (PL-06, PL-07, PL-08, RM-06, RM-07)**
Home: hero banner + rails (Recommended for You, Trending Treks, Homestays Near You, Community and
Volunteering) personalised by the user's interests · Explore: search bar, activity chips, category
grid, Popular Regions, Map FAB · Search Results with filter/sort · Collection / See All ·
Filter & Sort bottom sheet. Lists use FlashList. Every rail: skeleton → data → empty → error.

Search in the skeleton is a plain Postgres `tsvector` query from the client. The
`search-experiences` Edge Function is Stage B — the query shape does not change, only where it runs.

**S4.3 Detail and saving (PL-09, PL-12, RM-08)**
Experience Details in the exact section order of App Flow §5.7: cover, spots-left status, title /
location / rating / date, duration / difficulty / group size, trip overview, price, what's
included, what to bring, meeting point + map, participants, things to know, reviews, organizer,
fixed bottom bar with price and Join. Share via deep link. View on Map with a permission-denied
fallback to the text meeting point. Optimistic heart save with rollback on failure. Saved
Experiences: two-column grid, All / Treks / Stays / Available filters.

**S4.4 Booking form, walled (PL-10)**
Build the full form — date picker from `experience_departures`, Adults/Children counters, add-ons,
Full Name + Phone with validation, live price breakdown computed from real DB prices. Proceed to
Payment opens a **"Payments coming soon"** sheet. It does not create a booking. Client-side pricing
here is display-only and will be replaced by the server quote in Phase 7 — mark it
`// TEMP: client pricing, server re-price lands in Phase 7`.

**S4.5 Plans, Trips, Profile shells (PL-13 – PL-17, RM-10 – RM-13, RM-16 – RM-21, RM-27)**
My Plans with Upcoming/Drafts tabs reading real bookings (empty for now — that is the correct
state, show the empty state) · My Trips with Completed/Cancelled tabs · Itinerary reading
`itinerary_items` (real data, read-only) · Chat, Gear Checklist, Budget Tracker as laid-out
screens with a "coming soon" body · Profile with real counters from the DB, avatar, Edit Profile,
and all settings destinations reachable as titled empty screens.

**S4.6 Host shell (PL-18, PL-19, PL-20, RM-22 – RM-24)**
Become a Host landing built fully (hero, benefits, 4-step how-it-works, testimonial, CTA) · the
4-step application UI with progress indicator and Back/Next, step 2 exactly as wireframed, steps
1/3/4 to their stated purpose with fields marked `// ASSUMPTION:` · Submit writes a `draft` row
only · Application Submitted status tracker rendered with static state.

**Exit for Stage A**
- All 34 App Flow IDs implemented and reachable through normal navigation, not just direct URL.
- Every list and detail screen shows correct loading, empty and error states — verified by killing
  the network mid-load.
- Home rails reflect the interests chosen in onboarding.
- A guest tapping Save is gated by RM-05, logs in, and the save completes automatically.
- Deep link opens the right experience from a cold start.
- Typecheck, lint, unit tests, RLS tests all green.
- Commit + `PROGRESS.md` updated + a screen-coverage table generated by the Graph prompt.

**Then stop. Review with the user before Stage B.**

---

# STAGE B — TRANSACTIONAL

## Phase 5 — Search and discovery hardening
Move search into the `search-experiences` Edge Function with ranked full-text + filters + sort.
Add pagination/infinite scroll, recent searches, and "no results" recovery (Clear Filters /
Explore). Cache tuning for 3G.
**Exit:** searching "Everest" returns ranked seeded results in under 1 s on staging; filters change
results; back-from-detail restores scroll position.

## Phase 6 — Map
Real `react-native-maps` view with markers from published experiences, marker → detail, static
fallback image when tiles fail. Permission flow with denial handled per App Flow §5.7 step 4.
**Exit:** map renders Nepal-bounded pins; denying location still shows the meeting-point text.

## Phase 7 — Booking and payment · highest risk
Server-first, always. Client never prices anything.
- `create-booking-intent` Edge Function: re-prices from the DB, locks a 15-minute quote, writes
  `bookings(status='pending')` + `payments(status='initiated')` with a unique idempotency key,
  returns the gateway payload.
- Khalti (primary) and eSewa (secondary) checkout handoff.
- `payment-webhook`: verifies with the gateway's lookup API using the secret key, then in **one
  transaction** sets `payments.paid`, `bookings.confirmed`, decrements `spots_left`, inserts
  `booking_participants`, seeds the gear checklist from `bring_list`.
- PL-11 Booking Confirmation with `booking_ref`, receipt card, next steps.
**Exit:** happy path confirms · duplicate webhook creates no second booking · expired quote
re-prices and asks for confirmation · failed payment leaves the booking `pending` and recoverable ·
pricing unit tests cover children, add-ons, zero-child, and add-on-free cases.

## Phase 8 — Trip tools
Trip Chat on Supabase Realtime with a local outbox that queues offline and resends on reconnect ·
Gear Checklist with custom items · Budget Tracker with add/edit/delete and a client-computed total ·
Drafts tab with resume + Delete Draft confirmation (RM-25).
**Exit:** two devices exchange messages live; airplane mode queues a message and it sends on
reconnect; checklist and budget persist across restart.

## Phase 9 — Trips and reviews
Cron Edge Function flips past confirmed bookings to `completed` · Leave a Review form · Review
Submitted state · My Reviews · rating aggregate trigger verified end to end.
**Exit:** a completed trip offers a review exactly once; after submitting, the card reads
"Reviewed" and the experience's `rating_avg` moves.

---

# STAGE C — PRODUCTION

## Phase 10 — Host application, live
`submit-host-application` Edge Function validating all four steps, uploads to the **private**
`host-documents` bucket, status tracker driven by the real row, admin review done manually in the
Supabase dashboard for v1.
**Exit:** an application submits, shows `submitted`, and the ID document is unreachable without an
admin signed URL.

## Phase 11 — Localization, accessibility, resilience
Full `en` + `ne` strings via i18next, zero literals left in components · optional Bikram Sambat
display toggle (Gregorian always stored) · screen-reader labels on every image, icon, rating
control, upload, progress step and nav item · dynamic-type pass with no clipping · reduced-motion
alternative for the splash transition · global offline banner · retry on every network surface ·
Sentry + PostHog.
**Exit:** app usable end to end in Nepali; largest system font clips nothing; airplane mode shows
cached content and never a white screen.

## Phase 12 — Release
Icon and splash assets · store listings in en and ne · privacy policy · EAS production profile ·
Khalti/eSewa live keys · Maestro E2E suite (onboarding, book, chat, review, host apply) green ·
Play internal testing + TestFlight · crash-free-session baseline.
**Exit:** signed builds on both tracks, all E2E green.

---

## Dependency graph

```
S0 ─┬─► S1 ─┐
    │       ├─► S4 ─► [STAGE A REVIEW] ─┬─► 5 ─► 6 ─► 7 ─► 8 ─► 9 ─┐
    └─► S2 ─► S3 ─┘                     └─► 10 ────────────────────┤
                                                                   ├─► 11 ─► 12
```

S1 and S2 run in parallel. S3 needs S2. S4 needs S1 + S3. Phase 10 needs only the Stage A review.

---

## What Stage A deliberately does NOT do

Payments, real bookings, chat, reviews, host submission, notifications, Nepali translation,
map tiles, refunds, admin tooling. All of it is listed with a trigger condition in
`FEATURES_BACKLOG.md`. Nothing there gets built early just because it is easy.
