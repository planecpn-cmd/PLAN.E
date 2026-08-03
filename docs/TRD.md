# PLAN E — Technical Requirements Document (TRD)

Version 1.0 · 3 August 2026 · Mobile-only Nepal adventure & experience-discovery app
Source of truth order: App Flow Document v1.0 > UI/UX Design Report v1.0 > this TRD > agent judgement.

---

## 1. Scope

Build the mobile client + backend for PLAN E: discover, save, book and review Nepal adventure
experiences; manage upcoming plans; apply to become a host.

In scope: guest browsing, auth, interests, discovery, search/filter, experience detail, booking,
Nepal payment (eSewa/Khalti), plans, itinerary, trip chat, gear checklist, budget tracker, trip
history, reviews, profile/settings, 4-step host application.

Out of scope v1: admin dashboard, host operations console after approval, web/tablet, iOS-only
features requiring Apple hardware review beyond standard build, offline-first sync engine,
multi-currency (NPR only).

---

## 2. Stack decisions

| Layer | Choice | Reason |
|---|---|---|
| App | React Native + Expo (SDK 54+), TypeScript, EAS Build | One codebase for Android+iOS; Android is 90%+ of Nepal market but iOS needed for inbound tourists. Expo removes native build toil. |
| Navigation | `expo-router` (file-based) | Screen IDs from App Flow map 1:1 to route files. Deep links free (needed by PL-09 Share). |
| State / data | TanStack Query for server state, Zustand for local UI/session state | No Redux boilerplate. Query gives caching, retry, loading/error/empty states the App Flow demands. |
| Backend | Supabase (Postgres 15, GoTrue auth, Storage, Realtime, Edge Functions in Deno) | Managed Postgres + RLS gives per-user data ownership without writing an API tier. Realtime covers trip chat. Cheap at student/MVP scale. |
| API style | Supabase client SDK direct from app for CRUD, guarded by RLS. Edge Functions only for: payment intent creation, payment verification webhook, booking confirmation, host application submit, search ranking. | Anything touching money or trust never runs client-side. |
| Auth | Supabase Auth — email+password, Google OAuth, phone OTP (Nepali +977 numbers) | Phone OTP matters in Nepal; many users have no active email. |
| Payments | Khalti (primary) + eSewa (secondary), both server-verified | Nepal's dominant wallets. Stripe/PayPal not usable for NPR domestic. |
| Maps | Google Maps via `react-native-maps`, static-marker fallback | RM-08. Fallback because Nepal trail coverage is patchy. |
| Push | Expo Notifications (FCM/APNs under the hood) | Booking confirmations, chat messages, host application status. |
| Images | Supabase Storage + `expo-image` with cache | Photography-heavy UI (see Design Report §5). Serve WebP, 3 sizes. |
| Analytics/errors | PostHog (self-host optional) + Sentry | |
| CI | GitHub Actions -> EAS Build/Submit | |

### Rejected, with reason
- Firebase: no relational integrity for bookings/participants; RLS in Postgres is stronger for
  data ownership rules.
- Custom Node/Nest backend: doubles surface area for an MVP where RLS covers 80% of rules.
- Stripe: cannot settle NPR domestically.

---

## 3. Architecture

```
Expo app (RN, TS)
  ├─ expo-router screens (PL-*/RM-* IDs)
  ├─ TanStack Query  ──HTTPS──►  Supabase REST/PostgREST  ──► Postgres (+RLS)
  ├─ Zustand (session, guest interests, deferred action)
  ├─ Supabase Realtime (websocket)  ──► trip_messages
  └─ fetch  ──►  Edge Functions (Deno)
                    ├─ create-booking-intent   → locks quote, writes payment row
                    ├─ payment-webhook         → Khalti/eSewa callback verify → confirm booking
                    ├─ submit-host-application → validates 4 steps, flips status
                    └─ search-experiences      → ranked full-text + filter query
```

Data flow rule: **the client never writes `bookings.status`, `payments.*`, `host_applications.status`,
or `experiences.spots_left`.** Those are service-role only, via Edge Functions and DB triggers.

---

## 4. Environments

| Env | Supabase project | App |
|---|---|---|
| local | `supabase start` (Docker) | Expo Go / dev client |
| staging | plan-e-staging | EAS preview channel, Khalti sandbox |
| prod | plan-e-prod | EAS production channel, Khalti live |

Secrets in EAS Secrets + Supabase Vault. Nothing but `SUPABASE_URL` and `SUPABASE_ANON_KEY`
ships in the app bundle.

---

## 5. Auth & session

- Session persisted in `expo-secure-store`, auto-refresh on foreground.
- **Guest session**: local UUID in secure store, no server row. Guest interests stored locally
  (App Flow §2.1 assumption). On sign-up, offer one-time merge of local interests.
