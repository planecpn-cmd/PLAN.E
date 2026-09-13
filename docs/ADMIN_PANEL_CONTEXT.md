# ADMIN_PANEL_CONTEXT

Sole input for an admin-panel architecture plan. Everything here is drawn from the
repository as it stands at commit `f54bfec` (branch `main`). No application code was
written to produce this document. Where a thing does not exist in the codebase it is
marked **NOT PRESENT** rather than described aspirationally.

The live/production database could **not** be queried (see §8), so schema facts come
from `supabase/migrations/` (the source of truth per the repo's own README) and are
cross-checked against `supabase/dumps/schema_public.sql` (a reference snapshot that is
stale — it predates roughly the 2026‑08‑16 migrations onward).

---

## 1. Stack & Deployment

### 1.1 Flutter app (repository root)

- **Flutter/Dart version:** not pinned to an exact Flutter version. `pubspec.yaml`
  declares `environment: sdk: ^3.12.0` (Dart 3.12+, i.e. a recent Flutter 3.3x
  channel). `.metadata` exists but no `fvm`/`flutter --version` pin is committed.
  App version `1.0.0+1`.
- **State management:** `flutter_riverpod ^2.6.1`. Providers live in
  `lib/providers/` and per-feature `*_providers.dart` / `*_provider.dart` files
  (`Provider`, `FutureProvider`, `StreamProvider`, `StateProvider`,
  `StateNotifierProvider`).
- **Routing:** `go_router ^14.8.0`, single `GoRouter` in `lib/router.dart`.
- **Other notable deps:** `supabase_flutter ^2.8.3`, `google_sign_in ^6.2.1`,
  `firebase_core ^4.12.1` + `firebase_messaging ^16.4.3` (push), `webview_flutter`
  (payment gateway WebView), `flutter_map` + `latlong2` + `geolocator` +
  `geocoding` (maps), `image_picker` + `file_picker` (host document upload),
  `flutter_markdown` (legal docs), `shared_preferences`, `connectivity_plus`,
  `cached_network_image`.
- **`lib/` folder structure:**
  - `lib/main.dart` — entry point; `lib/router.dart` — all routes.
  - `lib/core/` — cross-cutting services: `supabase_client.dart`,
    `push_notification_service.dart`, `remote_config_service.dart`,
    `feature_flag_evaluation.dart`, `offline_cache.dart`, `message_outbox.dart`,
    `trip_presence_controller.dart`, `device_identity.dart`, `app_version.dart`,
    `chat_ordering.dart`, `experience_presentation.dart`, `format.dart`,
    `image_url.dart`, `onboarding_preferences.dart`, etc.
  - `lib/features/<feature>/` — `ai_itinerary`, `auth`, `booking`, `dev`,
    `experience`, `explore`, `home`, `host`, `legal`, `notifications`,
    `onboarding`, `plans`, `profile`, `saved`, `search`, `trips`.
    `host/` is further split into `data/`, `domain/`, `presentation/`,
    `presentation/widgets/`.
  - `lib/models/` — plain data classes (`booking.dart`, `experience.dart`,
    `host_application.dart`, `profile.dart`, `legal_document.dart`, …).
  - `lib/providers/` — `app_providers.dart`, `legal_providers.dart`,
    `remote_config_providers.dart`, `trip_tools_providers.dart`.
  - `lib/repositories/` — one repository per domain
    (`booking_repository.dart`, `host_repository.dart`, `profile_repository.dart`,
    `trip_chat_repository.dart`, `experience_repository.dart`, …).
  - `lib/theme/`, `lib/widgets/`, `lib/l10n/` (en + ne).
- **Platform targets present:** `android/`, `ios/`, `windows/`, `web/` (the Flutter
  web build target — standard scaffolding, not a separate app).

### 1.2 Supabase project

- **`supabase/` directory:** yes.
  - **`supabase/config.toml`** — `project_id = "PLAN_E"`, Postgres
    `major_version = 17`. Linked hosted project ref `dtebgbrqynxahuzmbtbc`
    (`supabase/.temp/project-ref`, name "Plan.E").
  - **Migrations:** `supabase/migrations/` — **59 files**. Two naming eras:
    `0001_*.sql` … `0022_*.sql` (unprefixed, initial build) then timestamped
    `20260813090000_*.sql` … `20260906140000_*.sql`. `[db.migrations] enabled = true`.
  - **Edge functions:** `supabase/functions/` — 11 functions:
    `complete-trips-cron`, `create-booking-intent`, `esewa-redirect`,
    `generate-itinerary`, `initiate-payment`, `payment-return`, `payment-webhook`,
    `search-experiences`, `submit-host-application`, `trip-message-push`,
    `verify-payment-return`. Plus `supabase/functions/_shared/`
    (`auth.ts`, `payment_provider.ts`, `payment_redirect_token.ts`,
    `rate_limit.ts`) and `.env.example`.
    `config.toml` sets `verify_jwt = false` for `esewa-redirect`,
    `payment-return`, `verify-payment-return`, `complete-trips-cron`,
    `trip-message-push` (these authenticate by other means — one-time token,
    `X-Cron-Secret`, Vault webhook secret — or are pure redirects).
  - **Seed files:** `supabase/seed.sql` (817 lines; `[db.seed] sql_paths =
    ["./seed.sql"]`) — 30 experiences + taxonomy. Additional seeding lives in
    migrations: `0018_seed_experience_departures.sql` (90 departures),
    `0020_seed_itinerary_items.sql` (210 rows), `0015_seed_dev.sql` (placeholder),
    `20260813111000_seed_ram_shrestha_demo_host.sql` +
    `20260813113000_complete_ram_shrestha_demo_bookings.sql` (one demo host and
    its bookings — dev only), plus catalog photo reference updates
    (`20260904091000`).
  - **Dumps:** `supabase/dumps/schema_public.sql` and `data_catalog.sql`
    ("reference artifacts, not the source of truth"). `supabase/full_schema_bundle.sql`
    is a stale concatenation of migrations 0001–0020 only.
  - **Legal:** `supabase/legal/` — 13 markdown legal documents + build prompt +
    `placeholders.json` (loaded into the `legal_documents` table).
  - **Tests:** `supabase/tests/` — `rls.test.sql`, `payment_finalization.test.sql`,
    `profile_privacy.test.sql`, `edge_idor.test.mjs`, several
    `trip_message_*_rls.test.sql`, `external_api_rate_limits.test.sql`.

### 1.3 Client initialisation & keys

- **Flutter:** `lib/core/supabase_client.dart` → `AppSupabaseClient.initialize()`:
  ```dart
  const url = String.fromEnvironment('SUPABASE_URL');
  const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  await Supabase.initialize(url: url, publishableKey: anonKey,
      authOptions: FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce));
  ```
  Values are passed with `--dart-define` at build/run time
  (`docs/SUPABASE_HOSTED_SETUP.md` §4). Local dev values sit in `env/local.json`
  (git-ignored; contains `http://192.168.100.5:54341` and a
  `sb_publishable_…` key). `env/local.json.example` carries an explicit warning:
  *"Never include SUPABASE_SERVICE_ROLE_KEY or any administrative secret in this
  file. Client app assets are public."* Auth deep-link scheme: `planee://login-callback`.
- **Next.js webapp:** `webapp/src/lib/supabase/client.ts` (browser) and
  `server.ts` (SSR) both use `createBrowserClient` / `createServerClient` from
  `@supabase/ssr` with `NEXT_PUBLIC_SUPABASE_URL` / `NEXT_PUBLIC_SUPABASE_ANON_KEY`.
  `webapp/src/proxy.ts` (Next 16's renamed middleware) refreshes the auth cookie
  on every request.
- **Service-role key:** used **only server-side, inside edge functions**, via
  `Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")`:
  - `_shared/auth.ts` builds an `adminClient` (service role) alongside the
    user-scoped client for `requireAuthenticatedUser`-based functions.
  - `verify-payment-return`, `esewa-redirect`, `complete-trips-cron` create a
    service-role client directly (no user session on those paths).
  - **The service-role key is NOT referenced anywhere in `lib/` or `webapp/`.**
    No committed file contains a service-role key. `.gitignore` excludes `.env`,
    `.env.*` (except `*.example`), `supabase/functions/.env`, and `env/*.json`.
    Confirmed: no env file with real secrets is tracked.

### 1.4 Web build target / separate web app

- **`webapp/`** — a **separate Next.js 16.3.4 application** (React 19.2, App
  Router, Tailwind 4, `@supabase/ssr`, `react-markdown`, `react-leaflet`). It is
  a read/write client against the **same hosted Supabase project** as the Flutter
  app (`webapp/src/lib/supabase/database.types.ts` is hand-authored, "Phase 1
  tables only", comment: *"Do not run migrations or alter this schema from the web
  app"*). Routes include `/host`, `/host/application`, `/host/status`, `/legal/*`,
  `/booking/*`, `/experience/*`, `/explore`, `/plans`, `/profile`, `/auth/*`.
- **`web/`** at repo root — the standard Flutter web output scaffold, not a
  distinct product.

### 1.5 Hosting / CI

- **webapp:** Cloudflare Workers via `@opennextjs/cloudflare` + `wrangler`.
  `webapp/wrangler.jsonc`: worker name `plan-e`, custom domains
  `planenepal.com` and `www.planenepal.com`, `compatibility_flags:
  ["nodejs_compat", "global_fetch_strictly_public"]`. Deploy command
  `pnpm deploy` = `opennextjs-cloudflare build && opennextjs-cloudflare deploy`.
  (Also documented in `memory/cloudflare-webapp-deploy.md`.)
- **Supabase:** manual per `docs/SUPABASE_HOSTED_SETUP.md` — `supabase link`,
  `supabase db push --linked`, `supabase functions deploy`,
  `supabase secrets set --env-file …`.
- **CI:** **NOT PRESENT.** No `.github/`, no CI config of any kind in the repo.
- **Scheduled jobs:** `complete-trips-cron` and `expire-stale-bookings-cron`
  (P3 — flips `pending` bookings past `quote_expires_at` to `expired` via
  `expire_stale_pending_bookings()`) each expect to be POSTed by an external
  scheduler with their own `X-Cron-Secret` header. No scheduler definition
  (`pg_cron`, GitHub cron, Cloudflare cron) is committed for either.
- **Payment redirect base URL:** `PUBLIC_SUPABASE_URL` env var; web returns land
  on `https://planenepal.com/booking/confirmation/<id>` (hard-coded `WEB_ORIGIN`
  in `verify-payment-return/index.ts`).

---

## 2. Full Database Schema

RLS is covered in §3; this section is structure only. Money is stored as `bigint`
**paisa** throughout (`currency` fixed to `'NPR'`). All `id` PKs are
`uuid default gen_random_uuid()` unless stated. Every table has RLS enabled (an
event trigger `rls_auto_enable` auto-enables RLS on any new `public` table — see §3).

### 2.1 Enums (`supabase/migrations/0002_enums.sql`, later altered)

```sql
create type user_role         as enum ('traveler','host_applicant','host','admin');
create type difficulty_level  as enum ('easy','moderate','challenging','strenuous');
create type experience_status as enum ('draft','pending_review','published','paused','archived');
create type booking_status    as enum ('pending','confirmed','cancellation_requested','cancelled','completed','expired');
create type payment_status    as enum ('initiated','paid','failed','refunded');
create type payment_provider  as enum ('khalti','esewa');
create type host_app_status   as enum ('draft','submitted','under_review','verification','approved','rejected');
create type trip_role         as enum ('traveler','host');   -- defined, not used by any table
create type notif_type        as enum ('booking','chat','host_application','system','promo');
```
Later: `20260906115900_host_action_required_status.sql` →
`alter type public.host_app_status add value if not exists 'action_required';`
(effective values: draft, submitted, under_review, verification, action_required,
approved, rejected).

### 2.2 `profiles` (`0003_profiles_trigger.sql`)

```sql
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text unique,
  avatar_url text,
  location text,
  bio text,
  role user_role not null default 'traveler',
  language text default 'en' check (language in ('en','ne')),
  points int not null default 0,
  onboarding_complete boolean default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
```
- Row auto-created by trigger `on_auth_user_created` → `handle_new_user()` (SECURITY
  DEFINER) on `auth.users` insert. `updated_at` maintained by `set_profiles_updated_at`.
- `role` mutation blocked for non-service callers by trigger
  `check_profile_role_update` → `prevent_profile_role_escalation()`.
- No `email` column (email lives only in `auth.users`). No `deleted_at`.

### 2.3 Taxonomy (`0004_taxonomy.sql`, + `20260821090000_experience_families.sql`)

```sql
create table public.interests (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null, name_en text not null, name_ne text not null,
  icon text, sort_order int default 0,
  created_at timestamptz not null default now()
);

create table public.user_interests (
  user_id uuid references public.profiles(id) on delete cascade,
  interest_id uuid references public.interests(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, interest_id)
);

create table public.regions (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null, name_en text not null, name_ne text not null,
  cover_image_url text, description text, sort_order int default 0,
  created_at timestamptz not null default now()
);

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null, name_en text not null, name_ne text not null,
  icon text, cover_image_url text, sort_order int default 0,
  created_at timestamptz not null default now()
  -- ALTER (20260821090000): add family_id uuid references public.experience_families(id) on delete restrict
);

-- 20260821090000_experience_families.sql
create table public.experience_families (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null, name_en text not null, name_ne text not null,
  description text, icon text, cover_image_url text,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

create table public.tags (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null, name_en text not null, name_ne text not null,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

create table public.experience_tags (
  experience_id uuid not null references public.experiences(id) on delete cascade,
  tag_id uuid not null references public.tags(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (experience_id, tag_id)
);
```

### 2.4 `experiences` (`0005_experiences.sql`, + constraint alters)

```sql
create table public.experiences (
  id uuid primary key default gen_random_uuid(),
  host_id uuid references public.profiles(id) on delete set null,
  category_id uuid references public.categories(id) on delete restrict,
  region_id uuid references public.regions(id) on delete restrict,
  title text not null,
  slug text unique not null,
  summary text,
  description text,
  cover_image_url text not null,
  gallery text[] default '{}',
  location_name text,
  meeting_point text,
  lat double precision,
  lng double precision,
  duration_hours int not null default 24,
  difficulty difficulty_level not null default 'moderate',
  max_altitude_m int,
  group_size_min int default 1,
  group_size_max int default 12,
  min_age int default 10,
  price_paisa bigint not null check (price_paisa >= 0),
  child_price_paisa bigint check (child_price_paisa is null or child_price_paisa >= 0),
  currency text not null default 'NPR' check (currency = 'NPR'),
  included text[] default '{}',
  bring_list text[] default '{}',
  things_to_know text[] default '{}',
  permits_required text[] default '{}',
  best_season int[] default '{3,4,5,9,10,11}',
  rating_avg numeric(2,1) default 0.0 check (rating_avg >= 0 and rating_avg <= 5.0),
  rating_count int default 0 check (rating_count >= 0),
  status experience_status default 'draft',
  search_tsv tsvector,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
-- ALTER (20260823140000): add check price_paisa <= 10000000000,
--   check child_price_paisa is null or child_price_paisa <= 10000000000
```
- `search_tsv` is **trigger-maintained** (not a `GENERATED` column) by
  `experiences_search_tsv_trigger` → `experiences_update_search_tsv()` from
  title/summary/location_name.
- `rating_avg` / `rating_count` are **trigger-maintained** by `on_review_change`
  → `update_experience_rating_stats()` (SECURITY DEFINER).
- Indexes: `idx_experiences_status_region`, `idx_experiences_status_category`,
  `idx_experiences_status_price`, `idx_experiences_status_difficulty`,
  `idx_experiences_search_tsv` (gin), `idx_experiences_rating` (rating_avg desc).
- `host_id` is nullable and is `NULL` for every seeded experience.

### 2.5 `experience_departures` (`0005_experiences.sql`)

```sql
create table public.experience_departures (
  id uuid primary key default gen_random_uuid(),
  experience_id uuid not null references public.experiences(id) on delete cascade,
  start_date date not null,
  end_date date not null,
  total_spots int not null check (total_spots > 0),
  spots_left int not null check (spots_left >= 0),
  price_override_paisa bigint check (price_override_paisa is null or price_override_paisa >= 0),
  status text default 'open',
  created_at timestamptz not null default now(),
  constraint unique_experience_start_date unique (experience_id, start_date)
);
-- ALTER (20260823140000): add check price_override_paisa is null or price_override_paisa <= 10000000000
-- index idx_departures_exp_date on (experience_id, start_date) where status = 'open'
```
`status` is free `text` (values seen: `'open'`), not an enum.

### 2.6 `itinerary_items` (`0005_experiences.sql`)

```sql
create table public.itinerary_items (
  id uuid primary key default gen_random_uuid(),
  experience_id uuid not null references public.experiences(id) on delete cascade,
  day_number int not null check (day_number > 0),
  start_time time,
  title text not null,
  description text,
  sort_order int default 0,
  created_at timestamptz not null default now()
);
-- index idx_itinerary_exp_day on (experience_id, day_number)
```

### 2.7 `saved_experiences` (`0006_saved.sql`)

```sql
create table public.saved_experiences (
  user_id uuid references public.profiles(id) on delete cascade,
  experience_id uuid references public.experiences(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, experience_id)
);
```

### 2.8 `bookings` (`0007_bookings.sql`, + constraint alters)

```sql
create table public.bookings (
  id uuid primary key default gen_random_uuid(),
  booking_ref text unique not null,
  user_id uuid not null references public.profiles(id) on delete cascade,
  experience_id uuid not null references public.experiences(id) on delete restrict,
  departure_id uuid not null references public.experience_departures(id) on delete restrict,
  adults int not null check (adults >= 1),
  children int not null default 0 check (children >= 0),
  addons jsonb default '[]'::jsonb,
  contact_name text not null,
  contact_phone text not null,
  subtotal_paisa bigint not null check (subtotal_paisa >= 0),
  addons_paisa bigint not null default 0 check (addons_paisa >= 0),
  fees_paisa bigint not null default 0 check (fees_paisa >= 0),
  total_paisa bigint not null check (total_paisa >= 0),
  status booking_status not null default 'pending',
  quote_expires_at timestamptz,
  is_draft boolean default false,
  cancelled_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
-- ALTER (20260823140000): add
--   check subtotal_paisa <= 210000000000, check addons_paisa <= 210000000000,
--   check fees_paisa <= 210000000000, check total_paisa <= 210000000000,
--   check total_paisa = subtotal_paisa + addons_paisa + fees_paisa
```
- `updated_at` via `set_bookings_updated_at`. `status` change blocked for
  non-service callers by `check_booking_status_update` →
  `prevent_client_booking_status_change()`.
- Indexes: `idx_bookings_user_status (user_id, status)`,
  `idx_bookings_departure (departure_id)`,
  `idx_bookings_quote_expiry (status, quote_expires_at) where status = 'pending'`.
- Only buyer identity fields are `contact_name`, `contact_phone`. No email,
  address, PAN, nationality.
- Trigger `shadow_trip_conversation_after_booking_insert` fires on insert (see §2.19).

### 2.9 `booking_participants` (`0007_bookings.sql`)

```sql
create table public.booking_participants (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  full_name text not null,
  age int,
  is_lead boolean default false,
  created_at timestamptz not null default now()
);
-- index idx_participants_booking on (booking_id)
```

### 2.10 `payments` (`0008_payments.sql`, + constraint alter)

```sql
create table public.payments (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid unique not null references public.bookings(id) on delete cascade,
  provider payment_provider not null,
  provider_ref text,
  idempotency_key text unique not null,
  amount_paisa bigint not null check (amount_paisa > 0),
  status payment_status not null default 'initiated',
  raw_response jsonb default '{}'::jsonb,
  paid_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
-- ALTER (20260823140000): add check amount_paisa <= 210000000000
-- ALTER (20260823080000): create unique index idx_payments_provider_ref_unique
--   on (provider, provider_ref) where provider_ref is not null
```
- One payment per booking (`booking_id` unique).
- **All** insert/update/delete blocked for non-service callers by trigger
  `check_payment_mutation` → `prevent_client_payment_mutation()`.
- `updated_at` via `set_payments_updated_at`.
- No index on `status`, `provider`, `created_at`, `paid_at`.

### 2.11 `trip_messages` (`0009_trip_tools.sql`, + `client_message_id` alter)

```sql
create table public.trip_messages (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  body text not null,
  attachment_url text,
  created_at timestamptz not null default now()
  -- ALTER (20260816100000): add column client_message_id uuid,
  --   add constraint trip_messages_client_message_id_key unique (client_message_id)
);
-- index idx_trip_messages_booking on (booking_id, created_at desc)
```
Rows are immutable — edits/deletes recorded in side tables (§2.19). In
`supabase_realtime` publication.

### 2.12 `gear_checklist_items` (`0009_trip_tools.sql`)

```sql
create table public.gear_checklist_items (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  label text not null,
  is_checked boolean not null default false,
  is_custom boolean not null default false,
  sort_order int default 0,
  created_at timestamptz not null default now()
);
-- index idx_gear_items_booking on (booking_id)
```

### 2.13 `budget_entries` (`0009_trip_tools.sql`)

```sql
create table public.budget_entries (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  label text not null,
  amount_paisa bigint not null check (amount_paisa >= 0),
  category text,
  spent_on date default current_date,
  created_at timestamptz not null default now()
);
-- index idx_budget_entries_booking on (booking_id)
```

### 2.14 `reviews` (`0010_reviews.sql`)

```sql
create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid unique not null references public.bookings(id) on delete cascade,
  experience_id uuid not null references public.experiences(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  rating int not null check (rating >= 1 and rating <= 5),
  title text,
  body text,
  photos text[] default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
```
`updated_at` via `set_reviews_updated_at`. `on_review_change` recomputes
`experiences.rating_avg` / `rating_count`. One review per booking. No index on
`experience_id` alone / `created_at` / `rating`.

### 2.15 `host_applications` (`0011_host_applications.sql`, + alters)

```sql
create table public.host_applications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique not null references public.profiles(id) on delete cascade,
  status host_app_status not null default 'draft',
  current_step int not null default 1 check (current_step >= 1 and current_step <= 4),
  category_id uuid references public.categories(id) on delete set null,
  title text,
  description text,
  location text,
  photos text[] default '{}',
  verification_doc_path text,
  submitted_at timestamptz,
  reviewed_at timestamptz,
  reviewer_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
  -- ALTER (20260906120000):
  --   drop constraint host_applications_current_step_check;
  --   add constraint host_applications_current_step_check check (current_step between 1 and 8);
  --   add column application_data jsonb not null default '{}'::jsonb;
);
```
- **One application per user** (`user_id` unique).
- `application_data` holds the full canonical v1 questionnaire payload shared by
  both clients (see `docs/HOST_APPLICATION_CONTRACT.md` and §4).
- `status` change blocked for non-service callers by `check_host_app_status_update`
  → `prevent_client_host_app_status_change()`.
- `updated_at` via `set_host_apps_updated_at`.
- Trigger `sync_host_account_after_application_review` (see §2.17, §3, §4).
- Only PK + `unique(user_id)` — **no index on `status`, `submitted_at`,
  `category_id`, `created_at`**.

### 2.16 `notifications` & `device_tokens` (`0012_notifications.sql`)

```sql
create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  type notif_type not null default 'system',
  title text not null,
  body text not null,
  entity_id uuid,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);
-- index idx_notifications_user on (user_id, is_read, created_at desc)

create table public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  expo_push_token text unique not null,
  platform text,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);
-- index idx_device_tokens_user on (user_id)
```
- `notifications` is written **only** by the Flutter client-side repository
  (`lib/repositories/notification_repository.dart` reads; the only inserts in the
  repo are in `supabase/tests/rls.test.sql`). No server code inserts notification
  rows. `notif_type` value `host_application` is never produced.
- `device_tokens` is the **legacy** Expo push table — superseded by
  `trip_push_device_tokens` (§2.19). `20260823100000` intentionally grants it no
  anon/authenticated access, so it is effectively dead.

### 2.17 `host_accounts` (`20260813090000_secure_host_access.sql`)

```sql
create table public.host_accounts (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  application_id uuid not null unique references public.host_applications(id) on delete restrict,
  is_active boolean not null default true,
  approved_at timestamptz not null default now(),
  suspended_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint host_accounts_suspension_check check (
    (is_active and suspended_at is null) or not is_active
  )
);
-- trigger set_host_accounts_updated_at
```
**This — not `profiles.role` — is the authoritative host authorization record.**
Created/updated only by the `private.sync_host_account_from_application()` trigger
that fires when `host_applications.status` is changed (by a service-role caller)
to `approved` or `rejected`. No index besides PK + `unique(application_id)`.

### 2.18 Remote config / feature flags (`0021_remote_config.sql`)

```sql
create table public.app_config (
  key text primary key, value jsonb not null, description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id)
);

create table public.feature_flags (
  key text primary key,
  enabled boolean not null default false,
  rollout_percent int not null default 100 check (rollout_percent between 0 and 100),
  platforms text[] not null default array['ios','android','windows','web'],
  min_app_version text, max_app_version text, description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id)
);

create table public.remote_content (
  slot text primary key, schema_version int not null default 1, payload jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id)
);

create table public.app_versions (
  platform text primary key,
  min_supported_version text not null, latest_version text not null,
  maintenance_mode boolean not null default false, maintenance_message text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.config_audit_log (
  id uuid primary key default gen_random_uuid(),
  table_name text not null, row_key text not null,
  old_value jsonb, new_value jsonb,
  changed_by uuid references public.profiles(id),
  changed_at timestamptz not null default now()
);
```
- `feature_flags` known keys (from migrations): `payment_khalti`, `payment_esewa`
  (`20260823130000`), `ai_itinerary` (`20260823180000`).
- `remote_content` known slot: `onboarding_slides` (`20260821100000`).
- All four config tables have an `updated_at` trigger and an
  `after insert/update/delete` audit trigger → `log_config_change()` (SECURITY
  DEFINER) writing `config_audit_log`.
- **This is the only general-purpose "admin writes config" surface that exists.**

### 2.19 Trip-messaging hardening tables (`20260816*` migrations)

All additive, RLS-enabled. Client access is mostly SELECT-only or none, with
writes funnelled through SECURITY DEFINER / INVOKER RPCs (see §3).

| Table | Migration | Key columns |
|---|---|---|
| `trip_message_reads` | `…090000` | `conversation_id`→bookings, `user_id`→auth.users, `last_read_message_id`→trip_messages, `last_read_at`; PK `(conversation_id, user_id)` |
| `trip_conversations` | `…110000` | `id`, `booking_id` unique→bookings, `created_at` |
| `trip_conversation_members` | `…110000` | `conversation_id`→trip_conversations, `user_id`→auth.users, `role` text check `('traveler','host')`; PK `(conversation_id, user_id)` |
| `trip_message_attachments` | `…120000` | `id`, `message_id`→trip_messages, `storage_path` unique, `mime_type` check(jpeg/png/webp/pdf), `size_bytes` check(1..10485760), `created_at` |
| `trip_push_device_tokens` | `…130000` | `id`, `user_id`→auth.users, `provider` check(`fcm`/`apns`), `platform` check(`android`/`ios`/`web`), `token`, `is_active`, `last_seen_at`, timestamps; `unique(provider, token)` |
| `trip_push_deliveries` | `…130000` | `id`, `message_id`→trip_messages, `recipient_id`→auth.users, `recipient_role` check(`traveler`/`host`), `target_route`, `status` check(`queued`/`processing`/`sent`/`failed`/`skipped_no_token`), `attempt_count`, `dispatch_request_id bigint`, `error_code`, `last_attempt_at`, `sent_at`, timestamps; `unique(message_id, recipient_id)` |
| `trip_message_receipts` | `…150000` | `message_id`→trip_messages, `conversation_id`→bookings, `recipient_id`→auth.users, `delivered_at`, `seen_at`, timestamps; PK `(message_id, recipient_id)` |
| `trip_message_edits` | `…160000` | `id`, `message_id`→trip_messages, `conversation_id`→bookings, `editor_id`→auth.users, `previous_body`, `new_body`, `edited_at` (append-only audit) |
| `trip_message_deletions` | `…160000` | `message_id` PK→trip_messages, `conversation_id`→bookings, `deleted_by`→auth.users, `reason` default `'sender_deleted'`, `deleted_at` |
| `trip_message_mutations` | `…160000` | `message_id` PK→trip_messages, `conversation_id`→bookings, `effective_body`, `edited_at`, `deleted_at`, `updated_at` (current projection; `deleted_at`/`effective_body` mutually exclusive by check) |
| `trip_message_reports` | `…170000` | `id`, `message_id`→trip_messages, `conversation_id`→bookings, `reporter_id`→auth.users, `reported_user_id`→auth.users, `reason` check(`harassment`/`spam`/`scam`/`unsafe`/`hate`/`other`), `details`, `status` check(`open`/`reviewing`/`resolved`/`dismissed`) default `open`, `reviewed_by`→auth.users, `reviewed_at`, `resolution_notes`, timestamps; `unique(message_id, reporter_id)`; index `(status, created_at)` |
| `trip_user_blocks` | `…170000` | `blocker_id`→auth.users, `blocked_id`→auth.users, `conversation_id`→bookings, `created_at`; PK `(blocker_id, blocked_id)`, check `blocker_id <> blocked_id` |

Triggers on `trip_messages` insert: `shadow_trip_conversation_for_booking` (on
`bookings` insert actually), `enqueue_trip_message_push()` → `trip_push_deliveries`
+ `net.http_post` to the `trip-message-push` function via Vault secret,
`create_trip_message_receipts()` → `trip_message_receipts`.

### 2.20 `ai_rate_limits` (`0022_ai_rate_limits.sql`)

```sql
create table public.ai_rate_limits (
  id uuid primary key default gen_random_uuid(),
  rate_key text not null unique,
  window_start timestamptz not null default now(),
  request_count int not null default 1,
  updated_at timestamptz not null default now()
);
```
RLS enabled, **no policies** — service-role / `check_ai_rate_limit()` RPC only.
Used by `initiate-payment`, `payment-webhook`, `generate-itinerary`.

### 2.21 `payment_redirect_tokens` (`20260823070000_payment_redirect_tokens.sql`)

```sql
create table public.payment_redirect_tokens (
  token_hash text primary key,
  payment_id uuid not null unique references public.payments(id) on delete cascade,
  booking_id uuid not null references public.bookings(id) on delete cascade,
  expires_at timestamptz not null,
  consumed_at timestamptz,
  created_at timestamptz not null default now(),
  constraint payment_redirect_tokens_hash_length check (length(token_hash) = 64),
  constraint payment_redirect_tokens_expiry check (expires_at > created_at)
);
```
RLS enabled, **no client policies** (`revoke all … from public, anon, authenticated;
grant all … to service_role`). Only SHA-256 hashes stored; raw token in the URL.
One-time capability for the unauthenticated eSewa browser redirect.

### 2.22 Legal (`20260905120000_legal_documents_and_acceptances.sql`)

```sql
create table public.legal_documents (
  id uuid primary key default gen_random_uuid(),
  slug text not null,
  version text not null,                    -- '1.0', '1.1'
  locale text not null default 'en',        -- 'en', 'ne'
  title text not null,
  body_md text not null,
  effective_at timestamptz not null,
  requires_acceptance boolean not null default false,
  is_current boolean not null default false,
  created_at timestamptz not null default now(),
  unique (slug, version, locale)
);
-- unique index legal_documents_one_current_per_slug_locale on (slug, locale) where is_current
-- index legal_documents_slug_current on (slug, locale) where is_current

create table public.legal_acceptances (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete restrict,   -- evidence: survives account deletion
  document_id uuid not null references public.legal_documents (id),
  booking_id uuid references public.bookings (id),                       -- risk acknowledgment only
  accepted_at timestamptz not null default now(),
  client text not null check (client in ('flutter', 'web')),
  app_version text,
  ip_address inet,
  unique nulls not distinct (user_id, document_id, booking_id)
);
-- index legal_acceptances_user on (user_id)
-- index legal_acceptances_booking on (booking_id) where booking_id is not null
```
`legal_acceptances` is **insert-only evidence** — no UPDATE/DELETE grant to any
non-service role. 13 documents delivered from this table (Terms, Privacy, Booking
Terms, Cancellation, Refund, Payment, Grievance, Account Deletion, Community
Guidelines, Safety & Risk, Risk Acknowledgment, Emergency, Cookie).

### 2.23 Views

```sql
-- 0014_views.sql, hardened by 20260823090000 (security_invoker = on; client access revoked)
public.my_plans_upcoming    -- confirmed bookings with future departure
public.my_trips_completed   -- completed bookings + optional review id
public.my_trips_cancelled   -- cancelled bookings
-- 20260816110000: private.trip_conversation_shadow_drift  (backend burn-in diagnostic)
```
The `my_*` views are marked "currently unused by the Flutter app"; anon/authenticated
`SELECT` is revoked. No materialized views.

### 2.24 Storage buckets (rows inserted by migrations)

| Bucket | Public | Limit | MIME | Migration |
|---|---|---|---|---|
| `avatars` | **yes** | 5 MiB | jpeg/png/webp | `0017_profile_avatars.sql` |
| `host-documents` | no | 10 MiB | jpeg/png/pdf | `20260813090000` |
| `trip-attachments` | no | 10 MiB | jpeg/png/webp/pdf | `20260816120000` |
| `catalog-images` | **yes** | — | webp | `20260904090000` |

### 2.25 Tables with no migration / remote-only

The public schema is **fully defined by `supabase/migrations/`**; the dump
`schema_public.sql` is generated from them and shows nothing extra (it is merely
older). No evidence of a `public` table that exists only in the remote DB. The
`auth.*`, `storage.*`, `realtime.*`, `vault.*`, `net.*` schemas are Supabase-managed;
this project only adds rows/policies/functions to them (buckets in §2.24,
`realtime.messages` policies in §3, `net.http_post` calls, Vault secrets
`trip_message_push_url` / `trip_message_push_webhook_secret`).
**This cannot be positively verified without live DB access (see §8).**

---

## 3. Auth, Roles & RLS

### 3.1 Authentication

Supabase Auth (GoTrue), config in `supabase/config.toml`:

- **Email + password** and **email OTP** (`[auth.email] enable_signup = true`,
  `enable_confirmations = true`, 6-digit OTP, custom Resend SMTP templates
  `confirmation.html` / `recovery.html`). Flutter has an
  `otp_verification_screen.dart`; webapp `/auth/otp-verify`.
- **Google OAuth** — `[auth.external.google] enabled = true` with a committed web
  client_id; browser-redirect PKCE flow. Recent commit `22479ee` adds native
  Google sign-in; `google_sign_in` package is a dependency;
  `GoogleSignInButton.tsx` in webapp.
- **Apple** — `[auth.external.apple] enabled = false` (configured, disabled).
- **Phone / SMS** — `[auth.sms] enable_signup = false`, Twilio block disabled.
- **Anonymous sign-ins** — disabled.
- `minimum_password_length = 6`, `jwt_expiry = 3600`, refresh-token rotation on.
- No MFA (`enroll_enabled = false` everywhere). No CAPTCHA configured.

### 3.2 Roles / user types

| Concept | Where stored | Who can set it |
|---|---|---|
| `public.user_role` enum: `traveler`, `host_applicant`, `host`, `admin` | `profiles.role` (default `traveler`) | Only `service_role`. Trigger `check_profile_role_update` → `prevent_profile_role_escalation()` raises if a non-service session changes `role`. |
| `traveler` → `host_applicant` | `submit-host-application` edge fn does `profiles.update({role: 'host_applicant'})` (service role) | edge function |
| `host_applicant` → `host` (and back to `traveler` on rejection) | `private.sync_host_account_from_application()` trigger on `host_applications.status` change | trigger, only when a service-role caller flips the status |
| `admin` | `profiles.role = 'admin'` | **No code path.** Set manually via Supabase Studio / raw SQL only. |
| Authoritative host authorization | `host_accounts` row: `is_active AND suspended_at IS NULL` joined to `host_applications.status = 'approved'` — evaluated by `private.is_approved_active_host(uuid)` | trigger-managed only |
| Conversation role | `trip_conversation_members.role` text check `('traveler','host')` | trigger `shadow_trip_conversation_for_booking()` |
| `trip_role` enum (`traveler`,`host`) | defined in `0002` | **unused** by any table |

`auth.users.raw_user_meta_data` is read once (`full_name`, `avatar_url`) by
`handle_new_user()` to seed the profile; no role/claim data is kept in user
metadata or JWT app_metadata. Role checks in SQL read `profiles.role` via
`is_admin()`; edge-function trigger guards read
`current_setting('request.jwt.claims')::jsonb->>'role'` and compare to
`'service_role'` (null-safe variant added in `20260823160000`).

### 3.3 Existing admin / staff concept

- `public.is_admin()` — `SECURITY DEFINER STABLE`, `select exists(select 1 from
  public.profiles where id = auth.uid() and role = 'admin')`.
- **Everything wired to `is_admin()`:**
  - RLS write policies on `app_config`, `feature_flags`, `remote_content`,
    `app_versions`; RLS read policy on `config_audit_log`.
  - RLS read policies on `trip_message_reports`, `trip_message_edits`,
    `trip_message_deletions`.
  - RPCs `get_trip_moderation_queue()` and `review_trip_message_report(...)`
    (both `raise exception` unless `is_admin()`).
- **Flutter admin surface:** exactly one screen —
  `lib/features/profile/moderation_queue_screen.dart` at route
  `/admin/message-moderation`. The route builder has **no gate** (any signed-in
  user can navigate to it); the profile screen only *shows the link* when
  `role == UserRole.admin`; the underlying RPCs enforce `is_admin()` server-side.
- **There is no other admin functionality anywhere** — no host-application
  review UI, no user management, no booking/payment console, no content/catalog
  editor, no dashboard. No `admin-*` edge function. No staff/permissions table
  (admin is a single boolean-equivalent enum value; no "support" vs "finance" vs
  "superadmin" tiers).

### 3.4 RLS policies (current effective set, verbatim predicates)

RLS is **enabled on every `public` table** (explicitly in `0013`, `0021`, `0022`,
and the `20260816*` migrations; plus event trigger `rls_auto_enable` on
`ddl_command_end` auto-enables RLS on any newly created `public` table). Grants
were rewritten to least-privilege in `20260823100000`; client writes to
`bookings` and `experiences` were then revoked in `20260823120000`.

**profiles**
```sql
-- replaces "Public profiles are readable by everyone" (20260823090000)
create policy "Public profile identities are readable"
  on public.profiles for select to anon, authenticated using (true);
create policy "Users can update their own profile"
  on public.profiles for update using (auth.uid() = id);
-- column grants: select (id, full_name, avatar_url) to anon, authenticated;
--   update (full_name, phone, avatar_url, location, bio, language,
--           onboarding_complete, updated_at) to authenticated
```

**interests**
```sql
create policy "Interests are readable by everyone" on public.interests for select using (true);
```

**user_interests**
```sql
create policy "Users can read their own interests"
  on public.user_interests for select using (auth.uid() = user_id);
create policy "Users can manage their own interests"
  on public.user_interests for all using (auth.uid() = user_id);
```

**regions**, **categories**, **experience_families**, **tags**
```sql
create policy "Regions are readable by everyone"     on public.regions for select using (true);
create policy "Categories are readable by everyone"  on public.categories for select using (true);
create policy "Experience families are readable by everyone"
  on public.experience_families for select using (true);
create policy "Tags are readable by everyone" on public.tags for select using (true);
```

**experiences**
```sql
-- 20260813100000 (split from an earlier combined policy)
create policy "Published experiences are readable by everyone"
  on public.experiences for select to anon, authenticated
  using (status = 'published'::public.experience_status);
create policy "Approved active hosts can view their own experiences"
  on public.experiences for select to authenticated
  using (auth.uid() = host_id and private.is_approved_active_host(auth.uid()));
-- "Approved active hosts can manage their experiences" (ALL) was DROPPED by
-- 20260823120000, and insert/update/delete was revoked from authenticated.
-- => no client write path to experiences exists today.
```

**experience_departures**
```sql
create policy "Departures readable for published experiences"
  on public.experience_departures for select using (
    exists (select 1 from public.experiences e
      where e.id = experience_id and (e.status = 'published' or e.host_id = auth.uid())));
```

**itinerary_items**
```sql
create policy "Itinerary items readable by anyone"
  on public.itinerary_items for select using (
    exists (select 1 from public.experiences e
      where e.id = experience_id and (e.status = 'published' or e.host_id = auth.uid())));
```

**experience_tags**
```sql
create policy "Published experience tags are readable by everyone"
  on public.experience_tags for select using (
    exists (select 1 from public.experiences e
      where e.id = experience_id and (e.status = 'published' or e.host_id = auth.uid())));
```

**saved_experiences**
```sql
create policy "Users can manage saved experiences"
  on public.saved_experiences for all using (auth.uid() = user_id);
```

**bookings**
```sql
-- 20260813090000 (replaces "Users can view their own bookings")
create policy "Travelers and approved hosts can view related bookings"
  on public.bookings for select using (
    auth.uid() = user_id or exists (
      select 1 from public.experiences e
      where e.id = experience_id and e.host_id = auth.uid()
        and private.is_approved_active_host(auth.uid())));
-- "Users can insert pending bookings" DROPPED by 20260823120000; insert revoked.
-- No client UPDATE/DELETE policy. status changes are service-role-only (trigger).
```

**booking_participants**
```sql
-- 20260813090000 (replaces "Participants readable by booking owner or host")
create policy "Travelers and approved hosts can view participants"
  on public.booking_participants for select using (
    exists (select 1 from public.bookings b
      where b.id = booking_id and (
        b.user_id = auth.uid() or exists (
          select 1 from public.experiences e
          where e.id = b.experience_id and e.host_id = auth.uid()
            and private.is_approved_active_host(auth.uid())))));
create policy "Booking lead user can insert participants"
  on public.booking_participants for insert with check (
    exists (select 1 from public.bookings b
      where b.id = booking_id and b.user_id = auth.uid()));
```

**payments** — RLS enabled, **no policies at all** (service-role only; trigger
`check_payment_mutation` blocks every non-service mutation).

**trip_messages**
```sql
create policy "Trip members can read trip messages"
  on public.trip_messages for select using (public.is_trip_member(booking_id));
create policy "Trip members can insert trip messages"
  on public.trip_messages for insert
  with check (public.is_trip_member(booking_id) and auth.uid() = sender_id);
```

**gear_checklist_items**, **budget_entries**
```sql
create policy "Booking owners can manage gear checklist"
  on public.gear_checklist_items for all using (
    exists (select 1 from public.bookings b where b.id = booking_id and b.user_id = auth.uid()));
create policy "Booking owners can manage budget entries"
  on public.budget_entries for all using (
    exists (select 1 from public.bookings b where b.id = booking_id and b.user_id = auth.uid()));
```

**reviews**
```sql
-- "Reviews are readable by everyone" DROPPED by 20260823110000
create policy "Users can read their own reviews"
  on public.reviews for select to authenticated using (auth.uid() = user_id);
create policy "Users can insert review for completed booking"
  on public.reviews for insert with check (
    auth.uid() = user_id and exists (
      select 1 from public.bookings b
      where b.id = booking_id and b.user_id = auth.uid() and b.status = 'completed'));
-- public review cards go through get_public_experience_reviews() (SECURITY DEFINER)
```

**host_applications**
```sql
create policy "Users can view their own host application"
  on public.host_applications for select using (auth.uid() = user_id);
-- "Users can create and edit draft host applications" (ALL) DROPPED by 20260813090000
create policy "Users can create their own draft host application"
  on public.host_applications for insert to authenticated
  with check (auth.uid() = user_id and status = 'draft'::public.host_app_status);
-- created 20260813090000, then REDEFINED by 20260906120000:
create policy "Users can edit their own draft host application"
  on public.host_applications for update to authenticated
  using  (auth.uid() = user_id and status in ('draft', 'action_required', 'rejected'))
  with check (auth.uid() = user_id and status in ('draft', 'action_required', 'rejected'));
-- status column changes blocked for non-service by trigger check_host_app_status_update
```

**notifications**
```sql
create policy "Users can view their own notifications"
  on public.notifications for select using (auth.uid() = user_id);
create policy "Users can mark notifications as read"
  on public.notifications for update using (auth.uid() = user_id);
```

**device_tokens**
```sql
create policy "Users can manage their device tokens"
  on public.device_tokens for all using (auth.uid() = user_id);
-- but 20260823100000 grants device_tokens NO privileges to anon/authenticated -> unusable
```

**host_accounts**
```sql
create policy "Hosts can view their own host account"
  on public.host_accounts for select to authenticated using (auth.uid() = user_id);
-- revoke all from anon, authenticated; grant select to authenticated
```

**app_config / feature_flags / remote_content / app_versions**
```sql
create policy "Config readable by everyone"        on public.app_config     for select using (true);
create policy "Feature flags readable by everyone" on public.feature_flags  for select using (true);
create policy "Remote content readable by everyone" on public.remote_content for select using (true);
create policy "App versions readable by everyone"  on public.app_versions   for select using (true);
create policy "Admins can manage app config"    on public.app_config    for all using (public.is_admin()) with check (public.is_admin());
create policy "Admins can manage feature flags" on public.feature_flags for all using (public.is_admin()) with check (public.is_admin());
create policy "Admins can manage remote content" on public.remote_content for all using (public.is_admin()) with check (public.is_admin());
create policy "Admins can manage app versions"  on public.app_versions  for all using (public.is_admin()) with check (public.is_admin());
```

**config_audit_log**
```sql
create policy "Admins can read config audit log"
  on public.config_audit_log for select using (public.is_admin());
```

**ai_rate_limits** — RLS enabled, **no policies** (service/RPC only).

**payment_redirect_tokens** — RLS enabled, **no policies**; `revoke all from
public, anon, authenticated; grant all to service_role`.

**legal_documents**
```sql
create policy "Current legal documents are public"
  on public.legal_documents for select to anon, authenticated using (is_current);
create policy "Superseded versions readable by those who accepted them"
  on public.legal_documents for select to authenticated using (
    not is_current and exists (
      select 1 from public.legal_acceptances a
      where a.document_id = legal_documents.id and a.user_id = auth.uid()));
```

**legal_acceptances**
```sql
create policy "Users insert their own acceptances"
  on public.legal_acceptances for insert to authenticated
  with check (user_id = auth.uid() and client in ('flutter', 'web'));
create policy "Users read their own acceptances"
  on public.legal_acceptances for select to authenticated using (user_id = auth.uid());
```

**trip_message_reads**
```sql
create policy "Trip members can read their own message read state"
  on public.trip_message_reads for select using (user_id = auth.uid() and public.is_trip_member(conversation_id));
create policy "Trip members can insert their own message read state"
  on public.trip_message_reads for insert with check (
    user_id = auth.uid() and public.is_trip_member(conversation_id) and (
      last_read_message_id is null or exists (
        select 1 from public.trip_messages message
        where message.id = last_read_message_id and message.booking_id = conversation_id)));
create policy "Trip members can update their own message read state"
  on public.trip_message_reads for update using (user_id = auth.uid() and public.is_trip_member(conversation_id))
  with check (user_id = auth.uid() and public.is_trip_member(conversation_id) and (
      last_read_message_id is null or exists (
        select 1 from public.trip_messages message
        where message.id = last_read_message_id and message.booking_id = conversation_id)));
```

**trip_conversations / trip_conversation_members**
```sql
create policy "Trip members can read their conversation containers"
  on public.trip_conversations for select to authenticated using (
    exists (select 1 from public.trip_conversation_members membership
      where membership.conversation_id = id and membership.user_id = auth.uid()));
create policy "Users can read only their own conversation membership"
  on public.trip_conversation_members for select to authenticated using (user_id = auth.uid());
```

**trip_message_attachments**
```sql
create policy "Trip members can read attachment metadata"
  on public.trip_message_attachments for select to authenticated using (
    exists (select 1 from public.trip_messages message
      where message.id = message_id
        and private.is_trip_member_by_booking(message.booking_id, auth.uid())));
```

**trip_push_device_tokens / trip_push_deliveries** — RLS enabled, **no client
policies** (`revoke all from public, anon, authenticated`); RPCs + service role.

**trip_message_receipts**
```sql
create policy "Recipients and senders can read message receipts"
  on public.trip_message_receipts for select to authenticated using (
    recipient_id = auth.uid() or exists (
      select 1 from public.trip_messages message
      where message.id = message_id and message.sender_id = auth.uid()));
```

**trip_message_mutations**
```sql
create policy "Trip members can read current message mutations"
  on public.trip_message_mutations for select to authenticated using (public.is_trip_member(conversation_id));
```

**trip_message_edits / trip_message_deletions**
```sql
create policy "Admins can read message edit audit"
  on public.trip_message_edits for select to authenticated using (public.is_admin());
create policy "Admins can read message deletion audit"
  on public.trip_message_deletions for select to authenticated using (public.is_admin());
-- 20260823150000 then REVOKES select on both from authenticated -> reachable only
-- via get_trip_moderation_queue() (admin RPC).
```

**trip_message_reports**
```sql
create policy "Reporters can read their own message reports"
  on public.trip_message_reports for select to authenticated using (reporter_id = auth.uid());
create policy "Admins can read all message reports"
  on public.trip_message_reports for select to authenticated using (public.is_admin());
```

**trip_user_blocks**
```sql
create policy "Blockers can read their own block list"
  on public.trip_user_blocks for select to authenticated using (blocker_id = auth.uid());
```

**storage.objects**
```sql
-- avatars (0017)
create policy "Avatar images are publicly readable"
  on storage.objects for select using (bucket_id = 'avatars');
create policy "Users can upload their own avatar"
  on storage.objects for insert with check (
    bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1]);
create policy "Users can update their own avatar"
  on storage.objects for update using (
    bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1]);
create policy "Users can delete their own avatar"
  on storage.objects for delete using (
    bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1]);
-- host-documents (20260813090000): applicants insert/select/update objects where
--   auth.uid()::text = (storage.foldername(name))[1]  (private; no public read)
-- trip-attachments (20260816120000): members select/insert/delete where
--   private.is_trip_member_by_booking((storage.foldername(name))[1]::uuid, auth.uid())
--   and (for insert/delete) (storage.foldername(name))[2] = auth.uid()::text
-- catalog-images (20260904090000): public bucket, NO client upload policy added
```

**realtime.messages** (`20260816140000`)
```sql
create policy "Trip members can receive private trip presence"
  on realtime.messages for select to authenticated using (
    realtime.messages.extension = 'presence'
    and private.can_join_trip_presence((select realtime.topic()), (select auth.uid())));
create policy "Trip members can publish private trip presence"
  on realtime.messages for insert to authenticated with check (
    realtime.messages.extension = 'presence'
    and private.can_join_trip_presence((select realtime.topic()), (select auth.uid())));
```

### 3.5 Postgres functions, triggers, SECURITY DEFINER

**`public` functions**

| Function | Security | Purpose |
|---|---|---|
| `set_updated_at()` | invoker | shared `updated_at` trigger fn |
| `handle_new_user()` | **DEFINER** | insert `profiles` row on `auth.users` insert |
| `prevent_profile_role_escalation()` | invoker | block client `profiles.role` change (null-safe in `20260823160000`) |
| `prevent_client_booking_status_change()` | invoker | block client `bookings.status` change |
| `prevent_client_payment_mutation()` | invoker | block all client `payments` writes |
| `prevent_client_host_app_status_change()` | invoker | block client `host_applications.status` change |
| `experiences_update_search_tsv()` | invoker | maintain `experiences.search_tsv` |
| `update_experience_rating_stats()` | **DEFINER** | recompute `experiences.rating_avg`/`rating_count` |
| `is_trip_member(uuid)` | **DEFINER** | booking owner or experience host |
| `is_admin()` | **DEFINER**, stable | `profiles.role = 'admin'` for `auth.uid()` |
| `current_host_access()` | **DEFINER**, stable | returns `(is_authenticated, is_approved, is_active, application_status)` for the caller |
| `log_config_change()` | **DEFINER** | write `config_audit_log` from the 4 config-table triggers |
| `check_ai_rate_limit(text,int,int)` | **DEFINER** | fixed-window rate limit (grant: `service_role` only after `20260823170000`) |
| `consume_payment_redirect_token(text)` | **DEFINER** | atomically consume a one-time eSewa redirect token (grant: `service_role`) |
| `finalize_verified_payment(uuid,uuid,payment_provider,text,jsonb)` | **DEFINER** | the single atomic "confirm booking + mark payment paid + decrement spots + seed participants/gear" transaction (grant: `service_role`) |
| `get_my_profile()` | **DEFINER**, stable | full own profile row |
| `get_public_host_profile(uuid)` | **DEFINER**, stable | limited public host profile (approved active hosts only) |
| `get_public_experience_reviews(uuid)` | **DEFINER**, stable | review cards for a published experience (grant: anon, authenticated) |
| `host_booking_payment_transactions()` | **DEFINER**, stable | payment facts for the caller's own experiences' bookings (no `raw_response`/`idempotency_key`) |
| `mark_trip_conversation_read(uuid)` | **DEFINER** (was invoker in `…090000`) | update read cursor + seen receipts |
| `send_trip_message(uuid,uuid,text,text)` | **INVOKER** | idempotent message insert + pairwise block check |
| `edit_trip_message(uuid,text)` / `delete_trip_message(uuid)` | **DEFINER** | append edit/deletion audit + mutation projection |
| `register_trip_message_attachment(uuid,text,text,bigint)` | **DEFINER** | validated attachment metadata registration |
| `register_trip_push_device(text,text,text)` / `unregister_trip_push_device(text,text)` | **DEFINER** | FCM/APNs token registry |
| `claim_trip_push_deliveries(uuid)` | **DEFINER** | atomically lease push-delivery rows (grant: `service_role`) |
| `report_trip_message(uuid,text,text)` | **DEFINER** | file a message report |
| `block_trip_participant(uuid,uuid)` / `unblock_trip_participant(uuid)` | **DEFINER** | conversation-scoped block list |
| `get_trip_conversation_safety(uuid)` | **DEFINER**, stable | `(blocked_by_me, blocked_me, can_message)` |
| `get_trip_moderation_queue()` | **DEFINER**, stable | **admin-only** report queue with message bodies |
| `review_trip_message_report(uuid,text,text)` | **DEFINER** | **admin-only** set report status |

**`private` schema functions** (schema created `20260813090000`; `usage` granted to
`authenticated`, `execute` granted selectively):
`is_approved_active_host(uuid)`, `sync_host_account_from_application()` (trigger fn,
no grants), `shadow_trip_conversation_for_booking()` (trigger fn),
`enqueue_trip_message_push()` (trigger fn; calls `net.http_post` with a Vault
secret), `create_trip_message_receipts()` (trigger fn),
`is_trip_member_by_booking(uuid,uuid)`, `is_trip_member_user(uuid,uuid)`,
`trip_messaging_is_blocked(uuid,uuid)`, `can_join_trip_presence(text,uuid)`.
All `security definer`, all `set search_path = ''`.

**Triggers**

| Trigger | Table / event | Function |
|---|---|---|
| `on_auth_user_created` | `auth.users` AFTER INSERT | `handle_new_user()` |
| `set_*_updated_at` (profiles, experiences, bookings, payments, host_apps, reviews, host_accounts, app_config, feature_flags, remote_content, app_versions) | BEFORE UPDATE | `set_updated_at()` |
| `check_profile_role_update` | `profiles` BEFORE UPDATE | `prevent_profile_role_escalation()` |
| `check_booking_status_update` | `bookings` BEFORE UPDATE | `prevent_client_booking_status_change()` |
| `check_payment_mutation` | `payments` BEFORE INSERT/UPDATE/DELETE | `prevent_client_payment_mutation()` |
| `check_host_app_status_update` | `host_applications` BEFORE UPDATE | `prevent_client_host_app_status_change()` |
| `experiences_search_tsv_trigger` | `experiences` BEFORE INSERT/UPDATE | `experiences_update_search_tsv()` |
| `on_review_change` | `reviews` AFTER INSERT/UPDATE/DELETE | `update_experience_rating_stats()` |
| `audit_app_config` / `audit_feature_flags` / `audit_remote_content` / `audit_app_versions` | AFTER INSERT/UPDATE/DELETE | `log_config_change()` |
| `sync_host_account_after_application_review` | `host_applications` AFTER INSERT OR UPDATE OF status | `private.sync_host_account_from_application()` |
| `shadow_trip_conversation_after_booking_insert` | `bookings` AFTER INSERT | `private.shadow_trip_conversation_for_booking()` |
| `enqueue_trip_message_push_after_insert` | `trip_messages` AFTER INSERT | `private.enqueue_trip_message_push()` |
| `create_trip_message_receipts_after_insert` | `trip_messages` AFTER INSERT | `private.create_trip_message_receipts()` |
| `rls_auto_enable` | **event trigger** on `ddl_command_end` (CREATE TABLE) | `rls_auto_enable()` — `alter table … enable row level security` |

---

## 4. Host Onboarding & Document Verification

### 4.1 The flow as implemented

Two client flows write the **same single-row-per-user** `host_applications` table:

1. **Legacy Flutter 4-step** — `lib/features/host/host_step_1..4_screen.dart`,
   `become_host_screen.dart`, driven by
   `lib/repositories/host_repository.dart::submitHostApplication()`. Posts flat
   fields to the `submit-host-application` edge function.
2. **Shared 8-step questionnaire (current)** —
   `lib/features/host/host_questionnaire_screen.dart` (Flutter) and
   `webapp/src/app/(main)/host/application/page.tsx` (web), both driven by the
   canonical v1 payload in `docs/HOST_APPLICATION_CONTRACT.md`
   (`webapp/src/lib/host-application.ts` is the web validator). Posts
   `{ applicationData: {...} }` to the same edge function.

Step by step:

1. **Auth gate.** `/host` and `/host/application/:step` are wrapped in
   `HostApplicationAuthGate`. Unauthenticated users are sent to sign-in.
2. **Draft autosave.** The client upserts `host_applications` directly
   (`user_id` conflict target) with `current_step` (1–8), `application_data`
   (whole questionnaire JSON), and the mirrored searchable columns
   `title` / `description` / `location` / `photos` / `verification_doc_path`.
   RLS allows this only while `status ∈ (draft, action_required, rejected)`.
3. **Document upload.** `HostRepository.uploadHostDocument()` uploads bytes to the
   private `host-documents` bucket at path
   `<auth.uid()>/<millis>_<sanitized-filename>` and returns that path. The client
   can view its own uploads via `createSignedUrl(path, 300)` (5-minute signed URL).
4. **Submit.** `POST` to edge function `submit-host-application`
   (`supabase/functions/submit-host-application/index.ts`, runs as service role):
   - Authenticates the caller (`_shared/auth.ts`).
   - Validates. Questionnaire path requires: `hosting_type`, `host_type`,
     `full_name` (≥2), `phone`, `province`, `district`, `locality`,
     `availability_type` (+ conditional days/date-range), `pricing_model`
     (+ positive `price_paisa` unless `custom_quote`), `cancellation_policy`,
     `description` (≥20), a valid `email` (must equal the account email for
     `host_type = individual`), `identity_type`, a valid `identity_number`
     (regex), `identity_front_path` starting `"<user.id>/"`, `terms_accepted === true`,
     and capacity `1 ≤ min_guests ≤ max_guests ≤ 100`.
   - Maps `hosting_type` (or legacy label) → a `categories.slug` → `category_id`
     (`adventure→trekking`, `experience→culture`, `stay→homestay`,
     `tour_package→travel-package`, `community_activity→community-event`,
     `other→group-activity`). Migration `20260906130000` backfills rows that were
     saved with a NULL `category_id`.
   - Upserts `host_applications` with `status = 'submitted'`, `current_step = 8`
     (or 4 for legacy), `submitted_at = now()`, `reviewed_at = null`,
     `reviewer_note = null`, `application_data` = the whole payload,
     `photos` = `source.photo_paths`.
   - Updates `profiles` (`full_name`, `phone`, `bio`, `location`,
     `role = 'host_applicant'`, `updated_at`).
   - Rejects resubmission with **409** unless the existing row's status is in
     `(draft, action_required, rejected)`.
   - **Bank/payout details and the raw identity *number* are validated but NOT
     stored** — code comment: *"Bank account and raw identity number are
     intentionally validated but not stored until a dedicated encrypted/PCI-safe
     backend exists."* Only the identity **document file path**
     (`verification_doc_path` / `application_data.identity_front_path` etc.) is
     persisted.
5. **Post-submit screens.** Flutter `application_submitted_screen.dart`; web
   `/host/status` — both just re-read `host_applications.status` and show a label.

### 4.2 Host statuses (exact values)

`host_app_status` enum: `draft`, `submitted`, `under_review`, `verification`
(legacy — still readable, not produced by current clients), `action_required`
(added `20260906115900`), `approved`, `rejected`.

Flutter `HostAppStatus` enum (`lib/models/host_application.dart`):
`draft`, `submitted`, `underReview`, `verification`, `actionRequired`,
`approved`, `rejected` (JSON `under_review`, `action_required`, …).

Downstream authorization state lives in `host_accounts`
(`is_active`, `suspended_at`) — see §2.17 / §3.2.

### 4.3 Documents collected & storage

From `docs/HOST_APPLICATION_CONTRACT.md` + `host-application.ts` +
`submit-host-application`:

- `identity_type`, `identity_number` (number **not** stored server-side),
  `identity_front_path`, `identity_back_path`
- Conditional: `business_document_paths[]` (registered businesses / tour
  operators / hotels), `safety_document_paths[]` (adventures & tour packages)
- `host_photo_path`, `photo_paths[]`, `business_logo_path`
- Legacy 4-step also collected bank/payout fields (`bankName`, `accountName`,
  `accountNumber`, `branch`) — validated, discarded.

**Storage bucket:** `host-documents`
- `public = false` (private; no public read policy)
- `file_size_limit = 10485760` (10 MiB), MIME `image/jpeg`, `image/png`,
  `application/pdf`
- **File naming:** `<auth.uid()>/<epoch-millis>_<sanitized-filename>` — first path
  segment is the owner's user id
- **Bucket policies** (`storage.objects`): applicant may `insert` / `select` /
  `update` objects where `auth.uid()::text = (storage.foldername(name))[1]`. No
  `delete` policy for applicants. Service-role review bypasses RLS.
- **Access mode:** signed-URL only (`createSignedUrl`, 300 s). Not public.
- The DB stores only the string path(s); there is **no `host_documents` metadata
  table** (no size, mime, uploaded_at, verified flag).

### 4.4 Who approves a host

**No approval mechanism exists in code.** There is no admin screen, no edge
function, no RPC that approves or rejects a host application.

Approval happens by a trusted operator running, in Supabase Studio / SQL as
`service_role`:
```sql
update public.host_applications
set status = 'approved', reviewed_at = now(), reviewer_note = '…'
where user_id = '<uuid>';
```
That fires `sync_host_account_after_application_review` →
`private.sync_host_account_from_application()`:
- **on `approved`:** upsert `host_accounts` (`is_active = true`,
  `approved_at = coalesce(reviewed_at, now())`, `suspended_at = null`); set
  `profiles.role = 'host'`.
- **on `rejected`:** `host_accounts.is_active = false`, `suspended_at = now()`;
  set `profiles.role = 'traveler'`.
- `under_review`, `action_required`, `verification` can be set on the row but
  trigger **no** side effects.

`reviewer_note` / `reviewed_at` are free columns; nothing but a manual update
writes them (the edge function only clears them on resubmit). There is no
reviewer identity column, no decision history, no review checklist.

### 4.5 Notification to hosts on approval / rejection

**NOT PRESENT.** No `notifications` row is inserted, no push is sent, no email is
triggered on any host-application status change. The `notif_type` enum value
`host_application` is never used. Clients discover the outcome only by
re-fetching `host_applications.status` (Flutter `application_submitted_screen`,
web `/host/status`, and `current_host_access()` / `HostModeAccessGate` for the
approved case).

---

## 5. Bookings & Payments

### 5.1 Booking lifecycle

`booking_status` enum: `pending`, `confirmed`, `cancellation_requested`,
`cancelled`, `completed`, `expired`.

| Status | Set by | Notes |
|---|---|---|
| `pending` | `create-booking-intent` edge fn (service role) | inserts `bookings` + `payments` (`initiated`); `quote_expires_at = now()+15min`; `booking_ref = "PLE-" + random 6 digits`; `idempotency_key = "intent_" + uuid` |
| `confirmed` | `finalize_verified_payment()` RPC (service role) only | atomic: `spots_left -= adults+children`, `payments.status='paid'`, insert lead `booking_participants`, seed `gear_checklist_items` from `experiences.bring_list`; row locks make it idempotent |
| `completed` | `complete-trips-cron` edge fn (X-Cron-Secret) | selects `status='confirmed'` bookings with `experience_departures.end_date <= today`, sets `completed`, `completed_at` |
| `cancellation_requested` | **nothing** | enum value only — no producer |
| `cancelled` | **nothing** | enum value only — `cancelled_at` column + `my_trips_cancelled` view exist, no code path |
| `expired` | **nothing** | enum value only — no cron expires stale `pending` bookings |

- Clients cannot INSERT bookings (revoked `20260823120000`; only the edge fn
  does) and cannot change `status` (trigger). Client grant on `bookings` is
  `select` only.
- `is_draft` boolean exists (edge fn always sets `false`).

### 5.2 Payment gateways

**Khalti** (ePayment v2) and **eSewa** (ePay v2). Enum `payment_provider` =
`khalti | esewa`. **No card, Fonepay, IME, ConnectIPS, or bank transfer.**

Availability is a server decision — `feature_flags` keys `payment_khalti` /
`payment_esewa`, checked by `_shared/payment_provider.ts::isPaymentProviderEnabled`
in `create-booking-intent` and `initiate-payment`.

Integration code:

| File | Role |
|---|---|
| `supabase/functions/create-booking-intent/index.ts` | authenticated; re-prices, creates `bookings` (`pending`) + `payments` (`initiated`) |
| `supabase/functions/initiate-payment/index.ts` | authenticated; Khalti → `POST {base}/epayment/initiate/` returns `pidx` + `payment_url`, stored in `payments.raw_response.pidx`. eSewa → creates a `payment_redirect_tokens` row and returns an `esewa-redirect` URL. Rate-limited via `check_ai_rate_limit` keys `payment:initiate:user:*` (20/15min), `payment:initiate:booking:*` (3/15min) |
| `supabase/functions/esewa-redirect/index.ts` | `verify_jwt=false`; consumes the one-time token, writes `payments.raw_response.transaction_uuid`, builds an HMAC-SHA256-signed auto-submitting form POST to `https://rc-epay.esewa.com.np/api/epay/main/v2/form` |
| `supabase/functions/payment-webhook/index.ts` | authenticated (mobile app after its WebView intercepts the return URL); re-verifies with the gateway (`/epayment/lookup/` or eSewa status API) then calls `finalize_verified_payment`. Rate-limited (`payment:verify:*`) |
| `supabase/functions/payment-return/index.ts` | `verify_jwt=false`; pure 302 → `verify-payment-return` |
| `supabase/functions/verify-payment-return/index.ts` | `verify_jwt=false`; the **web** browser-redirect landing path; service role; re-verifies with the gateway, calls `finalize_verified_payment`, then 302 → `https://planenepal.com/booking/confirmation/<id>?payment=<status>` |

Sandbox defaults: Khalti `https://dev.khalti.com/api/v2`; eSewa merchant
`EPAYTEST`, secret `8gBm/:&EnhH.1/q`, status host `rc.esewa.com.np`. Real
secrets are edge-function env vars (`KHALTI_SECRET_KEY`, `KHALTI_API_BASE_URL`,
`ESEWA_MERCHANT_CODE`, `ESEWA_SECRET_KEY`, `PUBLIC_SUPABASE_URL`).

### 5.3 Gateway response shape — what is returned & persisted

`payments.raw_response` (jsonb) accumulates, in order:
1. From `create-booking-intent`: `{ quote_expires_at, adults, children, created_at }`
2. From `initiate-payment` / `esewa-redirect`: `{ pidx }` (Khalti) **or**
   `{ transaction_uuid }` (eSewa)
3. On finalize/fail: merged with the **full gateway lookup/status JSON**
   (`coalesce(raw_response,'{}') || gateway_response` inside
   `finalize_verified_payment`; a shallow `{...payment.raw_response, ...gatewayResponse}`
   on the failure path).

Persisted columns from a verified payment: `payments.status = 'paid'`,
`payments.provider_ref` (Khalti `transaction_id` || `pidx`; eSewa `ref_id` ||
`transaction_uuid`), `payments.paid_at = now()`, plus the merged
`raw_response`. Unique index `(provider, provider_ref) where provider_ref is not
null`.

Verification predicates:
- Khalti: `lookupRes.ok && lookupData.status === 'Completed' &&
  Number(lookupData.total_amount) === Number(payment.amount_paisa)`
- eSewa: `statusRes.ok && statusData.status === 'COMPLETE' &&
  statusData.transaction_uuid === transaction_uuid &&
  Math.round(Number(statusData.total_amount) * 100) === Number(payment.amount_paisa)`

Client-supplied "paid" is never trusted; the gateway is always re-queried with
the server secret.

### 5.4 Refund / cancellation handling

**NOT PRESENT.** `payment_status` has a `refunded` value that **no code sets**.
There is no refund endpoint, no cancellation endpoint, no credit-note logic, no
partial-refund math. A failed gateway verification sets `payments.status =
'failed'` (booking stays `pending`); `finalize_verified_payment` refuses to run
if the quote has expired or the booking is not `pending`.

### 5.5 Payout to hosts & commission

- **Payout code: NOT PRESENT.** `docs/FEATURES_BACKLOG.md`: *"Host payout
  mechanism after approval | out of v1 | manual, off-app"*; `docs/TRD.md` §9 the
  same. Flutter "Earnings & Payouts" screens
  (`host_business_screen.dart`, `mock_host_mode_repository.dart`,
  `supabase_host_mode_repository.dart`) are display-only stubs: *"Display only.
  Secure payout processing is not connected."* Bank/wallet details are collected
  in the questionnaire and discarded (§4.1).
- Hosts can *read* payment facts for their own experiences' bookings via
  `public.host_booking_payment_transactions()` (returns `payment_id, booking_id,
  provider, provider_ref, amount_paisa, payment_status, paid_at, created_at`;
  withholds `raw_response` and `idempotency_key`).
- **Commission logic: NOT PRESENT** as a host-payout concept. The only fee in the
  system is a hard-coded **5 % platform fee** computed in
  `supabase/functions/create-booking-intent/index.ts`:
  ```js
  const feesPaisa = Math.round(subtotalPaisa * 0.05); // 5% platform fee
  const totalPaisa = subtotalPaisa + addonsPaisa + feesPaisa;
  ```
  It is stored on the booking as `fees_paisa` and charged **on top of** the
  subtotal to the traveller. The `0.05` is a literal — **there is no commission
  rate column, config key, or feature flag** anywhere. No host-side deduction is
  computed.
- Child pricing fallback (also in `create-booking-intent`): child rate =
  `experience.child_price_paisa ?? floor(adultRate * 0.75)`.
- Adult rate = `departure.price_override_paisa ?? experience.price_paisa`.

---

## 6. Tax / Invoicing / IRD-CBMS

### 6.1 Invoice generation

**NOT PRESENT.** There is no invoice table, no invoice-generation function, no
PDF/HTML invoice template, no invoice numbering scheme, and no sequence table.

Identifier facts:
- `bookings.booking_ref` = `"PLE-" + Math.floor(100000 + Math.random()*900000)` —
  a **random** 6-digit suffix generated in `create-booking-intent`, protected only
  by a `UNIQUE` constraint (collisions cause an insert failure, not a retry). Not
  monotonic, not a fiscal document number.
- `payments.idempotency_key` = `"intent_" + crypto.randomUUID()`.
- All other IDs are `gen_random_uuid()`. No `SERIAL`/`IDENTITY`/sequence table
  anywhere in the schema.

### 6.2 IRD / CBMS integration

**NOT PRESENT.** A full-tree search for `ird`, `cbms`, `vat`, `pan`, `invoice`,
`bill`, `tax`, `seller_pan`, `buyer_pan` returns **zero** code hits. (Matches
found: binary image files; the literal `tax_amount: "0"` /
`product_service_charge: "0"` / `product_delivery_charge: "0"` fields in the
eSewa form in `esewa-redirect/index.ts`; the word "tax" inside
`docs/` prose; `payment-policy.md` in `supabase/legal/`.) There is no IRD API
client, no CBMS billing sync, no fiscal-printer integration, no real-time
invoice transmission.

### 6.3 Invoice submission audit / sync log

**NOT PRESENT.** No `ird_sync_log`, `cbms_submissions`, `invoice_sync`, or any
equivalent table. The only audit tables that exist are `config_audit_log` (config
tables only) and the trip-message audit tables — none relate to fiscal documents.

### 6.4 Whose PAN appears on a customer-facing invoice

**N/A — no invoice is produced, and no PAN is stored anywhere.** Neither a
platform PAN nor a host PAN exists in the schema, config, or code. `host_accounts`
has no registration/PAN column; `experiences` has no seller-tax attributes;
`bookings` captures only `contact_name` + `contact_phone` for the buyer.

### 6.5 VAT / service charge computation & rate

The only money-on-top computation is the **5 % platform fee** in
`supabase/functions/create-booking-intent/index.ts`
(`Math.round(subtotalPaisa * 0.05)`, stored as `bookings.fees_paisa`). It is
**not** labelled or treated as VAT or a statutory service charge — it is a
marketplace fee. No 13 % VAT, no 10 % service charge, no tax-rate constant, no
per-line tax breakdown. `currency` is fixed to `'NPR'`; all amounts are integer
paisa.

### 6.6 Where invoicing would need to hook in (based on current code)

- **`public.finalize_verified_payment(...)`**
  (`supabase/migrations/20260823080000_atomic_payment_finalization.sql`) — the
  single transaction where a booking becomes `confirmed` and a payment becomes
  `paid`. An invoice row + number allocation belongs inside this RPC (or a
  trigger on its writes) so it is atomic with confirmation.
- **`supabase/functions/payment-webhook/index.ts`** and
  **`supabase/functions/verify-payment-return/index.ts`** — the two callers of
  that RPC (mobile and web). A post-RPC "transmit to IRD/CBMS" step, or an
  enqueue into a new `ird_sync_log`, would sit here or in a dedicated new
  function.
- **`supabase/functions/complete-trips-cron/index.ts`** — if final invoicing is
  meant to happen at trip completion rather than at payment, this is the hook.
- **New tables required:** `invoices`, an invoice-number sequence/allocation
  table (per fiscal year), `ird_sync_log` / `cbms_submissions` (attempt, payload,
  response, status, retry).
- **New columns required:** buyer identity on `bookings` (legal name, address,
  email, optional PAN — only `contact_name`/`contact_phone` exist today); seller
  identity/PAN/registration on `host_accounts` or `experiences`; a platform-PAN
  config key in `app_config`.
- **Refund/credit-note hook:** does not exist yet — there is no refund code path
  (§5.4), so credit-note issuance has nowhere to attach.
- **VAT rate:** would need an `app_config` key (or a constant) — currently only
  the `0.05` literal fee exists.

---

## 7. Existing Audit / Logging

### 7.1 "Who changed what, when" records

- **`config_audit_log`** (`0021_remote_config.sql`) — `after insert/update/delete`
  triggers on `app_config`, `feature_flags`, `remote_content`, `app_versions`
  write `{ table_name, row_key, old_value jsonb, new_value jsonb,
  changed_by = auth.uid(), changed_at }`. Admin-read only. **This is the only
  change-audit table, and it covers only those four config tables.**
- **Trip-messaging audit:** `trip_message_edits` (append-only:
  `previous_body`, `new_body`, `editor_id`, `edited_at`),
  `trip_message_deletions` (`deleted_by`, `reason`, `deleted_at`),
  `trip_message_reports` (`reporter_id`, `reported_user_id`, `status`,
  `reviewed_by`, `reviewed_at`, `resolution_notes`). Admin / service only.
  `trip_push_deliveries` records push attempts (`status`, `attempt_count`,
  `error_code`, `last_attempt_at`, `sent_at`, `dispatch_request_id`).
- **`legal_acceptances`** — not an audit table but immutable evidence:
  insert-only (no UPDATE/DELETE grant), records
  `{ user_id, document_id, booking_id, accepted_at, client, app_version,
  ip_address }`.
- **No audit at all on:** `bookings`, `payments`, `host_applications`,
  `host_accounts`, `experiences`, `experience_departures`, `profiles`
  (including `role` changes), `reviews`.

### 7.2 Soft-delete vs hard delete

- **`deleted_at` exists only in trip messaging:** `trip_message_mutations.deleted_at`
  + the `trip_message_deletions` table. Messages are never physically removed;
  the current projection just hides them.
- **Every other table is hard-delete**, mostly via `ON DELETE CASCADE` from
  `profiles` / `auth.users`. Notable FK behaviours:
  - `bookings.user_id` → `profiles` **CASCADE**; `bookings.experience_id` /
    `departure_id` → **RESTRICT**.
  - `host_applications.user_id` → **CASCADE**; `host_applications.category_id` →
    **SET NULL**.
  - `experiences.host_id` → `profiles` **SET NULL**; `category_id` / `region_id`
    → **RESTRICT**.
  - `host_accounts.application_id` → **RESTRICT**.
  - `payments.booking_id` / `payment_redirect_tokens.*` → **CASCADE**.
  - `legal_acceptances.user_id` → **RESTRICT** (evidence survives account
    deletion; the account-deletion policy anonymises `auth.users` instead).
- No `is_deleted` / `archived_at` / status-based soft delete on bookings, hosts,
  experiences, or profiles.

### 7.3 Server-side logging / error tracking

- Edge functions use `console.error` / `console.log` only (surfaced in Supabase
  Edge Function logs). No Sentry, no error-tracking SDK, no structured
  application-log table.
- Postgres: `RAISE LOG` inside `rls_auto_enable()`. `net.http_post` request ids
  from the push webhook are stored on `trip_push_deliveries.dispatch_request_id`.
- `stdout.log`, `stderr.log`, `test_std*.log` in the repo root are stray local
  run artifacts (git-ignored pattern `*.log`), not a logging mechanism.

---

## 8. Data Volumes & Reality Check

**The live database could not be queried.** No `SUPABASE_DB_PASSWORD` is
available; the only committed anon key (`env/local.json`,
`sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH`) targets a **non-running local**
instance (`http://192.168.100.5:54341`); a direct probe of the hosted REST API
(`https://dtebgbrqynxahuzmbtbc.supabase.co/rest/v1/experiences`) returned
`401 UNAUTHORIZED_INVALID_API_KEY`. `supabase link` is configured but
`supabase db …` needs the DB password.

**Seed / catalog volumes** (from `supabase/seed.sql`, the `0018`/`0020` seed
migrations, and `supabase/dumps/data_catalog.sql`, Aug–Sep 2026):

| Table | Rows | Source |
|---|---|---|
| `experience_families` | 6 | `20260821090000` |
| `categories` | 9 base + 18 added = **27** | `0004` + `20260821090000` |
| `tags` | 16 | `20260821090000` |
| `regions` | 10 | `0004` |
| `interests` | 10 | `0004` |
| `experiences` | **30** (all seed; every `host_id` is NULL) | `seed.sql` |
| `experience_departures` | **90** (3 per experience) | `0018` |
| `itinerary_items` | **210** | `0020` |
| `host_applications` | 0 in seed; 1 demo (`20260813111000`, dev only) | runtime |
| `host_accounts` | 0 in seed; 1 demo | runtime |
| `bookings` / `booking_participants` / `payments` | not in git; `docs/SUPABASE_HOSTED_SETUP.md` notes "11 current local payment attempts … test transactions" | runtime |
| `profiles` | 0 in git (created by `handle_new_user` trigger) | runtime |
| `reviews`, `trip_messages`, `notifications` | not in git | runtime |
| `legal_documents` | 13 documents (bodies in `supabase/legal/`) | runtime load |

**Hosts by status / bookings / date range of real data:** unknown — not
queryable, and no production dump is committed.

**Design conclusion:** this is a pre-launch system with a ~30-row hand-curated
catalog, one demo host, and low-double-digit test bookings. Design the admin
panel for **tens to low hundreds of rows** at launch, but treat
`host_applications`, `bookings`, `payments`, `reviews`, and the `trip_message_*`
family as the tables that will actually grow.

---

## 9. Gaps — what an admin panel needs that does not exist yet

### 9.1 Missing role / access infrastructure

- **No way to create an admin** except a manual `UPDATE profiles SET role='admin'`
  in SQL. No invite flow, no bootstrap.
- **`admin` is a single flat value** — no staff table, no permission scopes
  (support / finance / catalog / superadmin), no per-action authorization.
- **RLS does not let an admin read business data.** `is_admin()` is wired **only**
  to the 4 config tables + `config_audit_log` + the 3 message-audit tables +
  2 moderation RPCs. There is **no** admin RLS policy on `bookings`, `payments`,
  `host_applications`, `host_accounts`, `profiles`, `experiences`, `reviews`,
  `legal_acceptances`, `experience_departures`, `booking_participants`. An admin
  panel today literally cannot list other users' bookings or host applications
  through the anon/authenticated API — it would need either new `is_admin()` RLS
  policies on every such table, or a dedicated service-role admin backend
  (no `supabase/functions/admin-*` exists).
- `/admin/message-moderation` route in Flutter has **no route guard** (relies on
  the RPC's server-side `is_admin()` check and on the profile screen hiding the
  link).

### 9.2 Missing tables

- `invoices`, invoice-number **sequence/allocation** table, `ird_sync_log` /
  `cbms_submissions` (see §6).
- `refunds` / `credit_notes` and any refund-workflow state.
- `payouts` / `host_ledger` / `settlements` and a `commission_config` (rate is a
  `0.05` literal today).
- General `admin_audit_log` (who did what across the whole system — only
  config + messages are audited).
- Host review workflow: a table for review decisions, reviewer identity, status
  transitions, and a verification checklist (only free-text `reviewer_note` +
  `reviewed_at` exist, and nothing writes them).
- `host_documents` metadata table (uploaded file size / mime / uploaded_at /
  verified flag / rejection reason — paths live only as strings in
  `host_applications.application_data` and `verification_doc_path`).
- KYC / identity-number storage (deliberately not stored today).
- Bank / payout account storage (collected, discarded).
- Support tickets / disputes / chargebacks.
- Notification templates + an outbound-notification/email log.
- `booking_cancellations` (reason, requested_by, refund linkage).

### 9.3 Missing columns

- `bookings`: buyer email / legal name / address / PAN / nationality;
  `cancellation_reason`; `cancelled_by`; `refund_amount_paisa` / `refunded_at`;
  `invoice_id`.
- `payments`: `refunded_at`, `refund_amount_paisa`, `settlement_id` / `payout_id`,
  `gateway_fee_paisa`.
- `host_applications`: `reviewer_id` (uuid, not just a note); per-transition
  timestamps / status history; `rejection_reason` structured.
- `host_accounts`: `commission_rate` override; `payout_method` + payout account;
  KYC-verified flags; PAN / business-registration number; `suspended_reason`.
- `experiences`: seller/tax attributes; no `published_at`; no `submitted_at` /
  `reviewed_by` for the `pending_review` state (which no code produces anyway).
- `profiles`: no `email` (only in `auth.users`), no `is_staff` / permission set,
  no `banned_at` / `deleted_at`, no PAN.
- `experience_departures.status` is free text, not an enum.

### 9.4 Missing status handlers / dead enum values

- Host statuses `under_review`, `action_required`, `verification` can be set but
  trigger nothing server-side.
- Booking statuses `cancellation_requested`, `cancelled`, `expired` have **no
  producer** (no cancellation flow, no `pending`-booking expiry cron).
- `payment_status = 'refunded'` has no producer.
- `experience_status` `pending_review`, `paused`, `archived` — no code path sets
  them (client experience writes were revoked; no host-side edge function
  publishes experiences).
- `notif_type = 'host_application'` is never emitted.

### 9.5 Missing indexes for admin filtering

- `host_applications`: only PK + `unique(user_id)`. **No index on `status`,
  `submitted_at`, `reviewed_at`, `category_id`, `created_at`, `updated_at`** — an
  admin queue filtered by status/date will do sequential scans.
- `payments`: PK + `unique(booking_id)` + `unique(idempotency_key)` + partial
  `unique(provider, provider_ref)`. **No index on `status`, `provider`,
  `created_at`, `paid_at`.**
- `bookings`: has `(user_id, status)`, `(departure_id)`, partial
  `(status, quote_expires_at)`. **No index on `status` alone, `created_at`,
  `experience_id`, or `completed_at`.**
- `profiles`: **no index on `role`** (needed to list hosts / staff / applicants).
- `reviews`: PK + `unique(booking_id)`. **No index on `experience_id` alone,
  `created_at`, `rating`, or `user_id`.**
- `legal_acceptances`: `user` + partial `booking`. **No index on `document_id`
  or `accepted_at`** (needed to report "who accepted Terms v1.2").
- `config_audit_log`: PK only. **No index on `table_name`, `changed_by`,
  `changed_at`.**
- `experiences`: all indexes are `status`-prefixed for published discovery; an
  admin view of drafts/paused/archived or "by host" has no supporting index
  (`host_id` FK has no explicit index).
- `host_accounts`: PK + `unique(application_id)` only — no index on `is_active`
  / `suspended_at`.

### 9.6 Other structural gaps

- **No admin backend of any kind** — no `admin-*` edge function, no service-role
  admin API, no server that could safely run cross-user queries.
- **No pagination / cursor / full-text infrastructure** for large admin lists
  (only the public `search-experiences` fn and `experiences.search_tsv`).
- `booking_ref` is random, `UNIQUE`-only, 6-digit — unsuitable as an official
  document / invoice reference (collision-prone at scale, non-sequential).
- No mechanism to resend a payment receipt, re-verify a stuck payment, or force
  a booking state (all payment/booking mutation is service-role-only and
  funnelled through `finalize_verified_payment`).
- Host bank / identity-number data required to *verify* a host is collected and
  then discarded, so a host-review admin screen has nothing to display beyond the
  uploaded document image and the questionnaire JSON.
- `device_tokens` (legacy) vs `trip_push_device_tokens` (current) split — an
  admin "notify user" feature must target the latter.
- No feature-flag / config **admin UI** exists even though the tables and RLS for
  it are ready (`app_config`, `feature_flags`, `remote_content`, `app_versions`,
  `config_audit_log`, all `is_admin()`-gated) — this is the one area where an
  admin panel could be built against existing infrastructure with no schema
  changes.
