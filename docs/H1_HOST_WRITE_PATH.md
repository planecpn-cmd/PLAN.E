# H1 — Host write path (SCOPE ONLY)

What it takes to make `SupabaseHostModeRepository` actually write. No implementation in this doc. Read it to decide whether H1 runs before or after P3.

---

## Decisions log (founder, post-audit)

### D1 — N1 = approval queue (confirmed)

Client doc says "3 EXPERIENCE AWAITING APPROVAL"; `experience_status` already carries `pending_review`. **H1 client writes may only ever produce `draft` or `pending_review`, never `published`.** Publishing is an admin `content:manage` action. Edits to an already-published experience create a **`pending_review` revision**; they do not mutate the live row. The approval queue is therefore additive — build it as its own P-node modelled on P2's host-application review.

### D2 — experience photo storage: private bucket + copy on approval

**Supabase Storage has no per-object ACL** — a bucket is wholly public or wholly private, so "flip an ACL on the same object" is not an available primitive. Decision:

- New **private** bucket `experience-photos`. Host upload path `<host_id>/<experience_id>/<file>`; RLS upload policy scoped to `auth.uid() = <host_id>` and `private.is_approved_active_host(auth.uid())`. Read = signed URL for the owning host and the admin reviewer.
- On approval, the admin decision RPC **copies** the approved objects into the existing **public `catalog-images`** bucket and sets `experiences.cover_image_url` / `gallery` to those public paths. Private originals are kept for audit.

**Why copy, not signed-URL-always:** copy keeps the public surface a single well-known bucket (`catalog-images`, already how seeded catalog imagery works — stable CDN-friendly URLs). A takedown is then one delete from that one bucket + set the experience `archived`; the private original is not publicly reachable so it needs no urgent action. Signed-URL-always also unpublishes cleanly but couples every catalog image read to short-lived URL minting forever to get that property, and diverges from the existing catalog delivery model. Rejected the "public bucket, rely on nothing linking to unpublished photos" option outright — that is obscurity and it publicly hosts unreviewed uploads on our domain.

**Cleanup story (do not build now):** copy-on-approve leaves the private originals in `experience-photos` behind for the lifetime of the experience, including for **rejected / archived** listings that will never be approved. There is no reference-counting or TTL. For now this is an accepted, documented leak: a **manual periodic sweep** — delete `experience-photos/<host_id>/<experience_id>/` for any experience whose status has been `rejected` or `archived` for more than N days — run by an operator, not code. Wire an automated sweep (a cron edge function keyed off `experiences.status` + `updated_at`) only if storage cost or a data-retention requirement makes it worth it.

### D3 — taxonomy: NOT NULL status of the six columns (reported, per request)

`public.experiences`, from `0005_experiences.sql`; **no later migration alters any of these**:

| Column | NOT NULL? | Default | Fillable at draft-insert time? |
|---|---|---|---|
| `category_id` | **No** (nullable FK `categories`) | — | map from doc Q1; or leave null, admin sets at review |
| `region_id` | **No** (nullable FK `regions`) | — | derive from the host's location text; or leave null, admin sets at review |
| `slug` | **Yes** | none | yes — server-generated from `title` + short hash, retry-on-conflict |
| `currency` | **Yes** | `'NPR'` (+ `check (currency = 'NPR')`) | yes — default applies on insert |
| `duration_hours` | **Yes** | `24` | yes — default applies; admin normalises at review |
| `difficulty` | **Yes** | `'moderate'` (enum `difficulty_level`) | yes — default applies; admin sets at review |

**None of the six blocks a draft-time insert.** The three NOT-NULL ones all have defaults; `slug` is NOT NULL without a default but is server-generated; `category_id` / `region_id` are nullable.

