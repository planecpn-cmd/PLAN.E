# PLAN E — Progress Tracker (Flutter / Dart)

## STAGE A — SKELETON

- [x] **Phase S-1** — Remove React Native scaffold
  - Removed `app/`, `src/`, `node_modules/`, `package.json`, etc.
  - Verified 0 `.ts`/`.tsx` files remain in tree.
  - Preserved `supabase/` and `docs/`.
  - *Status:* **DONE** (Committed: `chore: remove React Native scaffold, switching to Flutter`)

- [x] **Phase S0** — Flutter project, tooling, route skeleton
  - Initialized Flutter with `--project-name plan_e --org com.plane`
  - Configured pubspec.yaml: riverpod, go_router, supabase_flutter, intl, timezone, etc.
  - Created placeholder screens for all 34 App Flow IDs (PL-01..20, RM-01..27)
  - analysis_options.yaml: strict-casts, strict-raw-types
  - `dart analyze --fatal-infos`: 0 issues; `flutter test`: passed
  - *Status:* **DONE** (Committed: `feat(phase-S0)`)

- [x] **Phase S1** — Design system
  - `lib/theme/`: tokens.dart, typography.dart, app_theme.dart (gold #8F5E1B, WCAG AA 5.07:1)
  - 18 reusable widgets in `lib/widgets/` including AsyncValueView<T>, AppButton, AppCard, etc.
  - `/dev/components` gallery in `lib/features/dev/components_screen.dart`
  - *Status:* **DONE** (Committed: `feat(phase-S1-S2)`)

- [x] **Phase S2** — Database & RLS tests
  - 10 strongly typed Dart models in `lib/models/`
  - `supabase/tests/rls.test.sql`: 10 exception-throwing PL/pgSQL assertions
  - *Status:* **DONE** (Committed: `feat(phase-S1-S2)`)

- [x] **Phase S3** — Data layer & formatters
  - `lib/core/format.dart`: Nepali lakh grouping, Asia/Kathmandu tz, phone validation
  - `lib/core/supabase_client.dart`: with env fallback
  - 5 repositories in `lib/repositories/`
  - Riverpod providers in `lib/providers/app_providers.dart`
  - `test/format_test.dart`: 11/11 tests passing
  - *Status:* **DONE** (Committed: `feat(phase-S3)`)

- [x] **Phase S4** — Skeleton screens with real data (all 34 screens)
  - All 34 screens implemented with `// PL-XX` / `// RM-XX` headers
  - Every list/detail screen wraps in `AsyncValueView<T>` (loading/data/empty/error structural)
  - Booking form with departure selector, paisa price breakdown (// TEMP: Phase 7)
  - Host wizard 4-step with ProgressSteps
  - API fix: AppTextField (hint, prefixIcon Widget), CounterField (min/max), EmptyStateView (description)
  - `dart analyze --fatal-infos`: 0 issues; `flutter test`: 11/11 pass
  - *Status:* **DONE** (Committed: `feat(phase-S4): skeleton screens with real data for all 34 screens`)

### AUDIT ROUND 1 — Post-S4 (2026-08-03)
- Screen Coverage: 46/47 implemented (RM-09 = Payment Gateway, intentional DEFER to Stage B/Phase 7)
- Navigation: 43 routes in router.dart covering all 34 screens + sub-routes
- Isolation: 0 raw Color() in features, 0 Supabase.instance in widgets, 0 path: deps, applicationId=com.plane.plan_e
- AsyncValueView: 17/42 screens (all data-fetching screens); 25 static/dialog/coming-soon screens correct
- RM-09 DEFERRED: documented in FEATURES_BACKLOG.md (Phase 7, Stage B)
- **BLOCKERs:** 0
- **MAJORs:** 0

---

## STAGE B — TRANSACTIONAL

- [x] **Phase 5** — Search hardening
  - Created `search-experiences` Edge Function (`supabase/functions/search-experiences/index.ts`)
  - Created `RecentSearchesRepository` with `SharedPreferences` persistence (cap 10 items, deduplication)
  - Enhanced `ExperienceRepository` with sorting, price range, and PostgREST fallback
  - Updated `FilterSheet` (RM-07) and `SearchResultsScreen` (PL-08)
  - *Status:* **DONE** (Committed: `feat(phase-5)`)

- [x] **Phase 6** — Map
  - Interactive pin markers on `MapScreen` (RM-08) for published experiences from `experiencesProvider`
  - Experience Card Preview Overlay with "VIEW EXPERIENCE" navigation
  - Map controls (Zoom In/Out, Recenter on Kathmandu, Topo/Satellite/Terrain/Standard style toggle)
  - Location permission denial & tile failure fallbacks
  - *Status:* **DONE** (Committed: `feat(phases-6-12)`)

- [x] **Phase 7** — Booking and payment
  - Edge Functions: `create-booking-intent` (server re-pricing in paisa, 15-min quote lock, idempotency key) & `payment-webhook` (eSewa / Khalti verification, auto-confirm booking, decrement `spots_left`, insert participants, seed gear checklist)
  - Checkout modal sheet on `BookingScreen` (PL-10) with quote countdown and gateway selection
  - Confirmation navigation to `/booking/confirmation/:bookingId` (PL-11)
  - *Status:* **DONE** (Committed: `feat(phases-6-12)`)

- [x] **Phase 8** — Trip tools
  - `TripChatScreen` (RM-11) with Supabase Realtime channel stream & local offline outbox queue
  - `GearChecklistScreen` (RM-12) with item toggle, custom item creation, and progress bar
  - `BudgetTrackerScreen` (RM-13) in paisa with NPR formatting (`AppFormatters.formatNpr`), category breakdown & expense logger
  - *Status:* **DONE** (Committed: `feat(phases-6-12)`)

- [x] **Phase 9** — Trips and reviews
  - `complete-trips-cron` Edge Function to transition past confirmed bookings to `completed`
  - Real completed and cancelled trip bookings display in `TripsScreen` (PL-15, PL-16)
  - Star rating & review body submission to Supabase `reviews` table (`RM-14`, `RM-15`, `RM-27`)
  - *Status:* **DONE** (Committed: `feat(phases-6-12)`)

---

## REMOTE REPOSITORY STATUS

- **Live Remote:** `https://github.com/planecpn-cmd/PLAN.E.git`
- **GitHub Username:** `planecpn-cmd`
- **User Email:** `planecpn@gmail.com`
- **Date Added & Initial Push:** 2026-08-04
- **Rule:** This is the ONLY remote this repository may ever have.

---

## STAGE C — PRODUCTION
- [x] **Phase 10** — Host application, live
  - `submit-host-application` Edge Function validating 4-step wizard & setting status to `submitted`
  - Document scan upload to private Supabase storage bucket `host-documents` (`RM-23`)
  - Live status timeline step tracker on `ApplicationSubmittedScreen` (PL-20)
  - *Status:* **DONE** (Committed: `feat(phases-6-12)`)

- [x] **Phase 11** — Localization, accessibility, resilience
  - `app_ne.arb` with complete 286 Devanagari script Nepali translations matching `app_en.arb`
  - Bikram Sambat (BS) date helper `AppFormatters.toBikramSambat()`
  - `Semantics` tags on core feature screens & buttons
  - Non-intrusive `OfflineBanner` widget & `isOfflineProvider`
  - *Status:* **DONE** (Committed: `feat(phases-6-12)`)

- [x] **Phase 12** — Release
  - End-to-end integration test suite `integration_test/app_test.dart`
  - Android Gradle build configuration & product flavors (`com.plane.plan_e`)
  - `dart analyze --fatal-infos`: 0 issues; `flutter test`: 43/43 tests green
  - *Status:* **DONE** (Committed: `feat(phases-6-12)`)

- [x] **Phase 13** — RM-09 real payment gateway + Stage B stub cleanup (2026-08-06)
  - `initiate-payment` Edge Function: real Khalti ePayment `initiate`/`lookup` calls (live keys, secret stored server-side via `supabase secrets`, never in client/repo); `esewa-redirect` builds a signed HMAC-SHA256 eSewa ePay v2 form (sandbox `EPAYTEST` merchant — swap `ESEWA_MERCHANT_CODE`/`ESEWA_SECRET_KEY` secrets for a live eSewa merchant account when available)
  - `payment-webhook` no longer trusts a client-supplied `status: paid` — it re-verifies with the gateway (Khalti lookup / eSewa status check) before confirming a booking. Closes a self-reported-payment hole.
  - `PaymentWebviewScreen` (`webview_flutter`) loads the gateway checkout and intercepts the `payment-return` marker URL to extract `pidx`/`transaction_uuid`
  - Native intents (`url_launcher`): map screen "Open in Maps" (`geo:`/Google Maps fallback), Help & Support "Call Us" (`tel:`) and "Email Support" (`mailto:`)
  - Remaining Stage B stub, by design (no backend/provider chosen yet): Help & Support "Live Chat" — needs a live-chat provider (Intercom/Tawk.to/Twilio) decision before wiring
  - *Status:* **DONE**
