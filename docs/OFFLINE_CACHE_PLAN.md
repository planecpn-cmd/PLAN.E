# PLAN E — Offline Cache (Implementation Plan)

Status: PROPOSED — not built yet. **Verified against the codebase and the live
database on 2026-08-10** (see §7 for what the verification pass changed).
Goal: browse and use previously-loaded data with no internet, app feels fast
(cache-first rendering), bounded disk footprint.

---

## 0. What's already there vs. what's missing

| Piece | State (verified) |
|---|---|
| `isOfflineProvider` / `OfflineBanner` | **Fake, and narrower than it looks.** `NetworkStateNotifier` ([app_providers.dart:311](../lib/providers/app_providers.dart)) is a manual toggle nothing ever sets. `isOfflineProvider` has exactly one reader (`OfflineBanner`), and `OfflineBanner` is mounted on exactly **one screen** — [booking_screen.dart:515](../lib/features/booking/booking_screen.dart). Making the provider real lights up the banner on the booking screen and nowhere else. |
| Structured data caching | **None.** Every repository hits Supabase directly; nothing persists past the session. |
| Image caching | **Exists, uncapped.** `cached_network_image` (direct dep) caches to disk using `flutter_cache_manager`'s defaults (200 objects / 30-day staleness / no byte cap). `flutter_cache_manager` itself is **transitive** — promoting it to direct is a one-line pubspec change, no new functionality. |
| Remote config caching | **Done** (phases 2–9 this session). [RemoteConfigService](../lib/core/remote_config_service.dart) is a proven cache-first + background-refresh + fail-open pattern already shipped and tested in this codebase. This plan generalizes that exact pattern rather than inventing one. |
| Local structured-data DB | **None.** `sqflite`/`path_provider` present only as *transitive* deps, unused by app code. |
| `shared_preferences` | **Direct dependency**, already used by `OnboardingPreferences`, `RecentSearchesRepository`, `RemoteConfigService`, `DeviceIdentity`. |
| `connectivity_plus` | **Absent.** Genuinely new dependency if we want real offline detection. |

---

## 1. Design decision: reuse the RemoteConfigService pattern, not a new database

| Option | Verdict |
|---|---|
| Drift / Hive — a real embedded DB | **Rejected for now.** New direct dependency (+ codegen for Drift) to solve a problem this app doesn't have. Measured against the live DB: **the entire catalog is ~40KB** — 30 experiences at 1,233 bytes average, 9 categories at 933 bytes total, 10 regions at 1,672 bytes total. A query engine is overkill for that. |
| `shared_preferences` JSON blobs, one key per query — **the RemoteConfigService pattern** | **Chosen.** Already a direct dependency, already proven in this exact codebase, zero new packages for the data layer. |
| No caching, rely on OS page cache | Rejected — doesn't survive app restart, which is the actual requirement. |

**Upgrade path:** if the catalog grows into the thousands of rows, or the app
needs offline full-text search across everything ever fetched, revisit with
Drift *then* — see phase 9, explicitly optional.

---

## 2. Architecture

### 2.1 PREREQUISITE — repositories that swallow errors must stop

**This is the finding that reorders the whole plan.** The cache-fallback
pattern in §2.2 triggers on an exception. Several repositories catch every
exception and return `[]` / `null` / `false` instead, so **the cache would
never engage for them** — silently, with no error anywhere:

| Method | Current behavior on network failure | Live? |
|---|---|---|
| `ExperienceDetailRepository.getDepartures` | `catch (_) { return []; }` | Yes |
| `ExperienceDetailRepository.getItinerary` | `catch (_) { return []; }` | Yes |
| `ExperienceDetailRepository.getReviews` | `catch (_) { return []; }` | Yes |
| `ExperienceDetailRepository.getHostProfile` | `catch (_) { return null; }` | Yes |
| `BookingFeatureRepository.getDepartures` | `catch (e) { return []; }` | Yes |
| `BookingFeatureRepository.getBookingById` | `catch (e) { return null; }` | Yes |

Two consequences, both bad:

1. **Priority-1 and priority-3 data would silently not cache.** The trail
   itinerary — the single highest-value thing to have offline — goes through
   `getItinerary()`, which swallows. The plan's headline use case would
   quietly not work.
2. **The cache would get poisoned with empty results.** A "successful" fetch
   returning `[]` (because the error was swallowed) is indistinguishable from
   a genuinely empty result, so we'd cache `[]` and serve it back later.