**One column outside the six IS a draft-insert blocker — flagging it:** `cover_image_url text not null` has **no default**. A `draft` / `pending_review` row cannot be inserted without a URL, and the wizard holds only local file paths until upload. Two ways out:
- **(a) recommended, no migration:** the create RPC uploads the photos first (step 1 already requires ≥1) and derives `cover_image_url` from the first stored object before the `experiences` insert.
- (b) additive migration: drop the NOT NULL, add `check (status <> 'published' or cover_image_url is not null)` so imageless drafts are legal and the constraint only bites at publish.

Recommend (a): keeps the live catalog's not-null invariant intact and needs no schema change. This is the one place the taxonomy decision meets a real constraint — raising it rather than inventing a placeholder cover URL.

### D4 — `slug` uniqueness: retry-on-conflict

`slug text unique not null`. Generate `slugify(title) + '-' + base36(short hash)`; on unique-violation, regenerate the hash and retry (bounded, e.g. 5 attempts). Do **not** repeat the `booking_ref` pattern of a unique column with no retry path.

---

## H1 core — build status (as of the H1 core commits)

Four `SECURITY DEFINER` RPCs, each `revoke execute from public, anon` + `grant to authenticated`, each in `security_definer_manifest.json` under `authenticated_callable` with a reasoning note, each with a `*.test.sql` covering owner / non-owner / suspended / wrong-status. All check `auth.uid()`, `host_id = auth.uid()` ownership, and `private.is_approved_active_host(auth.uid())`. The client can only ever produce `draft` or `pending_review` — never `published`.

| RPC | Migration | What it does | Screen re-wired from the H0 notice |
|---|---|---|---|
| `host_set_experience_paused(uuid, boolean)` | `20260909150000` | published ↔ paused for an owned listing | `host_experience_detail_screen` — confirm dialog + call + invalidate; failure caught |
| `host_update_experience_availability(uuid, date, date, int)` | `20260909160000` | edits the **earliest open departure** (creates one if none); rejects capacity below booked count and date moves under active bookings | `host_availability_screen` — validate + call + pop; failure caught |
| `host_save_experience_draft(jsonb)` | `20260909170000` | insert/update an experience **draft only**; rewrites `itinerary_items`; upserts the earliest open departure; server-generates the slug | `create_host_experience_screen` — "Save draft" calls the RPC, stores the returned id; failure caught |
| `host_submit_experience_for_review(uuid)` | `20260909180000` | `draft` → `pending_review` after a completeness check; **no path to `published`** | `host_experience_preview_screen` — validate + submit + navigate; RPC error messages surfaced |

**One-departure handling (RPC 2 & 3):** no HALT. The RPCs deterministically target the earliest `status = 'open'` departure — exactly the one the flattened `HostExperience` model and the host UI already show — and create one if none exists. They do not corrupt a many-departure experience. See **Known limitations** below — multi-departure / a real availability calendar is a stated client-doc requirement, not a future nicety, and it stays open.

**Lossy draft mapping (RPC 3), documented in the migration:** `trip_details` → a single `things_to_know` element (no column for it); `category_id` / `region_id` / `difficulty` / `duration_hours` left to the admin at review (`duration_hours` is derived from the date span when both dates are present, else the column default).

### Photo slice — done (`20260909190000` + client rework)

- **Private bucket `experience-photos`**, path `<host_id>/<experience_key>/<file>`, `public = false`, server-enforced 5 MiB / `image/jpeg|png|webp` on the bucket row.
- **Storage RLS** (`storage.objects`): upload only by an approved active host under their own uid prefix (`private.is_approved_active_host` in the `with check`); read by the owning host; read-all by `has_scope('content:manage')` — **never a bare `is_admin()`**; replace/delete by the owning host. Test: `experience_photos_storage_rls.test.sql`.
- **Client:** `HostModeRepository.uploadExperiencePhoto` / `experiencePhotoSignedUrl` / `deleteExperiencePhoto`. The wizard photo step uploads on pick (per-file, with an in-flight count + progress), renders thumbnails via signed URL, removes = delete + drop from the list. **A failed upload shows an error and leaves the rest of the wizard's local state untouched** (`host_experience_photo_step_test.dart`). Bundled placeholder tiles removed.
- **Threading:** `saveDraft` sends `gallery` = the uploaded storage paths and `cover_image_url` = the first; `submitForReview`'s cover check is now satisfiable.
- **Exit condition met** — `host_write_end_to_end.test.sql`: empty wizard → `host_save_experience_draft` with a photo → `cover_image_url` set → `host_submit_experience_for_review` → row `pending_review`, the photo readable by a `content:manage` reviewer and **not** by another host.