- **Auth gate (RM-05)**: any restricted action writes
  `{screenId, entityId, action, params}` to Zustand `deferredAction` before opening the modal.
  After successful auth: re-fetch entity, re-check availability, then replay or explain the change.
- Roles: `traveler` (default), `host_applicant`, `host`, `admin`. Stored in `profiles.role`,
  mirrored into JWT via a custom access-token hook so RLS can read it cheaply.

---

## 6. Payments (Nepal)

1. App calls `create-booking-intent` with `{experience_id, date, adults, children, addons}`.
2. Function re-prices server-side (never trusts client totals), creates `bookings` row
   `status='pending'`, `payments` row `status='initiated'`, returns the gateway payload.
3. App opens Khalti/eSewa via WebView/deep link.
4. Gateway calls `payment-webhook`. Function verifies with the gateway's lookup API using the
   secret key, then in **one transaction**: `payments.status='paid'`,
   `bookings.status='confirmed'`, decrement `experiences.spots_left`, insert
   `booking_participants`.
5. App polls `bookings/:id` (or listens on Realtime) until `confirmed` → PL-11.

Rules:
- Idempotency key = `payments.idempotency_key` unique index. Duplicate webhooks are no-ops.
- Quote lifetime 15 min (`bookings.quote_expires_at`). Expired → re-price and ask for confirmation.
- Unknown/timeout result is *verified* against the gateway before any retry is offered.
- Amounts stored as **integer paisa** (`amount_paisa`), never floats. Currency fixed `NPR`.
- Refund/cancellation: v1 records `status='cancellation_requested'` and notifies support manually.
  Automated refunds are v2.

---

## 7. Nepal-specific requirements

- Currency NPR, formatted `Rs. 12,500` with Nepali lakh grouping (`12,50,000`) in list/detail UI.
- Phone validation `^(\+977)?9[678]\d{8}$`.
- Dates stored UTC, displayed in `Asia/Kathmandu` (UTC+05:45 — must use a real tz library, never
  a fixed offset). Optional Bikram Sambat display toggle in Language & Region (RM-19), Gregorian
  is the stored value always.
- Localization: `en` and `ne` from day one via `i18next`; no hardcoded strings in components.
- Trekking domain fields: `difficulty` (easy/moderate/challenging/strenuous), `max_altitude_m`,
  `permits_required` (TIMS, ACAP, Sagarmatha NP, Restricted Area), `best_season` months.
- Network reality: assume 3G and frequent dropouts. Every screen has a cached-render path,
  image placeholders, and retry. Chat messages queue locally and resend.

---

## 8. Non-functional requirements

| Area | Requirement |
|---|---|
| Performance | Cold start ≤ 3 s on a mid-range Android (Redmi-class). Home first paint ≤ 1.5 s on cached data. List scroll 60 fps via FlashList. |
| Payload | Images served ≤ 200 KB at card size, ≤ 600 KB hero. |
| Availability | Booking path must degrade safely: if payment gateway is down, block Proceed to Payment with an explicit message rather than failing after charge. |
| Security | RLS on every table, no exceptions. Service-role key never in the app. Verification documents in a private bucket with signed URLs (5 min TTL). Rate-limit auth and payment endpoints. Input validated with `zod` on both client and Edge Function. |
| Privacy | Verification IDs are PII: private bucket, access limited to `admin`, deletable on request. |
| Accessibility | 44×44 pt targets, WCAG AA contrast (gold-on-cream needs verification, Design Report §8.2), dynamic type, screen-reader labels, reduced-motion alternative for the NEPAL→PLAN E transition. |
| Testing | Vitest/Jest units for pricing + validation; Maestro E2E for onboarding, booking, host application; pgTAP or SQL tests for RLS policies. Pricing and RLS are the two things that must never regress. |
| Observability | Sentry release tracking; structured logs in Edge Functions with `booking_id` correlation. |

---

## 9. Third-party integrations

| Service | Use | Failure mode |
|---|---|---|
| Khalti / eSewa | Payment | Block booking with message; never confirm without webhook verify |
| Google Maps | RM-08, meeting point | Fall back to static image + text address |
| Expo Push | Notifications | Silent degrade |
| Supabase Storage | Photos, verification docs | Upload retry with resumable upload |
| PostHog / Sentry | Analytics, errors | Silent degrade, never block UI |

---

## 10. Open technical questions (do not silently invent)

1. Khalti vs eSewa merchant accounts — which exists today? Sandbox credentials needed.
2. Is Saved a bottom-nav destination or Profile-only? (App Flow §6.2 conflict — currently Profile.)
3. Host payout mechanism after approval — out of v1 scope, confirm.
4. Do we need Nepali-language content for experiences, or Nepali UI only?
5. Booking cancellation/refund policy text — legal input required.
