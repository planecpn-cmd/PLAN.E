# PLAN E — Over-The-Air Updates: How It Works & How To Push One

Status: **built and verified** (phases 2–9 of [OTA_UPDATES_PLAN.md](OTA_UPDATES_PLAN.md)).
Shorebird (binary patches) is **permanently excluded** — data sovereignty
requirement (no data may leave Nepal); Shorebird routes app binaries and
every device's update-check traffic through its own cloud infrastructure
outside Nepal. Not a "not set up yet." See §5.

This doc has two audiences: the "push a change" section is written for anyone
on the team who needs to flip a flag or edit copy, no engineering background
assumed. The "how it works" section is for engineers extending the system.

---

## 1. One track, not two

The original design had a second track — Shorebird, for shipping an actual
Dart code fix without a store release. **That's excluded**: this project
runs entirely on Nepal-hosted infrastructure with a hard "no data leaves
Nepal" requirement, and Shorebird can't satisfy that — see §5 for why.

So there's one track: **remote config** (this doc). Edit a row in Supabase,
users pick it up next time they open or foreground the app — no app store
release, no waiting for review, and nothing leaves your own infrastructure.
A genuine code bug (not a setting) still needs a normal Play Store / App
Store release — there is no faster path for that under this constraint.

---

## 2. Pushing a remote config change (no engineering needed)

1. Open Supabase Studio for the project (ask an engineer for the link/login
   if you don't have it — it's the same project the app's database lives in).
2. Go to **Table Editor**, pick one of four tables:
   - `feature_flags` — turn something on/off
   - `remote_content` — edit copy, banners, merchandising rules
   - `app_versions` — force-update / maintenance mode
   - `app_config` — misc key/value settings (nothing uses this yet)
3. Edit the row, save.
4. Done. No deploy, no build, no app store submission.

**When do users actually see it?** Not instantly — there's no live push
(see §6). A user sees the change:
- The next time they **cold-start** the app, or
- The next time they **bring it back to the foreground** after backgrounding
  it (the app refreshes config every time it resumes).

A user who has the app open right now and never backgrounds it won't see
the change until they do one of those two things.

**Every change is logged.** `config_audit_log` records who changed what,
old value, new value, and when — visible to admins in Supabase Studio. This
is the accountability trail; there's no separate admin UI, and none is
planned — the audit log plus direct table editing is the whole workflow by
design (see [OTA_UPDATES_PLAN.md §3](OTA_UPDATES_PLAN.md)).

**Only admins can write.** Anyone can read these tables (that's how the app
fetches them), but only a `profiles.role = 'admin'` account can insert,
update, or delete a row — enforced by the database itself (Postgres RLS),
not just app-level checks. See §7 for why this matters.

---

## 3. What exists right now

Everything below is live in the shipped code — flip the flag/edit the slot
and it takes effect on next app open/resume.

### 3.1 `feature_flags` rows in use

| `key` | What it controls | Set `enabled = false` to… | Code |
|---|---|---|---|
| `payment_esewa` | The eSewa option in the checkout payment picker | Pull eSewa from checkout entirely (not greyed out — gone) when the gateway is down | [booking_screen.dart](../lib/features/booking/booking_screen.dart) |
| `ai_itinerary` | The "Plan with AI" entry point (home CTA + the `/ai-planner` screen itself) | Hide the CTA on home *and* show an "AI Planning Unavailable" message if someone still lands on the screen — covers deep links and a flag flip mid-session | [home_screen.dart](../lib/features/home/home_screen.dart), [ai_itinerary_screen.dart](../lib/features/ai_itinerary/ai_itinerary_screen.dart) |

**No row for a key = the feature behaves as if this system doesn't exist**
(fails open). You don't need to create a row for every feature — only ones
you actually want to be able to kill or gate.

Each flag row also supports (all optional, default = no restriction):

- `rollout_percent` (0–100) — a gradual rollout. Same user always lands on
  the same side of the percentage (stable per user, not re-randomized each
  session).
- `platforms` (array of `ios`/`android`/`windows`/`web`) — restrict to
  specific platforms. Leave it as all four (the default) for no restriction.
- `min_app_version` / `max_app_version` — restrict by installed app version.

### 3.2 `remote_content` slots in use

| `slot` | Payload shape | Effect | Code |
|---|---|---|---|
| `promo_banner` | `{"headline": "...", "subtitle": "...", "cta_label": "...", "cta_route": "..."}` (subtitle and the cta pair are optional) | Shows a banner on home, above the rails. No row = no banner (nothing shows today until this is configured). | [home_screen.dart](../lib/features/home/home_screen.dart) |
| `onboarding_slides` | JSON array of `{"title": "...", "description": "..."}`, matched by position to the 3 onboarding slides | Overrides slide copy. Icons and slide count stay fixed — only text is editable this way. A short array only overrides the first N slides; the rest keep their built-in copy. | [onboarding_slide_screen.dart](../lib/features/onboarding/onboarding_slide_screen.dart) |
| `home_rail_rules` | JSON array of `{"key": "...", "category_slug": "..."?, "terms": ["...", ...]?}` | Redefines which experiences land in which home rail — the merchandising rails (currently `community`, `adventure-together`, `mind-soul`, `give-back`). An experience matches a rule if it's in `category_slug` OR its title/summary/description/things-to-know text contains any `terms` word. Empty array = zero rule-based rails. **One malformed entry reverts the whole payload to the built-in defaults** — it's all-or-nothing, not a partial merge, so a typo can't half-break merchandising. | [home_rail_rule.dart](../lib/models/home_rail_rule.dart) |

`recommended`, `trending`, and `homestays` (the other 3 home rails) are
**not** remote-configurable — they're computed directly (catalog-wide sort,
category filter), not keyword-matched, so there's nothing to override.

