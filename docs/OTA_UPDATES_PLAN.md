# PLAN E — Over-The-Air Update System (Implementation Plan)

Status: **phases 2–9 built and verified** (DB schema through rollout %/version
targeting) as of 2026-08-10. Phase 1 (Shorebird) is **permanently excluded** —
project self-hosts in Nepal under a hard "no data leaves Nepal" requirement,
and Shorebird's cloud-hosted patch delivery can't satisfy that (see
[OTA_UPDATES_GUIDE.md](OTA_UPDATES_GUIDE.md) §5 for why). Phase 10 (Realtime)
is still open, optional. That guide is the one to hand the team; this doc
stays as the original design record — read §0 and §1.6 below with that
exclusion in mind, they predate the sovereignty requirement being confirmed.

## 0. Why this differs from the React Native version

The reference material describes React Native OTA (CodePush-style): swap the JS
bundle at runtime, no store review needed. PLAN E is **Flutter**, compiled to
native machine code — there is no JS bundle to swap. Two separate mechanisms
replace it:

| Track | What it updates | Store review? | Tool |
|---|---|---|---|
| **A. Binary patch OTA** — **excluded, see below** | Actual Dart code (bug fixes) | No | [Shorebird](https://shorebird.dev) |
| **B. Remote config OTA** | Flags, copy, content, kill switches, force-update | No | Supabase (self-hosted) |

Track A replaces "hotfix a crash without a store release." Track B replaces
"feature flagging / server-driven UI / instant kill switch" — the bulk of what's
actually useful day to day, and the part every feature in the app can hook into.

Apple/Google allow Track A for bug fixes (no new features, no new permissions,
no new native code) — that's Shorebird's model. Track B is server data; no store
rule applies.

**Track A is excluded from this project.** Shorebird patches are delivered by
uploading your compiled app binary/patch diffs to Shorebird's own cloud, and
every installed app pings Shorebird's servers on every launch to check for
one — both are data leaving Nepal to infrastructure you don't control, on an
ongoing basis. That's incompatible with this project's hard data-sovereignty
requirement. There's no self-hosted Shorebird to fall back to. A real Dart
code bug (not a setting) goes through a normal Play Store / App Store release
under this constraint — see [OTA_UPDATES_GUIDE.md](OTA_UPDATES_GUIDE.md) §5.

(The platform-limit note below is left for the historical record — it never
became relevant once Track A was excluded.) Shorebird platform limits:
Android and iOS only; this repo also has `windows/` and `web/` targets, which
Shorebird never covered regardless.

---

## 1. Architecture

### 1.1 New Supabase tables — migration `0021_remote_config.sql`

Existing migrations run to `0020_seed_itinerary_items.sql`, so **0021 is the next
free number** (an earlier draft of this doc said 0018 — that collides with
`0018_seed_experience_departures.sql`).

```sql
create table public.app_config (
  key text primary key,
  value jsonb not null,
  description text,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id)
);

create table public.feature_flags (
  key text primary key,
  enabled boolean not null default false,
  rollout_percent int not null default 100 check (rollout_percent between 0 and 100),
  platforms text[] not null default array['ios','android','windows','web'],
  min_app_version text,
  max_app_version text,
  description text,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id)
);

create table public.remote_content (
  slot text primary key,        -- e.g. 'home_sections', 'onboarding_slides', 'promo_banner'
  schema_version int not null default 1,
  payload jsonb not null,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id)
);

create table public.app_versions (
  platform text primary key,    -- 'ios' | 'android' | 'windows' | 'web'
  min_supported_version text not null,   -- below this: hard block, force update
  latest_version text not null,          -- above installed: soft nudge banner
  maintenance_mode boolean not null default false,
  maintenance_message text
);

create table public.config_audit_log (
  id uuid primary key default gen_random_uuid(),
  table_name text not null,
  row_key text not null,
  old_value jsonb,
  new_value jsonb,
  changed_by uuid references public.profiles(id),
  changed_at timestamptz not null default now()
);
```

Each table also gets the shared `set_updated_at()` trigger from
`0001_extensions.sql`, matching every other table in the schema.

### 1.2 SECURITY — RLS is mandatory, not optional, on these tables

`0016_grants.sql` does two things that make this critical:

```sql
grant insert, update, delete on all tables in schema public to authenticated;
alter default privileges in schema public grant insert, update, delete on tables to authenticated;
```

The `alter default privileges` line means **every new table automatically grants
write access to any logged-in user.** RLS is the only thing standing between a
random signed-up traveler and rewriting your feature flags, kill switches, and
force-update gate. If `enable row level security` is forgotten on even one of
these five tables, that table is world-writable by anyone with an account.

So migration 0021 must, without exception:

```sql
alter table public.app_config      enable row level security;
alter table public.feature_flags   enable row level security;
alter table public.remote_content  enable row level security;
alter table public.app_versions    enable row level security;
alter table public.config_audit_log enable row level security;
```

Then: public `select` for anon + authenticated on the four config tables (they
must be readable before login — the force-update gate runs pre-auth); writes
restricted to admins only; `config_audit_log` readable by admins only.

**There is no `is_admin()` helper in this schema yet** — `0009_trip_tools.sql`
defines `is_trip_member()`, and that's the only membership helper. Migration 0021
must define one, following the same `security definer` style as
`handle_new_user()` in `0003_profiles_trigger.sql`:

```sql
create or replace function public.is_admin()
returns boolean as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$ language sql security definer stable;
```

`profiles.role` is already a `user_role` enum including `'admin'`, and
`prevent_profile_role_escalation()` already blocks non-service-role clients from
promoting themselves — so this helper is safe to trust. Grant the admin write
policies off it. **Verify this by attempting a write as a normal test user
before shipping phase 2** — it's the one thing in this plan with a real blast
radius if it's wrong.

### 1.3 Client: `lib/core/remote_config_service.dart`

Follows the existing `AppSupabaseClient` / `OnboardingPreferences` pattern in
`lib/core/` — a static class with an `initialize()` awaited in `main()` — plus
Riverpod providers in `lib/providers/` alongside `app_providers.dart`.

**Boot ordering matters.** `main()` currently does:

```dart
await OnboardingPreferences.initialize();   // shared_preferences, fast, local
await AppSupabaseClient.initialize();       // network (and a demo sign-in in dev)
runApp(...)
```

Do **not** add a blocking network fetch here — it delays every cold start, and
config is not needed for the first frame. Instead:

1. `initialize()` reads the last-known-good payload out of `shared_preferences`
   **synchronously-ish** (one await, local disk, same cost as
   `OnboardingPreferences`) and returns. This is what the first frame uses.
2. The network refresh fires *unawaited* right after `runApp`. The splash screen
   runs for ~2 800 ms + 350 ms hold (`splash_screen.dart`) — a natural window
   where a refresh completes invisibly before the user reaches `/home`.
3. First-ever launch has no cache: every read falls back to its hard-coded
   default, which is exactly current shipped behavior. Nothing blocks, nothing
   crashes.

**Realtime is not currently usable and needs enabling first.**
`supabase/config.toml` has `[realtime] enabled = false`, and no migration
anywhere adds a table to the `supabase_realtime` publication — so
`TripChatRepository.streamMessages()` today gets an initial snapshot and no live
updates. Two consequences:

- Don't plan on Realtime config push in phase 3. Use foreground-resume refresh
  instead (`main.dart` already has a `didChangeAppLifecycleState` observer with
  a `_pausedAt` clock — hook the refresh there).
- Enabling Realtime properly (flip the config flag, add tables to the
  publication) is worth doing as its own task, since it also fixes trip chat.
  Treat live config push as a phase-10 nice-to-have, not a phase-3 requirement.

Providers to expose: `featureFlagProvider(key)`, `remoteContentProvider(slot)`,
`appConfigProvider(key)`, `appVersionGateProvider`. Every call site keeps a
hard-coded fallback default.

### 1.4 Version reporting needs a real source

`more_settings_screen.dart:231` hardcodes `'Version 1.0.0 (Build 104)'` while
`pubspec.yaml` says `version: 1.0.0+1`. They already disagree. A force-update
gate that compares against a hand-typed string is worthless.

Two options, pick one:

- **`package_info_plus`** — reads the real version/build from the platform
  bundle. One new dependency. Correct on all platforms. Recommended.
- **A `--dart-define` or generated Dart constant** written by the build script —
  no new dependency, but one more thing to keep in sync by hand.

(An earlier draft of this doc claimed "no new pub dependency required." That
holds for flags and content — Supabase, Riverpod, and `shared_preferences` cover
those — but not for version reporting.)

While you're in there, fix the hardcoded string in `more_settings_screen.dart`
to read from the same source.

### 1.5 l10n constrains what "remote copy" can mean

The app uses compile-time ARB localization (`l10n.yaml`, `generate: true`,
`lib/l10n/app_localizations.dart` is generated, en + ne). Any string reached via
`l10n.someKey` **cannot** be changed remotely — it's baked into the binary at
build time.

What *is* remotely changeable is the substantial amount of hardcoded English
copy: home rail subtitles ("Handpicked experiences based on popular journeys"),
`onboarding_slide_screen.dart`'s `_slides` list, `ExperienceStrings`,
`MapStrings`, `TripToolsStrings`, and the AI planner's option lists. Those are
plain Dart constants and are fair game.

Rule of thumb: **remote content carries structure and non-localized copy;
anything bilingual stays in ARB.** If a slot genuinely needs both languages,
store `{"en": "...", "ne": "..."}` in the JSONB payload and select on
`profile.language` — but don't retrofit the whole app that way.

### 1.6 Shorebird (Track A) — excluded, kept here for the historical record only

This section describes what Track A would have looked like; it is **not
being implemented**, per the data-sovereignty exclusion in §0.

- `shorebird init` in repo root, creates `shorebird.yaml`.
- Release builds: `shorebird release android` / `shorebird release ios` instead
  of `flutter build`.
- Hotfix a shipped release: `shorebird patch android|ios` — ships a binary diff;
  installed apps pick it up on next launch, no store review.
- Hard rule: patches only for bug fixes to existing Dart logic. Any new asset,
  new permission, new plugin, or new native code needs a normal store release.
- Requires a Shorebird account — user-facing signup, not something Claude can do
  for you.
- Windows and web builds continue to ship the normal way.

---

## 2. Every feature that can hook into this

Verified against actual files — each row names a real hook point.

| Feature area | What becomes remote-controllable | Where |
|---|---|---|
| App boot | Force-update gate, maintenance mode, "update available" nudge | `main.dart` `MaterialApp.router` `builder:` — wrap alongside `ScaledAppViewport`. Not a go_router `redirect`: that callback is synchronous and can't await config. |
| Onboarding | Slide copy/images/order | `onboarding_slide_screen.dart` `_slides` (hardcoded list, no l10n — easy win) |
| Home | Rail order/visibility, promo banner, hero copy, CTA labels | `home_screen.dart` — 7 rails currently hardcoded as `if (railsMap['x']?.isNotEmpty ?? false)` blocks |
| Home rail *content* | Which experiences land in which rail | `ExperienceRepository.getHomeRails()` — rails are built by **hardcoded keyword matching** (`'yoga'`, `'monastery'`, `'rafting'`…). Moving those term lists to `remote_content` is the single highest-leverage change in this plan: it makes merchandising editable without a release. |
| Explore/Search | Default sort, featured filters | `explore_screen.dart`, `search_results_screen.dart` |
| AI Itinerary | Kill switch (fall back to manual planning if the LLM provider is down) | `ai_itinerary_screen.dart` + `/ai-planner` CTA on home. `AiItineraryNotifier` already catches and surfaces errors, so the fallback path exists. |
| Booking / Payment | Per-gateway kill switch — pull a broken gateway instantly | `booking_screen.dart` — the Khalti/eSewa picker in `_showPaymentIntentModalSheet`, and `_selectedGateway` (currently `final String _selectedGateway = 'khalti'`) |
| Trip tools | Default gear checklist, budget categories | `GearChecklistRepository.defaultTrekGear` (hardcoded 10 items), `TripToolsStrings.expenseCategories` |
| Host flow | Which steps are required, verification copy, district/bank lists | `host_provider.dart` `HostApplicationData` defaults |
| Notifications | Which notif types are enabled | `notification_feed_screen.dart` |
| Any screen | A/B bucket via `rollout_percent` + stable hash of `profile.id` | — |

### Two things worth fixing while you're in here

- **`isOfflineProvider` is fake.** `NetworkStateNotifier` in `app_providers.dart`
  is a manual toggle — nothing in the app ever sets it from real connectivity, so
  `OfflineBanner` never appears on its own. If you want the config system's
  offline story to be honest, wire real connectivity detection
  (`connectivity_plus`, not currently a dependency). Separate task; flagging it
  because the plan's "works offline" claim leans on it.
- **Settings toggles are cosmetic.** Dark mode, offline maps, and clear-cache in
  `more_settings_screen.dart` only call `setState` and show a toast — none of them
  do anything. Same for the language picker in `language_region_screen.dart`,
  which doesn't change the app locale. Not blockers for this plan, but don't
  point the team at them as examples of "settings that work."

---

## 3. Rollout mechanics & safety rails

- **Staged rollout**: `rollout_percent` bucketed by a stable hash of `user.id`.
  Note the dev environment auto-signs-in a demo user
  (`AppSupabaseClient.initialize()` reads `DEMO_EMAIL`/`DEMO_PASSWORD` from
  `env/local.json`), so **every dev device lands in the same bucket** — test
  bucketing against a real ID range, not by relaunching locally.
- Guests have no Supabase session at all (they're tracked only via
  `OnboardingPreferences`), so bucketing needs a device-local fallback id
  persisted in `shared_preferences`.
- **Platform/version targeting**: `platforms[]` + `min/max_app_version`.
- **Kill switch**: `enabled = false` overrides rollout and targeting entirely.
- **Fail-open**: every call site keeps a hard-coded fallback; missing or
  malformed config = current shipped behavior, never a crash.
- **Schema versioning**: `remote_content.schema_version` lets an old client
  ignore a payload shape it doesn't understand.
- **Audit log**: every change records who/when/old/new — accountability without
  building an admin panel. Edit rows directly in Supabase Studio.

---

## 4. Implementation phases (each independently shippable)

1. ~~**Shorebird setup**~~ — **excluded**, data-sovereignty requirement (§0).
   Not being done.
2. **DB schema** — migration `0021_remote_config.sql`: tables, `is_admin()`,
   RLS on all five tables, admin-write policies, audit trigger. **Verify a
   normal user cannot write** before moving on (see §1.2).
3. **Version source** — add `package_info_plus`, expose a `appVersionProvider`,
   fix the hardcoded string in `more_settings_screen.dart`. Tiny, unblocks 5.
4. **`RemoteConfigService`** — cache-first boot, background refresh, refresh on
   foreground resume, Riverpod providers. No feature wired to it yet.
5. **Force-update / maintenance gate** — wire `app_versions` into
   `MaterialApp.router`'s `builder`. Highest value first: this is the one thing
   you'll actually need in an emergency.
6. **First real flag** — one low-risk toggle end to end (`payment_esewa` kill
   switch). Proves the whole pipe before spreading it everywhere.
7. **Spread flags** — AI itinerary kill switch, promo banner, onboarding
   content. One PR per feature area, not one giant PR.
8. **Home rail keyword lists → `remote_content`** — the merchandising win.
9. **Rollout % + version targeting** — add once you have >1 flag actually in
   use. Building it earlier is premature.
10. **(Optional) Enable Realtime** — flip `config.toml`, add tables to the
    `supabase_realtime` publication, subscribe for live config push. Also fixes
    trip chat, which is silently non-live today.
11. **Write `OTA_UPDATES_GUIDE.md`** — how it works, how to push a flag change.
    Written for the team once the above is real and testable.

Each phase is a separate PR. Nothing in phase N blocks starting phase N+1's
code, but don't ship N+1 to production ahead of N.
