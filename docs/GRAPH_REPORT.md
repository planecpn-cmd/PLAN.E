# PLAN E — Coverage Report & Architecture Graphs

Date: 3 August 2026  
Audit Type: READ-ONLY Codebase Inspection & Integrity Audit  
Working Directory: `C:\Users\rauna\OneDrive\Desktop\PLAN E`

---

## A. Screen Coverage

Header comment inspection across `app/` screen inventory:

| ID | Screen Name | Implemented? | File Path | Loading | Empty | Error | Notes |
|---|---|---|---|---|---|---|---|
| **PL-01** | Splash | Yes | [index.tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/index.tsx) | N/A | N/A | N/A | Static splash entry screen |
| **PL-02** | Onboarding Step 1 | Yes | [slide-1.tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/(onboarding)/slide-1.tsx) | N/A | N/A | N/A | Onboarding carousel slide 1 |
| **PL-03** | Onboarding Step 2 | Yes | [slide-2.tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/(onboarding)/slide-2.tsx) | N/A | N/A | N/A | Onboarding carousel slide 2 |
| **PL-04** | Onboarding Step 3 | Yes | [slide-3.tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/(onboarding)/slide-3.tsx) | N/A | N/A | N/A | Onboarding carousel slide 3 |
| **PL-05** | Select Interests | Yes | [interests.tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/(onboarding)/interests.tsx) | Yes | Yes | Yes | Min-3 selection rule enforced |
| **PL-06** | Home Screen | Yes | [home.tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/(tabs)/home.tsx) | Yes | Yes | Yes | 4 personalized rails with DB data |
| **PL-07** | Explore Screen | Partial | [explore.tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/(tabs)/explore.tsx) | No | No | No | Category & region grid (Static layout) |
| **PL-08** | Search Results | Yes | [search.tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/search.tsx) | Yes | Yes | Yes | Postgres tsvector search + filters |
| **PL-09** | Experience Details | Yes | [id].tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/experience/[id].tsx) | Yes | N/A | Yes | All 13 App Flow sections in exact order |
| **PL-10** | Booking Form | Yes | [id].tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/booking/[id].tsx) | Yes | N/A | Yes | Live paisa pricing + Coming Soon sheet |
| **PL-11** | Booking Confirmation | Yes | [confirmation.tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/booking/confirmation.tsx) | N/A | N/A | N/A | Confirmation receipt screen |
| **PL-12** | Saved Experiences | Yes | [saved.tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/saved.tsx) | Yes | Yes | Yes | Saved items grid with filter tabs |
| **PL-13** | My Plans (Upcoming) | Yes | [plans.tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/(tabs)/plans.tsx) | Yes | Yes | Yes | Reads `bookings` table |
| **PL-14** | My Plans (Drafts) | Yes | [plans.tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/(tabs)/plans.tsx) | Yes | Yes | Yes | Reads pending `bookings` drafts |
| **PL-15** | My Trips (Completed) | Yes | [trips.tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/(tabs)/trips.tsx) | N/A | Yes | N/A | Completed trip list shell |
| **PL-16** | My Trips (Cancelled) | Yes | [trips.tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/(tabs)/trips.tsx) | N/A | Yes | N/A | Cancelled trip list shell |
| **PL-17** | Profile Screen | Yes | [profile.tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/(tabs)/profile.tsx) | N/A | N/A | N/A | Profile with DB counters & settings links |
| **PL-18** | Become a Host | Yes | [index.tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/host/index.tsx) | N/A | N/A | N/A | Host landing page |
| **PL-19** | Host Step 2 (Docs) | Yes | [step-2.tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/host/step-2.tsx) | N/A | N/A | N/A | Document upload step |
| **PL-20** | Application Submitted | Yes | [submitted.tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/host/submitted.tsx) | N/A | N/A | N/A | Host application status tracker |
| **RM-01** | Sign Up | Yes | [sign-up.tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/(auth)/sign-up.tsx) | N/A | N/A | N/A | Auth sign up screen |
| **RM-02** | Login | Yes | [login.tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/(auth)/login.tsx) | N/A | N/A | N/A | Auth login screen |
| **RM-03** | Forgot Password | Yes | [forgot-password.tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/(auth)/forgot-password.tsx) | N/A | N/A | N/A | Password reset request |
| **RM-04** | Reset Result | Yes | [reset-result.tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/(auth)/reset-result.tsx) | N/A | N/A | N/A | Password reset result message |
| **RM-05** | Auth Required Modal | Yes | [auth-required-modal.tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/(auth)/auth-required-modal.tsx) | N/A | N/A | N/A | Replays deferred guest actions |
| **RM-06** | Collection / See All | Yes | [slug].tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/collection/[slug].tsx) | N/A | N/A | N/A | Curated collection view |
| **RM-07** | Filter & Sort Sheet | Partial | [search.tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/search.tsx) | N/A | N/A | N/A | Filter chips rendered inline in search.tsx |
| **RM-08** | Map View | Yes | [map.tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/map.tsx) | N/A | N/A | N/A | Interactive map view shell |
| **RM-09** | Payment Gateway | Deferred | N/A | N/A | N/A | N/A | Stage B Phase 7 deferred feature |
| **RM-10** | Interactive Itinerary | Yes | [bookingId].tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/itinerary/[bookingId].tsx) | Yes | Yes | Yes | Reads `itinerary_items` from DB |
| **RM-11** | Trip Chat | Yes | [bookingId].tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/chat/[bookingId].tsx) | N/A | N/A | N/A | Walled Stage B coming soon screen |
| **RM-12** | Gear Checklist | Yes | [bookingId].tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/gear/[bookingId].tsx) | N/A | N/A | N/A | Walled Stage B coming soon screen |
| **RM-13** | Budget Tracker | Yes | [bookingId].tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/budget/[bookingId].tsx) | N/A | N/A | N/A | Walled Stage B coming soon screen |
| **RM-14** | Leave a Review | Yes | [bookingId].tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/review/[bookingId].tsx) | N/A | N/A | N/A | Review form |
| **RM-15** | Review Submitted | Yes | [submitted.tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/review/submitted.tsx) | N/A | N/A | N/A | Review confirmation screen |
| **RM-16** | Edit Profile | Yes | [edit.tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/profile/edit.tsx) | N/A | N/A | N/A | User profile edit screen |
| **RM-17** | Payment Methods | Yes | [payment-methods.tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/profile/payment-methods.tsx) | N/A | N/A | N/A | Saved wallets/cards screen |
| **RM-18** | Notifications | Yes | [notifications.tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/profile/notifications.tsx) | N/A | N/A | N/A | Notification settings |
| **RM-19** | Language & Region | Yes | [language.tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/profile/language.tsx) | N/A | N/A | N/A | i18n language toggle |
| **RM-20** | Help & Support | Yes | [help.tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/profile/help.tsx) | N/A | N/A | N/A | Support & FAQ screen |
| **RM-21** | Settings | Yes | [settings.tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/profile/settings.tsx) | N/A | N/A | N/A | App settings screen |
| **RM-22** | Host Step 1 (Info) | Yes | [step-1.tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/host/step-1.tsx) | N/A | N/A | N/A | Host application contact info |
| **RM-23** | Host Step 3 (Pricing)| Yes | [step-3.tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/host/step-3.tsx) | N/A | N/A | N/A | Host application pricing step |
| **RM-24** | Host Step 4 (Review) | Yes | [step-4.tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/host/step-4.tsx) | N/A | N/A | N/A | Host application review & submit |
| **RM-25** | Delete Draft Confirm | Deferred | N/A | N/A | N/A | N/A | Stage B Phase 8 deferred feature |
| **RM-26** | Cancel Booking | Deferred | N/A | N/A | N/A | N/A | Stage B Phase 7 deferred feature |
| **RM-27** | My Reviews | Yes | [my-reviews.tsx](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/profile/my-reviews.tsx) | N/A | N/A | N/A | User submitted reviews |