### 3.3 `app_versions` — force-update / maintenance

One row per platform (`platform` = `ios`/`android`/`windows`/`web`):

- `maintenance_mode = true` → full-screen block, nobody gets past it. Use
  `maintenance_message` for the text users see.
- `min_supported_version` set above what a user has installed → full-screen
  "Update Required" block. Android gets a working "Update Now" button
  straight to the Play Store; **iOS doesn't yet** (needs a numeric App Store
  ID we don't have configured — flagged as a known gap in the code).
- `latest_version` set above what a user has, but they're still ≥
  `min_supported_version` → a dismissible "Version X is available" banner,
  app stays fully usable.
- No row for a platform → no gate at all on that platform.

Maintenance beats force-update beats the soft nudge — only the highest-
priority one applies at a time. Code: [version_gate.dart](../lib/widgets/version_gate.dart).

---

## 4. Adding something new — the pattern

Every flag/slot above followed the same four steps. Do the same for the
next one:

1. **Decide the shape.** Pick a `feature_flags.key` or a `remote_content.slot`
   name. No schema change needed — these are generic tables, any key/slot
   works without touching the database.
2. **Read it in the app.**
   - A flag: `ref.watch(featureFlagProvider('your_key')) ?? <default>`.
     Get the `??` default right — it's what every existing user sees before
     anyone ever touches the flag, and if the row gets deleted later.
   - Content: `ref.watch(remoteContentProvider('your_slot'))`, then parse
     defensively (a `PromoBannerContent`/`HomeRailRule`-style `tryParse`
     that returns `null`/falls back on anything malformed — never throws).
3. **Test the fallback branches**, not just the happy path: missing key,
   malformed payload, partial payload. This is where a real bug would ship —
   the whole point of this system is that a bad remote value can't crash a
   screen or strand a user, and that only holds if the fallback path is
   actually exercised, not assumed.
4. **Ship it disabled/unconfigured first**, confirm nothing changed for
   users, *then* configure the real value in Supabase Studio.

---

## 5. Shorebird — excluded, not "pending"

The original plan had Shorebird as Track A: real Dart code patches, no
store review, for actual bug fixes rather than settings. **This project
does not use it, and won't** — it conflicts with a hard data-sovereignty
requirement (nothing leaves Nepal-hosted infrastructure).

Why it conflicts, specifically:

- `shorebird release`/`shorebird patch` uploads your compiled app binary
  and patch diffs to Shorebird's own cloud servers — the code artifact
  itself leaves your infrastructure and lives on theirs.
- Every installed app checks in with Shorebird's servers (outside Nepal) on
  every launch to see if a patch is available — that's a recurring network
  call from every user's device to third-party infrastructure you don't
  control, carrying device/app identifiers and IP addresses.

