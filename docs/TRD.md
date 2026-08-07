# PLAN E — Technical Requirements Document (TRD)

Version 2.0 · 3 August 2026 · **Flutter / Dart** · Mobile-only Nepal adventure & experience-discovery app
Source of truth order: App Flow Document v1.0 > UI/UX Design Report v1.0 > this TRD > agent judgement.

> **v2.0 change:** the stack moved from React Native/Expo to Flutter. Reason: the maintainer works
> in Dart, Khalti and eSewa ship official Flutter SDKs, and Flutter's own rendering engine gives
> consistent performance on the low-end Android hardware that dominates the Nepali market. The
> database, schema, and all product documents are unchanged — they were never language-specific.

---

## 1. Scope

Build the mobile client + backend for PLAN E: discover, save, book and review Nepal adventure
experiences; manage upcoming plans; apply to become a host.

In scope: guest browsing, auth, interests, discovery, search/filter, experience detail, booking,
Nepal payment (Khalti/eSewa), plans, itinerary, trip chat, gear checklist, budget tracker, trip
history, reviews, profile/settings, 4-step host application.

Out of scope v1: admin dashboard, host operations console after approval, web/tablet, automated
refunds, offline write sync, multi-currency (NPR only).

---

## 2. Stack decisions

| Layer | Choice | Reason |
|---|---|---|
| App | **Flutter 3.24+ / Dart 3.5+** | One codebase, own rendering engine — identical output on cheap Android and iOS, no bridge, no JS GC pauses on photo-heavy scroll. Maintainer already writes Dart. |
| Routing | `go_router` | Declarative, deep-link native, path-per-screen maps 1:1 onto App Flow screen IDs. |
| State / async | `flutter_riverpod` (v2, code-gen off) | `AsyncValue` models loading/data/error as an exhaustive switch — the App Flow's three-state requirement becomes compiler-enforced, not a checklist. Providers replace both TanStack Query and Zustand. |
| Backend | Supabase (Postgres 15, GoTrue auth, Storage, Realtime, Edge Functions in Deno), **Mumbai `ap-south-1`** | Managed Postgres + RLS gives per-user ownership without an API tier. Mumbai is the lowest-latency region to Kathmandu (~40–60 ms). |
| Client SDK | `supabase_flutter` | Official. Handles session persistence, Realtime, Storage, deep-link auth callbacks. |
| API style | Supabase client direct from app for CRUD, guarded by RLS. Edge Functions only for: payment intent, payment webhook, booking confirmation, host application submit, search ranking. | Anything touching money or trust never runs client-side. |
| Auth | Supabase Auth — email+password, Google OAuth, phone OTP (+977) | Phone OTP matters in Nepal; many users have no active email. |
| Payments | **`khalti_checkout_flutter`** (primary) + eSewa (secondary), both **server-verified** | Official Flutter SDKs exist for both. Nepal's dominant wallets. Stripe/PayPal cannot settle NPR domestically. |
| Maps | `google_maps_flutter`, static-image fallback | RM-08. Fallback because Nepal trail tile coverage is patchy. |
| Images | `cached_network_image` + Supabase Storage | Photography-heavy UI. Serve WebP in 3 sizes. |
| Push | `firebase_messaging` (FCM) + APNs | Booking confirmations, chat, host status. |
| Local storage | `flutter_secure_store` for session (via supabase_flutter), `shared_preferences` for guest interests | |
| i18n | `flutter_localizations` + ARB files (`app_en.arb`, `app_ne.arb`) | Compile-time key checking; a missing Nepali string is a build warning, not a runtime blank. |
| Money/dates | `intl` + `timezone` package | Nepali lakh grouping and `Asia/Kathmandu` (+05:45). |
| Lint/analyze | `flutter_lints` + `dart analyze --fatal-infos` | This is the agent's typechecker. It must run clean, always. |
| Tests | `flutter_test` (unit/widget), `mocktail`, `integration_test` (E2E) | |
| Analytics/errors | PostHog + Sentry (`sentry_flutter`) | |
| CI | GitHub Actions → `flutter build appbundle` / `ipa` | |

### Rejected, with reason
- **React Native / Expo** — evaluated first and built as a throwaway skeleton. Rejected because the
  maintainer debugs in Dart, and the payment SDKs are Flutter-first. Its only real advantage (OTA
  updates via Expo) is not worth the ownership cost. Do not reintroduce it.