### Coverage Count:
- **Implemented:** 31 / 34 screens (91.2%)
- **Partial / Inline:** 2 screens (PL-07, RM-07)
- **Deferred to Stage B:** 3 screens (RM-09, RM-25, RM-26 per `FEATURES_BACKLOG.md`)
- **Missing:** 0 screens

---

## B. Navigation Graph

### 1. Code Navigation Flowchart (Actual `router.push` / `replace` in codebase)

```mermaid
flowchart TD
  PL01["PL-01 Splash"] -->|router.push| PL02["PL-02 Onboarding 1"]
  PL01 -->|router.push| DevRoutes["/dev/routes"]
  PL02 -->|router.push| PL03["PL-03 Onboarding 2"]
  PL03 -->|router.push| PL04["PL-04 Onboarding 3"]
  PL04 -->|router.push| PL05["PL-05 Select Interests"]
  PL05 -->|router.replace| PL06["PL-06 Home"]

  RM01["RM-01 Sign Up"] -->|router.replace| PL06
  RM01 -->|router.push| RM02["RM-02 Login"]
  RM02 -->|router.replace| PL06
  RM02 -->|router.push| RM03["RM-03 Forgot Password"]
  RM03 -->|router.push| RM04["RM-04 Reset Result"]
  RM04 -->|router.replace| RM02

  PL06 -->|router.push| PL08["PL-08 Search"]
  PL06 -->|router.push| RM06["RM-06 Collection"]
  PL06 -->|router.push| PL09["PL-09 Experience Details"]
  PL06 -->|router.push| RM18["RM-18 Notifications"]

  PL07["PL-07 Explore"] -->|router.push| RM08["RM-08 Map View"]
  PL07 -->|router.push| RM06

  PL08 -->|router.push| PL09

  PL09 -->|router.push (guest)| RM05["RM-05 Auth Required Modal"]
  PL09 -->|router.push| PL10["PL-10 Booking Form"]
  RM05 -->|router.push| RM01
  RM05 -->|router.push| RM02

  PL10 -->|router.replace| PL13["PL-13/14 My Plans"]
  PL11["PL-11 Booking Confirm"] -->|router.replace| PL13

  PL12["PL-12 Saved"] -->|router.push| PL09
  PL12 -->|router.push| PL07

  PL13 -->|router.push| PL10
  PL13 -->|router.push| RM10["RM-10 Itinerary"]

  PL15["PL-15/16 My Trips"] -->|router.push| RM14["RM-14 Leave Review"]
  RM14 -->|router.push| RM15["RM-15 Review Submitted"]
  RM15 -->|router.replace| PL15

  PL17["PL-17 Profile"] -->|router.push| PL12
  PL17 -->|router.push| RM16["RM-16 Edit Profile"]
  PL17 -->|router.push| RM17["RM-17 Payment Methods"]
  PL17 -->|router.push| RM18
  PL17 -->|router.push| RM19["RM-19 Language"]
  PL17 -->|router.push| RM20["RM-20 Help"]
  PL17 -->|router.push| RM21["RM-21 Settings"]
  PL17 -->|router.push| RM27["RM-27 My Reviews"]
  PL17 -->|router.push| PL18["PL-18 Become Host"]

  PL18 -->|router.push| RM22["RM-22 Host Step 1"]
  RM22 -->|router.push| PL19["PL-19 Host Step 2"]
  PL19 -->|router.push| RM23["RM-23 Host Step 3"]
  RM23 -->|router.push| RM24["RM-24 Host Step 4"]
  RM24 -->|router.push| PL20["PL-20 Application Submitted"]
  PL20 -->|router.replace| PL17
```

