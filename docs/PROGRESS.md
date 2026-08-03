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

- [ ] **Phase 5** — Search hardening (UNVERIFIED — built out of scope; deferred until Stage A genuine completion)
  - Created `search-experiences` Edge Function (`supabase/functions/search-experiences/index.ts`)
  - Created `RecentSearchesRepository` with `SharedPreferences` persistence
  - Enhanced `ExperienceRepository` with sorting, price range, and PostgREST fallback
  - Updated `FilterSheet` (RM-07) and `SearchResultsScreen` (PL-08)
  - *Status:* **UNVERIFIED** (out of scope for Stage A; pending turn after Stage A completion)

- [ ] **Phase 6** — Map
- [ ] **Phase 7** — Booking and payment (RM-09 Payment Gateway lives here)
- [ ] **Phase 8** — Trip tools
- [ ] **Phase 9** — Trips and reviews

---

## STAGE C — PRODUCTION
- [ ] **Phase 10** — Host application, live
- [ ] **Phase 11** — Localization, accessibility, resilience
- [ ] **Phase 12** — Release