Neither of those is "user data" in the traditional sense, but both are data
leaving Nepal to a third party on an ongoing basis — exactly what the hard
requirement rules out. There's no self-hosted version of Shorebird to fall
back to.

**The consequence:** a genuine Dart code bug (not a setting, not content)
has no faster path than a normal Play Store / App Store release. The remote
config system in this doc is the *only* no-release update mechanism
available under this constraint — which is also why getting the fail-open
fallback right on every flag/content read (§4) matters more here than it
would on a project that has Shorebird as a safety net for a bad remote
value slipping through.

---

## 6. Why nothing is instant (and when it will be)

Supabase Realtime is **disabled** for this project
(`supabase/config.toml` → `[realtime] enabled = false`), so there's no live
push — config only refreshes on cold start and foreground-resume (see
§2). This also means the in-app trip chat (`trip_messages`) isn't actually
live today, which is a separate, pre-existing gap this system didn't
create but does share the same fix.

Turning Realtime on (flip the config flag, add the four config tables to
the `supabase_realtime` publication) is documented as an optional future
phase — worth doing eventually, not currently blocking anything in this
doc.

---

## 7. Safety rails (why this doesn't turn into a footgun)

- **Fail-open, everywhere.** Missing row, malformed payload, network
  failure, corrupt local cache — every one of these falls back to "behave
  like this system doesn't exist," never a crash. Verified with dedicated
  tests for every fallback branch, not just the happy path.
- **Admin-only writes, enforced by the database.** `feature_flags`,
  `remote_content`, `app_versions`, `app_config`, and `config_audit_log` all
  have Postgres row-level security requiring `profiles.role = 'admin'` for
  any insert/update/delete. This was tested directly against a running
  database: a non-admin signed-in user gets a hard RLS rejection attempting
  to write any of these tables; an admin succeeds and the write is logged.
- **Full audit trail.** Every write to a config table is logged to
  `config_audit_log` with who/when/old-value/new-value, automatically, via a
  database trigger — not something the app or the person editing it has to
  remember to do.
- **Kill switch always wins.** For flags, `enabled = false` overrides
  rollout percentage, platform targeting, and version bounds — there's no
  configuration that can accidentally re-enable something an admin turned
  off.
- **No new dependency for the risky bits.** Version comparison and rollout
  bucketing are both hand-written (not a transitive package pulled in
  implicitly) specifically so their behavior is fully under this repo's
  control and fully unit-tested.

---

## 8. Where things live (for engineers)

| Piece | File |
|---|---|
| DB schema, RLS, audit trigger | [supabase/migrations/0021_remote_config.sql](../supabase/migrations/0021_remote_config.sql) |
| Fetch + local cache | [lib/core/remote_config_service.dart](../lib/core/remote_config_service.dart) |
| Models | [lib/models/remote_config.dart](../lib/models/remote_config.dart), [home_rail_rule.dart](../lib/models/home_rail_rule.dart), [promo_banner.dart](../lib/models/promo_banner.dart) |
| Riverpod providers (`featureFlagProvider`, `remoteContentProvider`, `appConfigProvider`, `appVersionGateProvider`) | [lib/providers/remote_config_providers.dart](../lib/providers/remote_config_providers.dart) |
| Version compare, gate decision logic | [lib/core/app_version.dart](../lib/core/app_version.dart) |
| Rollout hashing/bucketing, full flag evaluation | [lib/core/feature_flag_evaluation.dart](../lib/core/feature_flag_evaluation.dart) |
| Force-update/maintenance UI | [lib/widgets/version_gate.dart](../lib/widgets/version_gate.dart) |
| Guest bucketing id | [lib/core/device_identity.dart](../lib/core/device_identity.dart) |
| Boot wiring (cache-first load, background refresh, foreground-resume refresh) | [lib/main.dart](../lib/main.dart) |
| Tests | `test/remote_config_test.dart`, `test/version_gate_test.dart`, `test/payment_gateway_flag_test.dart`, `test/phase7_remote_content_test.dart`, `test/home_rail_rule_test.dart`, `test/feature_flag_evaluation_test.dart`, `test/feature_flag_provider_wiring_test.dart` |

Every piece above was verified against a real local Supabase instance
(migration applied, RLS tested with real non-admin/admin sessions, REST
responses fetched and confirmed to match the Dart parsing exactly) in
addition to unit tests — not just reviewed by eye.