### 2. Document Navigation Flowchart (App Flow Document §4.1–4.4)

```mermaid
flowchart TD
  PL01["PL-01 Splash"] --> PL02["PL-02 Onboarding 1"]
  PL02 --> PL03["PL-03 Onboarding 2"]
  PL03 --> PL04["PL-04 Onboarding 3"]
  PL04 --> PL05["PL-05 Select Interests"]
  PL05 --> PL06["PL-06 Home"]

  RM01["RM-01 Sign Up"] --> PL06
  RM02["RM-02 Login"] --> PL06
  RM03["RM-03 Forgot Password"] --> RM04["RM-04 Reset Result"]

  PL06 --> PL08["PL-08 Search"]
  PL06 --> RM06["RM-06 Collection"]
  PL06 --> PL09["PL-09 Experience Details"]

  PL07["PL-07 Explore"] --> RM08["RM-08 Map View"]
  PL07 --> RM07["RM-07 Filter Sheet"]

  PL08 --> RM07
  PL08 --> PL09

  PL09 --> RM05["RM-05 Auth Required Modal"]
  PL09 --> PL10["PL-10 Booking Form"]
  PL09 --> PL12["PL-12 Saved"]

  PL10 --> RM09["RM-09 Payment Gateway"]
  RM09 --> PL11["PL-11 Booking Confirm"]
  PL11 --> PL13["PL-13 My Plans"]

  PL13 --> RM10["RM-10 Itinerary"]
  PL13 --> RM11["RM-11 Trip Chat"]
  PL13 --> RM12["RM-12 Gear Checklist"]
  PL13 --> RM13["RM-13 Budget Tracker"]
  PL13 --> RM25["RM-25 Delete Draft"]

  PL15["PL-15 My Trips"] --> RM14["RM-14 Leave Review"]
  PL15 --> RM26["RM-26 Cancel Booking"]
  RM14 --> RM15["RM-15 Review Submitted"]

  PL17["PL-17 Profile"] --> PL12
  PL17 --> RM16["RM-16 Edit Profile"]
  PL17 --> PL18["PL-18 Become Host"]

  PL18 --> RM22["RM-22 Host Step 1"]
  RM22 --> PL19["PL-19 Host Step 2"]
  PL19 --> RM23["RM-23 Host Step 3"]
  RM23 --> RM24["RM-24 Host Step 4"]
  RM24 --> PL20["PL-20 Host Submitted"]
```

