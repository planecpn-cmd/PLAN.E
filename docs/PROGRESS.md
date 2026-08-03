# PLAN E — Progress Tracker

## STAGE A — SKELETON

- [x] **Phase S0** — Repo, tooling, skeleton navigation
  - Code & routes built (All 34 screens + `/dev/routes`)
  - `npx tsc --noEmit`: Clean (0 errors)
  - `npm run lint`: Clean (0 errors)
  - *Status:* **BLOCKED (Awaiting device / Expo start verification)**

- [x] **Phase S1** — Design system
  - Tokens (`tokens.ts`) & Typography (`typography.ts`) created
  - Gold token adjusted to `#8F5E1B` (WCAG AA 5.07:1 contrast on ivory)
  - 17 primitives built & `/dev/components` gallery created
  - `npx tsc --noEmit` & `npm run lint`: Clean
  - *Status:* **BLOCKED (Awaiting visual verification on device/browser via `npx expo start`)**

- [ ] **Phase S2** — Database
  - 15 SQL migration files (`0001`–`0015`) created under `supabase/migrations/`
  - ~30 real Nepal experiences seeded in `0015_seed_dev.sql`
  - Permanent test file `supabase/tests/rls.test.sql` created
  - TypeScript types created in `src/types/database.ts`
  - *Status:* **BLOCKED (Requires real Supabase staging keys in `PLAN E/.env` to run `supabase db reset` & `rls.test.sql` against live Postgres)**

- [x] **Phase S3** — Data layer
  - Supabase client, TanStack Query hooks, Zustand stores, Zod schemas created
  - Nepali formatters (`formatNpr`, `toKathmandu`, `isNepaliPhone`, `formatDuration`) created
  - Unit tests in `src/lib/__tests__/format.test.ts` passed (10/10 passed)
  - `npx tsc --noEmit`, `npm run lint`, `npm test`: All Clean
  - *Status:* **DONE (Code & automated unit tests 100% verified)**

- [ ] **Phase S4** — Skeleton screens with real data
  - All 34 screens updated with layout, loading/empty/error states, paisa formatting, and i18n
  - Walled booking form (PL-10) with live paisa price breakdown and "Payments coming soon" sheet
  - `npx tsc --noEmit`, `npm run lint`, `npm test`: All Clean
  - *Status:* **BLOCKED (Awaiting live Supabase database connection & device runtime verification)**

---

## Blocked Items & Exact Information Needed

To unblock Phase S2 and Phase S4 and move Stage A to 100% DONE:

1. **Supabase Staging Project Credentials:**
   - Real Supabase project URL (`EXPO_PUBLIC_SUPABASE_URL`) and anon key (`EXPO_PUBLIC_SUPABASE_ANON_KEY`) for PLAN E inside `PLAN E/.env`.
   - Database connection string / reference to run `supabase db reset` and execute `supabase/tests/rls.test.sql` against live Postgres.

2. **Device / Emulator Verification:**
   - Launching `npx expo start` to verify screens rendering live on an Android/iOS device or emulator.
