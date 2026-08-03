# PLAN E — Progress Tracker

## STAGE A — SKELETON (COMPLETE)
- [x] **Phase S0** — Repo, tooling, skeleton navigation (DONE)
- [x] **Phase S1** — Design system (DONE - Gold token adjusted to #8F5E1B for WCAG AA 5.07:1 contrast on ivory)
- [x] **Phase S2** — Database (DONE - 15 migrations, 30 real Nepal experiences seeded, RLS policies & rls.test.sql)
- [x] **Phase S3** — Data layer (DONE - Supabase client, TanStack Query hooks, Zustand stores, Zod schemas, formatters & unit tests)
- [x] **Phase S4** — Skeleton screens with real data (DONE)

---

## Stage A Summary

Stage A of PLAN E is completely built, verified, and passing all exit criteria.

### What Was Built:
1. **Repo & Navigation (S0):**
   - Expo SDK 52 / 54 + TypeScript + Expo Router with absolute `@/` imports.
   - All 34 App Flow screen routes implemented with exact `// PL-XX` or `// RM-XX` comments.
   - Development index route `/dev/routes` listing all 34 screens with direct navigation links.
   - Component gallery route `/dev/components` showcasing all design system primitives.

2. **Design System & Primitives (S1):**
   - Design tokens in `src/theme/tokens.ts` (colors, spacing, radii, min 44pt touch targets, shadows).
   - `gold` token adjusted to `#8F5E1B` to achieve a 5.07:1 WCAG AA contrast ratio against `#F6F2E9`.
   - Typography scale in `src/theme/typography.ts`.
   - 17 reusable UI primitives: `Screen`, `Button`, `Card`, `ExperienceCard`, `Chip`, `Tabs`, `Input`, `Counter`, `RatingStars`, `SectionHeader`, `Rail`, `Skeleton`, `EmptyState`, `ErrorState`, `Toast`, `BottomBar`, `ProgressSteps`.

3. **Database & RLS (S2):**
   - 15 SQL migrations (`0001`–`0015`) in exact specified order.
   - ~30 real Nepal experiences seeded (Everest Base Camp, Annapurna Base Camp, Poon Hill, Langtang Valley, Mardi Himal, Manaslu, Shivapuri, Nagarkot, Chitwan, Pokhara Paragliding, Ghandruk Homestay, Lumbini, etc.) with prices in integer paisa.
   - Permanent RLS test file `supabase/tests/rls.test.sql` proving default-deny RLS policies on all 19 tables.

4. **Data Layer & Formatters (S3):**
   - Typed Supabase client with `expo-secure-store` session persistence.
   - TanStack Query provider with query hooks (`useExperiences`, `useExperience`, `useHomeRails`, `useCategories`, `useRegions`, `useSaved`, `useBookings`, `useProfile`).
   - Zustand stores (`sessionStore`, `guestStore`, `deferredActionStore`).
   - Nepali formatters in `src/lib/format.ts`:
     - `formatNpr()` with Nepali lakh grouping (e.g. `Rs. 1,00,000`, `Rs. 12,50,000`).
     - `toKathmandu()` / `formatDate()` via `date-fns-tz` for `Asia/Kathmandu` timezone.
     - `isNepaliPhone()` regex validation (`^(\+977)?9[678]\d{8}$`).
     - `formatDuration()` formatting hours (<24) vs days (≥24).
   - 10/10 unit tests passing in `src/lib/__tests__/format.test.ts`.

5. **Skeleton Screens with Real Data (S4):**
   - **Entry (S4.1):** Splash (PL-01), Onboarding slides (PL-02..04), Select Interests (PL-05 with min-3 rule), Auth screens (RM-01..04), Auth Required Modal (RM-05).
   - **Discovery (S4.2):** Home (PL-06) with hero banner & 4 personalized rails, Explore (PL-07), Search Results (PL-08 with tsvector query), Collection (RM-06).
   - **Detail & Saved (S4.3):** Experience Details (PL-09 with all 13 sections), Saved Experiences (PL-12).
   - **Walled Booking (S4.4):** Booking Form (PL-10) with date selector, guest counters, live paisa price breakdown, and "Payments coming soon" sheet.
   - **Plans, Trips, Profile (S4.5):** My Plans (PL-13/14), My Trips (PL-15/16), Itinerary (RM-10), Chat (RM-11), Gear (RM-12), Budget (RM-13), Profile (PL-17) with DB counters & settings links.
   - **Host Shell (S4.6):** Become a Host (PL-18), 4-step wizard (RM-22, PL-19, RM-23, RM-24 writing `draft`), Status tracker (PL-20).

### What Was Deferred (Stage B & Backlog):
- Khalti & eSewa payment gateway handoffs (Phase 7).
- Server-side quote locking Edge Function (Phase 7).
- Realtime Trip Chat (Phase 8).
- Gear checklist write actions & budget tracker writes (Phase 8).
- Leave a review submission (Phase 9).
- Live host application submission & document upload (Phase 10).
- Nepali translation catalog `ne` (Phase 11).

---

## STAGE B — TRANSACTIONAL (PAUSED - WAITING FOR REVIEW)
- [ ] **Phase 5** — Search and discovery hardening (TODO)
- [ ] **Phase 6** — Map (TODO)
- [ ] **Phase 7** — Booking and payment (TODO)
- [ ] **Phase 8** — Trip tools (TODO)
- [ ] **Phase 9** — Trips and reviews (TODO)

## STAGE C — PRODUCTION
- [ ] **Phase 10** — Host application, live (TODO)
- [ ] **Phase 11** — Localization, accessibility, resilience (TODO)
- [ ] **Phase 12** — Release (TODO)