- **Firebase instead of Supabase** — no relational integrity for bookings/participants; RLS in
  Postgres is the security model.
- **Self-hosted Postgres on a Nepali VPS** — trades uptime and sysadmin time for a latency gain of
  a few ms over Mumbai. Revisit only if a legal data-residency requirement appears.
- **BLoC** — more ceremony than Riverpod for the same result at this size.
- **Custom Dart backend** — doubles surface area where RLS covers most rules.

---

## 3. Architecture

```
Flutter app (Dart)
  ├─ go_router          screens named by App Flow ID (PL-*/RM-*)
  ├─ Riverpod providers
  │    ├─ repositories  ──HTTPS──►  Supabase PostgREST  ──►  Postgres (+RLS)
  │    ├─ session / guest / deferredAction  (StateNotifier)
  │    └─ realtime      ──WS──────►  trip_messages
  └─ http  ──►  Edge Functions (Deno)
                  ├─ create-booking-intent   → server re-price, lock quote, payment row
                  ├─ payment-webhook         → Khalti/eSewa verify → confirm booking
                  ├─ submit-host-application → validate 4 steps, flip status
                  └─ search-experiences      → ranked full-text + filter query
```

Layering, enforced: **widget → provider → repository → Supabase.** A widget never calls
`Supabase.instance` directly. This is checked in the graph audit.

Data flow rule: **the client never writes `bookings.status`, `payments.*`,
`experience_departures.spots_left`, or `host_applications.status`.** Service-role only, via Edge
Functions and DB triggers.

### Project structure

```
lib/
  main.dart
  app.dart                     MaterialApp.router + theme + localization
  router.dart                  go_router, one route per App Flow ID
  theme/
    tokens.dart                colors, spacing, radii, elevation
    typography.dart            serif display + sans UI scale
    app_theme.dart             ThemeData assembled from tokens
  core/
    supabase_client.dart
    format.dart                formatNpr, toKathmandu, isNepaliPhone, formatDuration
    result.dart                error types
  models/                      freezed/json_serializable data classes
  repositories/                experience_repo, booking_repo, profile_repo, …
  providers/                   riverpod providers, one file per domain
  widgets/                     design-system primitives + shared widgets
  features/
    onboarding/  auth/  home/  explore/  search/  experience/  booking/
    saved/  plans/  trips/  profile/  host/
      └─ each holds its screens, named <screen>_screen.dart
l10n/
  app_en.arb  app_ne.arb
supabase/
  migrations/  functions/  tests/
test/                          unit + widget
integration_test/              E2E
```

---

## 4. Environments

| Env | Supabase | App |
|---|---|---|
| local/LAN | `supabase start` (Docker) | `flutter run` |
| hosted | configured Supabase project | `flutter run --dart-define-from-file=<config.json>` |

Android uses one application ID, `com.plane.plan_e`; there are no product
flavors or alternate app installs. Local config is loaded from the ignored
`env/local.json`, and `--dart-define`/`--dart-define-from-file` can override it.
Only `SUPABASE_URL` and `SUPABASE_ANON_KEY` reach the app binary. Service-role
keys remain server-side.

---

## 5. Auth & session

- `supabase_flutter` persists the session in secure storage and auto-refreshes on resume.
- **Guest session**: a local UUID in `shared_preferences`, no server row. Guest interests stored
  locally (App Flow §2.1). On sign-up, offer a one-time merge.
- **Auth gate (RM-05)**: any restricted action writes
  `DeferredAction(screenId, entityId, action, params)` to a Riverpod `StateNotifier` before opening
  the modal. After auth: re-fetch the entity, re-check availability, then replay — or explain what
  changed and route somewhere valid.
- Roles: `traveler` (default), `host_applicant`, `host`, `admin` in `profiles.role`, mirrored into
  the JWT via a custom access-token hook so RLS reads it cheaply.

---

## 6. Payments (Nepal)

1. App calls `create-booking-intent` with `{experience_id, departure_id, adults, children, addons}`.
2. Function re-prices **server-side** (never trusts a client total), creates `bookings`
   `status='pending'` + `payments` `status='initiated'`, returns the gateway payload.
3. App launches `KhaltiCheckout` (or eSewa) with that payload.
4. Gateway calls `payment-webhook`. Function verifies via the gateway's lookup API using the secret
   key, then in **one transaction**: `payments.paid`, `bookings.confirmed`, decrement
   `spots_left`, insert `booking_participants`, seed the gear checklist from `bring_list`.