There's already a **user-visible bug from this today, with no caching
involved**: offline on the booking screen, `getDepartures()` swallows the
network error and returns `[]`, so
[booking_providers.dart:52](../lib/features/booking/booking_providers.dart)
throws `StateError('No bookable departures are available for this
experience.')`. The user is told the trip has no departures when they're
simply offline.

**Fix (phase 0):** let these methods propagate exceptions — the existing
`AsyncValueView` + `ErrorStateView` path already handles that correctly
everywhere they're consumed. Genuinely-empty stays `[]`; failure becomes an
exception. This is a small, self-contained correctness fix that stands on its
own merit even if the rest of this plan is never built.

**Related dead code to delete while in there:**
`BookingRepository.createBookingIntent` fabricates a booking with **hardcoded
prices** (`subtotalPaisa: 1000000, feesPaisa: 50000, totalPaisa: 1050000`) in
its catch block. It is currently **unreachable** — the booking screen uses
`BookingFeatureRepository` (a different class) — so this is not an active
bug. But a money-path method that invents Rs. 10,500 out of a caught
exception is a landmine if anyone wires it up later. Delete it and
`confirmPayment` alongside (also dead).

### 2.2 `lib/core/offline_cache.dart` — the reusable primitive

Generalizes what `RemoteConfigService` already does:

```dart
class OfflineCache {
  static Future<T?> read<T>(String key, T Function(Map<String, dynamic>) fromJson);
  static Future<void> write(String key, Map<String, dynamic> json);
  static Future<DateTime?> lastWrittenAt(String key);
  static Future<void> clear(String key);
  static Future<void> clearAll();
  static Future<void> clearWhere(bool Function(String key) test);
}
```

Same fail-open shape: a read that fails to decode returns `null`, never
throws — a corrupt cache is treated exactly like a cold one.

### 2.3 The pattern every cached repository call follows

```
1. Try the network call (ExperienceRepository already has a 12s timeout;
   apply the same elsewhere).
2. On success → write result to OfflineCache under a deterministic key,
   return it.
3. On exception → read cache for that key.
     - Hit  → return it. Stale-but-available beats an error screen.
     - Miss → rethrow. Existing AsyncValueView error state handles it
       exactly as today; no regression for a user who never loaded this
       data and has no connection.
```

Requires §2.1 to land first, or step 3 is unreachable for those six methods.

### 2.4 Cache keys

One key per distinct query, same idea as `remote_content.slot`:

- `home_rails`, `categories`, `regions`
- `experience_detail:<id>`, `experience_departures:<id>`,
  `experience_itinerary:<id>`, `experience_reviews:<id>`
- `bookings:<userId>:<status>`, `saved_experiences:<userId>`, `profile:<userId>`
- `gear_checklist:<bookingId>`, `budget_entries:<bookingId>`,
  `trip_messages:<bookingId>`

### 2.5 User-scoped cache must clear on logout

`profile:`, `bookings:`, `saved_experiences:` are user-scoped. On a shared
device, user B must never see user A's cached bookings because a fetch
failed right after login. Add a `clearWhere` call to
[logout_dialog.dart](../lib/features/profile/logout_dialog.dart)'s sign-out
handler before `signOut()`. Catalog/taxonomy/remote-config caches aren't user
data and stay.

### 2.6 Real connectivity detection

Add `connectivity_plus` and wire the existing-but-dead `isOfflineProvider`:

```dart
Connectivity().onConnectivityChanged.listen((results) {
  final offline = results.every((r) => r == ConnectivityResult.none);
  ref.read(isOfflineProvider.notifier).state = offline;
});
```

Caveat: `connectivity_plus` reports connectivity *type*, not internet
reachability — wifi with no upstream reads as "online." It's a fast-path
signal to skip a doomed network call, **not** the source of truth. The
try/fallback in §2.3 is what actually guarantees correctness.

---

## 3. What gets cached, in priority order