### Not done — the next increments

1. **N1 admin experience-review node.** `pending_review` rows now exist but nothing consumes them. A `content:manage` queue + a decision RPC (`pending_review` → `published`) with the **copy-on-approve photo promotion** from D2 (copy `experience-photos/<path>` → public `catalog-images`, rewrite `cover_image_url` / `gallery`) + a host notification. Mirrors P2's host-application review; ~3–4 days. **This is the next dead end after the photo slice — a host submitting into a queue nobody reads.**
2. **`updateBookingStatus` — still deferred** (own node after N3). `booking_status` has no host-decision state; decline-with-refund needs the refund path; accept touches frozen `finalize_verified_payment`.
3. **D2 private-original cleanup** — manual sweep only, per the D2 note.

---

## Known limitations (open gaps, not deferred niceties)

### One departure per experience

Every host write path — `getExperiences` (reads `departures.first`), the availability screen, `host_update_experience_availability`, `host_save_experience_draft` — assumes and touches **a single departure**: the earliest `status = 'open'` one. The `experience_departures` table is one-to-many and travellers book against a specific `departure_id`, but the host has no way to see or manage more than one.

The client doc's availability model asks for **closed dates, blocked dates, and "available anytime"** — i.e. a real availability calendar with multiple date ranges / recurring availability, not one start–end pair. That is a **stated requirement**, currently unmet. Closing it means: a host-facing departures/calendar UI, `host_*` RPCs that address a departure by id (the `HostExperience` model must stop flattening), and the traveller booking flow already supports many departures so no change there. Not scoped here; flagged so it stays visible.

### Edit of a draft does not preserve existing photos

`HostExperience` carries no `gallery`, so opening a saved draft in the wizard shows none of its stored photos; re-saving overwrites `gallery` with whatever was added in that session. Acceptable for the create flow (the exit condition); a gap for iterative editing. Fix rides with the N1 revision model.

---

## Background

`hostModeRepositoryProvider` → `SupabaseHostModeRepository` (`lib/features/host/presentation/host_mode_providers.dart:8`). That class extends `UnavailableHostModeRepository` and overrides **reads and messaging only**. Five write methods fall through to the fail-closed base, which returns `Future.error(StateError('Host Mode requires an authenticated, approved and active host account.'))`.

Host Mode is **not** feature-flagged (verified: no host flag in `feature_flags` / `app_config` / `remote_content` seed migrations; `router.dart` registers `/host/*` unconditionally; guard is `HostModeAccessGate` = backend `current_host_access()` approved+active). Splash routes an approved host straight to `/host/dashboard`; the profile screen shows a live "verified host" button to the same place. So for any approved+active host (the Ram Shrestha demo account included), these five buttons are reachable and throw an unhandled `StateError` at the tap. Severity: real bug, not an unfinished-feature-behind-a-flag.

The grant history is the reason all five need a service-role path:
- `20260823100000_least_privilege_table_grants.sql` — `revoke all` on all tables from `anon, authenticated`, then re-grants narrowly (`experiences`, `experience_departures` = **SELECT only** to authenticated).
- `20260823120000_checkout_authority_hardening.sql` — `revoke insert, update, delete on public.experiences from authenticated` **and** drops policy `"Approved active hosts can manage their experiences"`; `revoke insert on public.bookings from authenticated`.
- `bookings.status` writes are already restricted to `service_role` by trigger `prevent_client_booking_status_change` (`0007_bookings.sql`).
- `host_applications.status` writes restricted to `service_role` by trigger `prevent_client_host_app_status_change` (`0011`).