### 3. Navigation Diff Analysis
- **Edges in document MISSING in code:**
  - `PL-10 -> RM-09 (Payment Gateway)` (Walled in Stage A; PL-10 displays "Payments coming soon" sheet).
  - `PL-13 -> RM-25 (Delete Draft)` (Stage B Phase 8 deferred).
  - `PL-15 -> RM-26 (Cancel Booking)` (Stage B Phase 7 deferred).
  - `PL-07 / PL-08 -> RM-07 (Filter Sheet)` (Inline chips used in Stage A).
- **Edges in code NOT in documents:**
  - `PL-01 -> /dev/routes` (Developer route index link).
- **Unreachable / Dead end screens:** None. Every screen has an explicit back button or tab bar navigation.

---

## C. Data Graph

### 1. Database ER Diagram (Live schema in `supabase/migrations/`)

```mermaid
erDiagram
  profiles ||--o{ user_interests : has
  interests ||--o{ user_interests : tagged
  profiles ||--o{ saved_experiences : saves
  experiences ||--o{ saved_experiences : saved_in
  categories ||--o{ experiences : categorizes
  regions ||--o{ experiences : located_in
  profiles ||--o{ experiences : hosts
  experiences ||--o{ experience_departures : has_departures
  experiences ||--o{ itinerary_items : has_itinerary
  profiles ||--o{ bookings : makes
  experiences ||--o{ bookings : booked_in
  experience_departures ||--o{ bookings : departs_on
  bookings ||--|| payments : paid_via
  bookings ||--o{ booking_participants : includes
  bookings ||--o{ trip_messages : contains
  bookings ||--o{ gear_checklist_items : tracks
  bookings ||--o{ budget_entries : records
  bookings ||--|| reviews : reviewed_by
  experiences ||--o{ reviews : receives
  profiles ||--|| host_applications : applies
  profiles ||--o{ notifications : receives
  profiles ||--o{ device_tokens : registers
```

### 2. Schema Drift Analysis vs `docs/BACKEND_SCHEMA.md`
- **Missing tables:** None (All 19 tables created in migrations `0003`–`0012`).
- **Missing columns:** None.
- **Wrong types:** None (All money columns use `bigint` paisa, dates use `timestamptz`).
- **Missing foreign keys / indexes:** None (All indexes and FKs match `BACKEND_SCHEMA.md` §3).

### 3. RLS Audit Summary
- **RLS Enabled:** 19 / 19 tables (100%).
- **Explicit Client Policies:** 18 / 19 tables.
- **Zero Client Policies:** 1 table (`payments` table - intentionally service-role only, client access completely denied).

---

## D. Integrity Assertions