| Priority | Data | Why | Notes |
|---|---|---|---|
| 1 | Trip tools for an active trip — gear checklist, budget entries, trail itinerary | A trekker needs their packing list and trip guide with zero signal. This app's actual use case, not an edge case. | **Read-only under this plan — see §3.1, this is a real limitation** |
| 2 | Home rails, categories, regions | Browsing works offline; biggest visible "it's fast / it works" win, lowest risk (public, non-user-scoped). | Straightforward |
| 3 | Experience detail (ones already viewed) | Re-read a trip you browsed while you had signal. | Blocked on §2.1 |
| 4 | Bookings, saved experiences, profile | "My stuff" shows up offline. | Needs §2.5 logout hook |
| 5 | Trip chat — read-only history | Re-read past messages. Sending offline is out of scope (§5). | Realtime is off anyway (see OTA plan §1.3) |

### 3.1 The gear checklist tension — read-only caching is half a feature

Priority 1 says the gear checklist is *the* reason this matters. But
**ticking an item off is a write** (`toggleItem` → Supabase `update`), and
§5 puts offline writes out of scope. So under this plan a trekker on the
trail can *read* their packing list but every checkbox they tap will bounce
back — `GearChecklistNotifier.toggleItem` updates optimistically then
reverts on error.

That's arguably worse than useless: a checklist you can't check.

Two further wrinkles in the same repository:

- **`getItems()` is secretly a write.** It auto-seeds ten default items via
  `INSERT` when the list comes back empty
  ([gear_checklist_repository.dart:34](../lib/repositories/gear_checklist_repository.dart)).
  Offline, the `select` throws before reaching it, so the fallback path is
  fine — but any caching layer must never cache an empty result for this
  key, or it'll serve `[]` and skip seeding forever.
- The same applies to `addItem` / `deleteItem`.

**Decision needed before building phase 6** — pick one:

- **(a)** Ship gear checklist as read-only offline, and be explicit in the UI
  ("offline — changes will not be saved"). Cheap, honest, partially useful.
- **(b)** Build a minimal write queue *just for gear checklist toggles* — a
  local `is_checked` overlay that reconciles on reconnect. Genuinely useful,
  meaningfully more work, and the toggle case is unusually well-suited to it
  (idempotent, last-write-wins, no money involved).
- **(c)** Drop gear checklist from priority 1 and lead with the trail
  itinerary (pure read, no tension) instead.

Recommendation: **(c) for the first cut, (b) as a fast follow.** The itinerary
delivers the "works on the trail" promise with none of the write complexity;
the checklist toggle queue is then a small, well-scoped second step.