`service_role` retains full grants and bypasses RLS, so every write below is implementable as a Supabase **edge function** (JWT-verified, loads the caller, checks host ownership, writes with the service-role client) or a **`SECURITY DEFINER` RPC** with an explicit ownership check in the body. There is no host-facing edge function for any of this today — only `submit-host-application`.

---

## The five fall-through writes

### 1. `saveDraft(HostExperienceDraft)` — create / edit an experience

| | |
|---|---|
| Screen / button | `create_host_experience_screen.dart` — "Save draft" app-bar action (`_saveDraft`, ~:161); also the create wizard's implicit save. Edit mode: `/host/experiences/:id/edit`. |
| Needs | Insert/update `public.experiences` (status stays `draft`); write `public.itinerary_items` rows; optionally seed one `public.experience_departures` from the draft's date range + capacity; **upload photos to object storage**. |
| Tables exist? | `experiences`, `itinerary_items`, `experience_departures` — yes. **Photo bucket — no.** Buckets are `avatars`, `host-documents`, `trip-attachments`, `catalog-images` (last one is `image/webp`, public, explicitly "No client upload policies"). No bucket a host may upload experience imagery to. |
| RLS / grants today | `authenticated` = SELECT only on `experiences`; write grant revoked and host-manage policy dropped (`20260823120000`). No path for a host to write `experiences` with their own JWT. Service-role only. |
| Model gap | `HostExperienceDraft` collects title, location text, description, local photo paths, trip details, itinerary[], included[], bring[], start/end date, capacity, price NPR, meeting-point text. It does **not** collect: `slug` (unique, required), `cover_image_url` (required — draft has local file paths, not URLs), `category_id`, `region_id`, `currency`, `difficulty`, `duration_hours`. A create RPC must generate the slug, map taxonomy, and resolve photos to stored URLs. |
| Blocked on | Not the ledger or commission. Blocked on two **decisions**: (a) experience photo storage — new bucket + host-scoped upload policy + a resize/webp step, or reuse `host-documents`; (b) how draft fields map to required `experiences` columns (taxonomy picker in the wizard, or admin assigns on review). Also interacts with N1 — see §"Direct write vs approval queue". |
| Implementable now? | Yes as a service-role edge function once (a) and (b) are decided. It is the largest of the five because the draft is lossy against the table. |
| Size | **L — ~4–6 days.** Edge function (create + edit branches) + photo upload/bucket/policy + slug + taxonomy mapping + `itinerary_items` sync + departure seed + Flutter repo wiring + SQL/edge tests. |

### 2. `submitForReview(HostExperienceDraft)` — draft → pending_review