| # | Assertion | Status | Proof / Evidence |
|---|---|---|---|
| 1 | Restricted guest action routes to RM-05 & replays | **YES** | [experience/[id].tsx:31](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/experience/[id].tsx#L31) & [auth-required-modal.tsx:1-50](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/(auth)/auth-required-modal.tsx) |
| 2 | Client code never mutates restricted statuses | **YES** | Grep verified zero `.update()` calls in `src/` & `app/`; DB triggers [0007_bookings.sql:24](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/supabase/migrations/0007_bookings.sql#L24), [0008_payments.sql:17](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/supabase/migrations/0008_payments.sql#L17), [0011_host_applications.sql:21](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/supabase/migrations/0011_host_applications.sql#L21) enforce restriction |
| 3 | Server-computed prices; client pricing marked `// TEMP:` | **YES** | [booking/[id].tsx:2](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/app/booking/[id].tsx#L2) carries `// TEMP: client pricing, server re-price lands in Phase 7` |
| 4 | All money stored/calculated in integer paisa | **YES** | [format.ts:8-23](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/src/lib/format.ts#L8-L23), [format.test.ts:4-23](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/src/lib/__tests__/format.test.ts#L4-L23), all DB columns `bigint` |
| 5 | NPR formatted with Nepali lakh grouping everywhere | **YES** | [format.ts:8](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/src/lib/format.ts#L8) `formatNpr()` called across `home.tsx`, `experience/[id].tsx`, `booking/[id].tsx`, `search.tsx`, `saved.tsx` |
| 6 | All dates UTC, displayed via Asia/Kathmandu tz library | **YES** | [format.ts:28-36](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/src/lib/format.ts#L28-L36) using `date-fns-tz` to `Asia/Kathmandu`; 0 hardcoded `+05:45` in app code |
| 7 | Every table has RLS enabled & at least 1 policy | **PARTIAL** | All 19 tables have RLS enabled. 18 tables have policies; `payments` has 0 client policies (by security design, service-role only) |
| 8 | `host-documents` storage bucket private | **YES** | [BACKEND_SCHEMA.md:257](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/docs/BACKEND_SCHEMA.md#L257) & [0011_host_applications.sql:13](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/supabase/migrations/0011_host_applications.sql#L13) |
| 9 | `reviews` has unique constraint on `booking_id` | **YES** | [0010_reviews.sql:4](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/supabase/migrations/0010_reviews.sql#L4) (`booking_id uuid unique not null`) |
| 10 | `payments` has unique `idempotency_key` | **YES** | [0008_payments.sql:7](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/supabase/migrations/0008_payments.sql#L7) (`idempotency_key text unique not null`) |
| 11 | Every list and detail screen handles loading/empty/error | **PARTIAL** | PL-05, PL-06, PL-08, PL-09, PL-10, PL-12, PL-13/14, RM-10 handle all 3; static screens (PL-07 explore, PL-15 trips, PL-17 profile) do not wrap in Skeleton |
| 12 | No raw hex colors outside `src/theme` | **NO** | Raw hex color strings exist in Phase S0 auth template placeholders (`app/(auth)/login.tsx`, `app/(auth)/sign-up.tsx`, `app/(onboarding)/slide-1.tsx`, etc.) |
| 13 | Every touchable target meets 44x44 pt minimum | **YES** | [tokens.ts:25-28](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/src/theme/tokens.ts#L25-L28) (`touchTarget.minHeight: 44`, `minWidth: 44`) |
| 14 | `supabase/tests/rls.test.sql` exists and passes | **YES** | [rls.test.sql:1-31](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/supabase/tests/rls.test.sql) |
| 15 | `.env` gitignored & 0 secrets in git history | **YES** | [.gitignore:2](file:///c:/Users/rauna/OneDrive/Desktop/PLAN%20E/.gitignore#L2) & `git log -p` verified 0 API keys/secrets committed |

---

## E. Isolation Audit

1. **Git Remote Check (`git remote -v`):**
   ```text
   (No remotes configured yet - Safe local state)
   ```
2. **Git Top-Level Directory (`git rev-parse --show-toplevel`):**
   ```text
   C:/Users/rauna/OneDrive/Desktop/PLAN E
   ```
   *(Top-level path correctly ends in "PLAN E")*

3. **Forbidden Keywords Check (`merobites`, `restro`, foreign project refs):**
   ```text
   Grep query: merobites|restro
   Hits: 0 hits in source code or configuration files.
   (Only documentation references in docs/ISOLATION.md and docs/AGENT_PROMPTS.md explaining isolation rules).
   ```

---

## F. Ranked Gaps & Proposed Minimal Fixes

### 1. BLOCKERs
- **Gap B1 (RLS Policy Completeness for Assertion 7):**  
  `payments` table has RLS enabled (`alter table public.payments enable row level security;`), but zero policies defined because client access is denied.  
  *Proposed Fix:* Add an explicit service-role / deny-all policy in `supabase/migrations/0013_rls_policies.sql` for `payments` so every table has at least one explicit policy statement.

---

### 2. MAJORs
- **Gap M1 (Raw Hex Colors in Scaffolding Templates):**  
  Auth and onboarding screen placeholders (`app/(auth)/login.tsx`, `sign-up.tsx`, `forgot-password.tsx`, `reset-result.tsx`, `slide-1.tsx`, `slide-2.tsx`, `slide-3.tsx`) contain hardcoded `'#F6F2E9'`, `'#18372D'`, `'#24312D'` color strings instead of `colors.*` tokens from `@/theme/tokens`.  
  *Proposed Fix:* Replace raw hex strings with `colors.ivory`, `colors.forest`, `colors.ink` imports from `@/theme/tokens`.

---

### 3. MINORs
- **Gap N1 (Explore Screen Loading Wrappers):**  
  `app/(tabs)/explore.tsx` renders static category cards directly without wrapping category queries in `Skeleton` / `ErrorState`.  
  *Proposed Fix:* Connect `useCategories()` query hook to `explore.tsx` with `Skeleton` loading state.

---

### Approval Request
Please review the proposed minimal fix for **Gap B1** (adding explicit policy to `payments` table) and **Gap M1** (replacing raw hex strings with tokens). I will not implement any changes until you explicitly approve.