5. App listens on Realtime (or polls) until `confirmed` → PL-11.

Rules:
- Idempotency key = unique index on `payments.idempotency_key`. Duplicate webhooks are no-ops.
- Quote lifetime 15 min (`bookings.quote_expires_at`). Expired → re-price, ask for confirmation.
- An unknown or timed-out result is **verified against the gateway** before any retry is offered.
- Amounts are **integer paisa** (`amount_paisa`, Dart `int`). Never `double` on money. Currency
  fixed `NPR`.
- The Khalti SDK's client-side success callback is **not** proof of payment. Only the webhook is.
- Refunds: v1 records `cancellation_requested` and notifies support manually.

---

## 7. Nepal-specific requirements

- NPR formatted with Nepali lakh grouping — `Rs. 12,50,000`, not `Rs. 1,250,000`. `intl`'s default
  grouping is wrong for this; write and unit-test `formatNpr` by hand.
- Phone validation `^(\+977)?9[678]\d{8}$`.
- Dates stored UTC, displayed via the `timezone` package with `Asia/Kathmandu` (+05:45). **Never a
  hardcoded offset and never `DateTime.now().toLocal()`** — the device may be in any timezone.
- Optional Bikram Sambat display toggle in Language & Region (RM-19). Gregorian is always what is
  stored.
- `en` and `ne` ARB files from day one. No literal user-facing string in any widget.
- Trekking domain fields: `difficulty`, `max_altitude_m`, `permits_required` (TIMS, ACAP,
  Sagarmatha NP, Restricted Area), `best_season`.
- Network reality: assume 3G with frequent dropouts. Every screen has a cached render path, image
  placeholders, and retry. Chat messages queue locally and resend.

---

## 8. Non-functional requirements

| Area | Requirement |
|---|---|
| Performance | Cold start ≤ 3 s on a mid-range Android (Redmi-class). Home first paint ≤ 1.5 s on cached data. Scroll 60 fps — verify with `flutter run --profile` and the DevTools frame chart, not by eye. |
| Build | `flutter build appbundle --split-per-abi`. Watch APK size; `--analyze-size` in CI. |
| Payload | Images ≤ 200 KB at card size, ≤ 600 KB hero, WebP. |
| Availability | If the payment gateway is down, block Proceed to Payment with an explicit message — never fail after a charge. |
| Security | RLS on every table, no exceptions. Service-role key never in the app. Verification documents in a private bucket, 5-minute signed URLs. Rate-limit auth and payment endpoints. Validate input in Dart **and** in the Edge Function. |
| Privacy | Verification IDs are PII: private bucket, admin-only, deletable on request. |
| Accessibility | 48×48 dp minimum tap targets (Flutter's `kMinInteractiveDimension`), WCAG AA contrast (the gold `#B7802B` fails on ivory — use the corrected `#8F5E1B`), `MediaQuery.textScaler` respected without clipping, `Semantics` labels on every image/icon/rating/upload/progress/nav item, reduced-motion alternative for the splash transition. |
| Testing | Unit tests for pricing and formatters; widget tests for the three-state rendering of every list; `integration_test` for onboarding, booking, chat, review, host apply; SQL tests for RLS. Pricing and RLS must never regress. |
| Observability | `sentry_flutter` with release tracking; structured logs in Edge Functions correlated by `booking_id`. |

---

## 9. Third-party integrations

| Service | Use | Failure mode |
|---|---|---|
| Khalti / eSewa | Payment | Block booking with a message; never confirm without webhook verification |
| Google Maps | RM-08, meeting point | Static image + text address |
| FCM / APNs | Notifications | Silent degrade |
| Supabase Storage | Photos, verification docs | Resumable upload with retry |
| PostHog / Sentry | Analytics, errors | Silent degrade, never block UI |

---

## 10. Open technical questions (do not silently invent)

1. Khalti vs eSewa merchant account — which exists today? Sandbox credentials needed.
2. Is Saved a bottom-nav destination or Profile-only? (App Flow §6.2 conflict — currently Profile.)
3. Host payout mechanism after approval — out of v1 scope, confirm.
4. Is experience content authored in Nepali too, or is only the UI bilingual?
5. Booking cancellation / refund policy text — legal input required.
6. Any legal data-residency requirement that would force self-hosting out of Mumbai?