| | |
|---|---|
| Screen / button | `host_experience_preview_screen.dart` — "Submit for review" (`_submit`, :223). Currently throws uncaught. |
| Needs | Persist the draft (same write as #1) then set `experiences.status = 'pending_review'`. |
| Tables exist? | Yes. `experience_status` enum already has `draft, pending_review, published, paused, archived` (`0002_enums.sql`) — the rails for a review step exist. |
| RLS / grants today | Service-role only (same as #1). |
| Blocked on | **N1.** If there is an approval queue: this flips to `pending_review` and an admin `content:manage` screen flips to `published`. That admin screen and its decision RPC **do not exist** (ADMIN_PANEL_PLAN §"Deliberately NOT built": experience moderation is not in P1–P2). If there is no queue: "submit" would just self-publish, which the enum design argues against. |
| Implementable now? | The status flip itself is trivial. The half that makes it meaningful (admin review screen + `experiences` decision RPC + host notification) is a separate node. |
| Size | **S–M — ~1 day** for the client-side flip on top of #1. The admin review screen is its own P-node (estimate separately, ~3–4 days, mirrors P2's host-application review). |

### 3. `setExperiencePaused(id, bool)` — published ↔ paused

| | |
|---|---|
| Screen / button | `host_experience_detail_screen.dart` — "Pause listing" / "Resume listing" (`_toggle`, :188). |
| Needs | Set `experiences.status` between `published` and `paused` for an experience the caller owns. |
| Tables exist? | Yes; both enum values exist. |
| RLS / grants today | Service-role only. |
| Blocked on | Nothing. |
| Implementable now? | Yes. Narrowest of the five. One `SECURITY DEFINER` RPC `host_set_experience_paused(p_experience_id uuid, p_paused boolean)` with body check `exists (select 1 from experiences where id = p_experience_id and host_id = auth.uid()) and private.is_approved_active_host(auth.uid())` and a guard that current status is in `('published','paused')`. |
| Size | **S — ~0.5–1 day.** RPC + grant + Flutter wiring + one `.test.sql` (owner can toggle, non-owner blocked, draft/pending can't be paused). |

### 4. `updateAvailability(id, start, end, capacity)` — edit dates + capacity

| | |
|---|---|
| Screen / button | `host_availability_screen.dart` — "Update availability locally" (`_save`, :119). `host_departure_detail_screen.dart` links here too. |
| Needs | Update the experience's `experience_departures` row (`start_date`, `end_date`, `total_spots`, `spots_left`), or insert one if none exists. |
| Tables exist? | Yes. |
| RLS / grants today | `authenticated` = SELECT only on `experience_departures`; no write policy at all. Service-role only. |
| Blocked on | Semantics, not schema: reducing `total_spots` below already-booked count; moving dates when confirmed bookings exist; the client assumes exactly one departure per experience (`departuresByExperience[id].first`) while the table is one-to-many. Needs conflict rules before it is safe. |
| Implementable now? | Happy path yes via a service-role RPC (`host_upsert_primary_departure(...)`). The booking-conflict rules are the real work. |
| Size | **M — ~2–3 days.** RPC + conflict checks (`bookings` against the departure) + single-vs-many departure reconciliation + tests. |

### 5. `updateBookingStatus(id, HostBookingStatus)` — accept / decline a request

| | |
|---|---|
| Screen / button | `host_booking_detail_screen.dart` — "Accept request" / "Decline" (`_decide`, :250). Shown only when status maps to `requested`. |
| Needs | Flip `bookings.status`; on accept, atomically decrement `experience_departures.spots_left`; notify the traveler; on decline after payment, refund. |
| Tables exist? | `bookings` yes. **But `booking_status` enum is `pending, confirmed, cancellation_requested, cancelled, completed, expired`** — there is **no `requested` and no `declined` state**. The Flutter `HostBookingStatus` (`requested, confirmed, completed, cancelled, declined`) is a client fiction; `_bookingStatus()` maps DB `pending` → `requested`. There is nowhere to write "declined". |
| RLS / grants today | `bookings` insert revoked from authenticated; status change is `service_role`-only by trigger. |
| Blocked on | **Product model + N3.** The current booking lifecycle is payment-driven: `create-booking-intent` → pay → `finalize_verified_payment` sets `confirmed`. There is no host-decision state in that lifecycle. Adding "host accepts/declines a request" means deciding whether the host approves **before** payment (new pre-payment state) or **after** (decline must refund). Decline-with-refund is blocked on the refund/cancellation path (N3 — no refund code in the repo). Accept touches capacity atomicity shared with `finalize_verified_payment`, which is **Rule 4 frozen**. |
| Implementable now? | No, not cleanly. This is the weakest fit and should not be built as part of a first H1 pass. It needs an enum change, a lifecycle decision, and the N3 refund path. |
| Size | **L / blocked — ~5+ days and gated on decisions.** Enum migration + lifecycle design + edge function + refund-on-decline (N3) + capacity atomicity review. |

---

## Direct write vs the experience-approval queue (N1)

These two interact, and building the write path without deciding N1 means building it twice.

- **The `experience_status` enum already carries `draft` and `pending_review`.** The schema was designed expecting a review step between a host finishing an experience and it appearing in discovery. ADMIN_PANEL_PLAN gives `content:manage` scope "experiences, catalog" but no experience-review node is built (P1–P2 covered host *applications*, not their listings).
- **If H1 writes `published` directly:** #1 and #2 collapse into one "create and go live" RPC. Fast, but every host can publish unreviewed listings into the catalog. When N1 lands you must: change the RPC's status target, add a re-review rule for edits to already-published experiences (edit-in-place vs draft-a-revision), build the admin screen + decision RPC + notification, and migrate any self-published rows back through review.
- **If H1 always writes `pending_review` (client can never set `published`):** #2 is done on the host side the day it ships; the only missing piece is the admin flip, which is a self-contained P-node modelled on P2's host-application review (queue + `hosts`-style scope, decision RPC, `notifyHost*` path already patterned). Edits to a published experience write a `pending_review` revision rather than mutating the live row.

**Recommendation:** decide N1 before H1 implementation. If that decision slips, build H1 to the second option — host writes only ever produce `draft` or `pending_review`, never `published` — so the approval queue is additive and nothing is rebuilt. Do not build a direct-to-`published` path "for now".

---

## Honest size summary

| Write | Blocked on | Size | Order |
|---|---|---|---|
| `setExperiencePaused` | nothing | **S** ~0.5–1d | do first, any time |
| `submitForReview` (host side) | N1 decision | **S–M** ~1d on top of #1 | after N1 decided |
| `updateAvailability` | booking-conflict rules | **M** ~2–3d | with or after #1 |
| `saveDraft` (create/edit) | photo storage decision, taxonomy mapping, N1 | **L** ~4–6d | the core of H1 |
| `updateBookingStatus` | `booking_status` enum, lifecycle decision, N3 refund path | **L / blocked** ~5d+ | defer — own node after N3 |
| admin experience-review screen | (only if N1 = queue) | **M** ~3–4d | separate P-node |

**H1 as a sane first slice** (`setExperiencePaused` + `saveDraft` + `submitForReview` + `updateAvailability`, N1 decided, booking-decision deferred): **~1.5–2 weeks**, one photo-storage decision, one taxonomy decision, plus the admin experience-review node if N1 is a queue.

`updateBookingStatus` is not part of that slice. It waits on the N3 refund path and a booking-lifecycle decision, and it would touch `finalize_verified_payment` (frozen). Treat it as its own node sequenced after N3.

---

## Cleanup flag (do not action yet)

`lib/features/host/host_step_1_screen.dart` … `host_step_4_screen.dart` are **dead code** — not in `router.dart`, only referenced by `test/host_application_test.dart`. They are the legacy 4-screen application flow, superseded by the 8-step `host_questionnaire_screen.dart`. Backed by `lib/features/host/host_provider.dart` (`HostApplicationData`) and `HostRepository.submitHostApplication` (legacy payload).

**Flag for deletion, keep for now:** `host_step_4_screen.dart` and `HostApplicationData` carry the **bank payout fields** (`bankName`, `accountName`, `accountNumber`, `branch`, plus a bank dropdown: Global IME, Nabil, NIC Asia, Rastriya Banijya, NIMB). The live questionnaire collects **no** payout details anywhere. Those four screens are the only in-repo reference for what a host payout form asked for, which N3 (settlement ledger) will need to re-collect. Delete them once N3's payout-details capture is specified, together with `host_provider.dart`, the legacy `submitHostApplication` payload, and `test/host_application_test.dart`.

---

*Scope only. Nothing implemented. P2 stays halted on notification copy; founder emails still outstanding.*