**Not cached, by design:** arbitrary search/filter combinations (would need
the full catalog client-side — that's the Drift upgrade, §9); the
notifications feed (freshness matters more); AI itinerary generation (live
LLM call, nothing to cache).

---

## 4. Bounding disk usage

### 4.1 Structured JSON cache — a non-issue at current volumes

Measured: whole catalog ≈40KB. Even caching every experience detail,
booking, and trip tool for a heavy user stays in the low single-digit MB.
Still worth a **soft cap (~5MB total) with least-recently-written eviction**
via a small manifest (key → timestamp + byte size) so it can't grow
unbounded through some path nobody anticipated. Cheap to implement,
unit-testable.

### 4.2 Image cache — the space risk is *future*, not current

**Correction from the verification pass.** An earlier draft implied the image
cache is already a 100–300MB problem. Measured against the live database, it
isn't:

- **7 distinct cover images across all 30 experiences** (the seed data reuses
  the same Unsplash photos).
- **Zero gallery images** — `gallery` is empty on every row.

So today's realistic image cache is **~7 files, low single-digit MB**. The
uncapped default config is a *latent* risk that only bites once real content
lands (unique photo per experience, populated galleries), not a fire today.
**Phase 7 accordingly drops down the order** — it's future-proofing, not
urgent.

When it is done, two changes, both centred on
[app_photo.dart](../lib/widgets/app_photo.dart) (`PlanEPhoto` — the shared
widget; only two other files use `CachedNetworkImage` directly,
`experience_card.dart` and `itinerary_screen.dart`, and routing those through
`PlanEPhoto` is a worthwhile side-cleanup):

1. **A custom `CacheManager`** with an explicit named config — capped object
   count and staleness instead of library defaults. Hard ceiling, automatic
   LRU eviction.
2. **Request appropriately-sized images.** Verified: **100% of current
   `cover_image_url`s are `images.unsplash.com` and carry a `w=` param**
   (mix of `w=1000` and `w=800`), so a URL-rewrite helper works across the
   whole catalog today. Rail/grid cards render at 148–260px but download
   800–1000px — roughly 4–7x the pixels needed. Trimming `w=` per render
   context (≈`w=400` for cards, full size only for the detail hero) saves
   bytes *before* they're downloaded or cached, which beats any eviction
   policy.
   **Caveat:** this only applies to Unsplash-style URLs. Profile avatars go
   to Supabase Storage ([profile_repository.dart](../lib/repositories/profile_repository.dart))
   with no such param, and a future real image host will need its own
   equivalent (Supabase Storage transforms). The helper must pass through
   URLs it doesn't recognise unchanged.

---

## 5. Explicitly out of scope

- **Writing while offline** — bookings, payments, chat sends, reviews, host
  applications. These need connectivity by nature. This plan's contribution
  is making them fail with an honest "you're offline" message instead of a
  misleading one (see the §2.1 departures bug). The one place this
  limitation genuinely hurts is the gear checklist — see §3.1.
- **Offline search/filtering across the whole catalog** — see §1 / phase 9.

---

## 6. Implementation phases

| # | Phase | Notes |
|---|---|---|
| **0** | **Stop swallowing errors** in `ExperienceDetailRepository` (4 methods) and `BookingFeatureRepository` (2 methods); delete dead fabricated-price `BookingRepository.createBookingIntent`/`confirmPayment` | **New — prerequisite.** Nothing downstream caches correctly without it. Fixes a real user-visible bug on its own (§2.1). |
| 1 | Real connectivity detection — add `connectivity_plus`, wire `isOfflineProvider` | Foundation |
| 2 | `OfflineCache` primitive + soft size cap | Pure infra, no visible change, unit-testable without a device |
| 3 | Catalog data — home rails, categories, regions | Lowest risk, highest visible win |
| 4 | Experience detail + departures/itinerary/reviews | Depends on phase 0 |
| 5 | User-scoped — profile, bookings, saved. **Include the logout-clear hook (§2.5) in this phase, not after** | |
| 6 | Trip tools — **trail itinerary first** (pure read), budget entries, read-only chat history. Gear checklist per the §3.1 decision | Highest real-world value; deliberately after the pattern is proven on lower-stakes data |
| 7 | Image cache tuning — custom `CacheManager` + `w=` trimming | **Demoted** — future-proofing, not urgent (§4.2) |
| 8 | Offline UX — real `OfflineBanner`, and **mount it beyond the single booking screen**; honest "needs internet" messaging on write actions | More work than "wire the provider" (§0) |
| 9 | *(Optional)* Offline search — full-catalog snapshot + client-side filter | Only if usage shows demand |
| 10 | *(Optional)* Offline write queue — gear checklist toggles first, then chat outbox | The §3.1 (b) option |

Each phase gets the same rigor as the OTA work: unit tests for every fallback
branch (cache hit, miss, malformed, network failure) plus a real check on the
A55, not just `flutter analyze` passing.

---

## 7. What the verification pass changed

Recorded so the diff from the first draft is auditable:

1. **Added phase 0** — six error-swallowing methods would have silently
   defeated the cache fallback for the plan's highest-value data. Biggest
   correction; reordered the plan.
2. **Surfaced a live bug** — offline booking screen reports "No bookable
   departures are available" instead of an offline state.
3. **Flagged the gear-checklist contradiction** (§3.1) — ranked #1 but
   read-only under a plan that excludes offline writes; a checklist you can't
   tick. Added an explicit decision point with a recommendation.
4. **Corrected the image-cache size claim** (§4.2) — measured 7 distinct
   images / 0 gallery images, so the risk is future not current; demoted
   phase 7 from 7th-of-10-urgent to explicitly non-urgent.
5. **Confirmed the no-database decision with real numbers** — 40KB total
   catalog, measured, not estimated.
6. **Narrowed the `w=` claim** — verified 100% coverage of current cover
   images, but excluded Supabase Storage avatars.
7. **Corrected the `OfflineBanner` scope** — one screen, not app-wide; phase
   8 is bigger than it looked.
8. **Noted dead code** — `BookingRepository`'s fabricated-price fallback is
   unreachable today (not an active bug) but worth deleting.

Also noted for testing: `itinerary_items` is **empty (0 rows) in the local
database** despite migration `0020_seed_itinerary_items.sql`, because
`supabase/seed.sql` truncates it. Anyone testing offline itinerary caching
locally needs to seed that table first or they'll be testing the empty path.
