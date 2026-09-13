# Host Surface Audit

Read-only inventory of the **host-facing Flutter surface** in `lib/`. No admin panel (`admin/`) is covered here — it is separately specified.

Scope note on the reference list: the client doc phrases (`HOST DASHBOARD SHOULD SHOW`, `only ask 7 things`, `Screens 1-4`) are **NOT PRESENT in this repo**. The gap tables below use the item list quoted verbatim in the audit request. Where a doc screen count is referenced, it is compared against `docs/HOST_APPLICATION_CONTRACT.md` and the two application flows found in code.

---

## 0. Critical finding — the host management surface is read-only in production

`hostModeRepositoryProvider` wires `SupabaseHostModeRepository` (`lib/features/host/presentation/host_mode_providers.dart:8`). That class extends `UnavailableHostModeRepository` and **overrides only the read methods**. Every write method falls through to the fail-closed base, which returns `Future.error(StateError('Host Mode requires an authenticated, approved and active host account.'))`:

| Host action | UI entry point | Runtime result in production |
|---|---|---|
| Save experience draft | `create_host_experience_screen.dart:161` (`_saveDraft`) | throws `StateError` |
| Submit experience for review | `host_experience_preview_screen.dart:223` (`_submit`) | throws `StateError` (uncaught) |
| Pause / resume listing | `host_experience_detail_screen.dart:188` (`_toggle`) | throws `StateError` |
| Update dates & availability | `host_availability_screen.dart:119` (`_save`) | throws `StateError` |
| Accept / decline booking request | `host_booking_detail_screen.dart:250` (`_decide`) | throws `StateError` |
| Edit host profile | `edit_host_profile_screen.dart:118` (`_save`) → `updateHostProfile` | **works** (only override present; writes `profiles.full_name/bio/location`) |

Only `MockHostModeRepository` (test-only, `lib/features/host/data/mock_host_mode_repository.dart`) implements these mutations, in memory. Several screens also print their own disclaimer copy ("temporary frontend state", "resets when the app restarts", "in-memory only"), i.e. the read-only state is partly acknowledged in the UI text but the buttons are still live and will surface a raw error.

Working host writes that DO exist:
- Host **application** questionnaire (`host_questionnaire_screen.dart` → `HostRepository.saveQuestionnaireDraft` / `submitQuestionnaire` → edge function `submit-host-application`).
- Host **document upload** to storage bucket `host-documents` (`HostRepository.uploadHostDocument`).
- Host **profile** edit (name/bio/location) — as above.
- **Messaging** (`send_trip_message`, `mark_trip_conversation_read` RPCs) — fully wired, realtime.

---

## 1. Inventory — every host-facing screen in `lib/`

Route guards: `HostModeAccessGate` = authenticated **and** `current_host_access()` returns approved+active (`widgets/host_mode_access_gate.dart`). `HostApplicationAuthGate` = authenticated only (`widgets/host_application_auth_gate.dart`).

### 1a. Become-a-host / onboarding

| Route | File | Shows | Host can |
|---|---|---|---|
| `/host` | `become_host_screen.dart` | Marketing landing: hero, "what can you host" chips, benefits, 3-step "how it works", verified-badge note. CTA label is state-aware (`Start` / `Continue` / `View status` / `Go to dashboard`). | Start or resume the application; deferred-auth redirect to `/auth/required` if signed out |
| `/host/application/:step` (+ redirects `/host/step-1..4`) | `host_questionnaire_screen.dart` | **8-step** questionnaire. Step 1 hosting type; 2 host type + name/org/email/phone; 3 province/district/locality + min/max guests; 4 availability type + days/dates + pricing model + price; 5 inclusions checklist + cancellation policy; 6 identity type + doc number + front/back upload + conditional business/safety docs; 7 description + host photo + location photos + optional logo; 8 review + terms checkbox. Progress bar, per-step validation, draft autosave to `host_applications.application_data` + `current_step`. | Fill/edit answers, upload docs (signed-URL preview on review step), submit |
| `/host/submitted` | `application_submitted_screen.dart` | Confirmation + status pill from `myHostApplicationProvider` (`UNDER REVIEW` / `ACTION REQUIRED` / `APPROVED` / `REJECTED` / `DRAFT`). | Return to `/profile` |
| — (not routed) | `host_step_1_screen.dart` … `host_step_4_screen.dart` | **DEAD CODE.** Legacy 4-screen flow (personal+bio / experience details+duration / ID type+PAN / **bank payout: bank name, account name, account number, branch**). Backed by `host_provider.dart` `HostApplicationData` + `HostRepository.submitHostApplication` (legacy payload). Only referenced by `test/host_application_test.dart`. Not in `router.dart`. | n/a |

### 1b. Host Mode — tabbed shell (`HostModeScaffold`, 5 tabs: Dashboard / Experiences / Bookings / Messages / Profile)

| Route | File | Shows | Host can |
|---|---|---|---|
| `/host/dashboard` | `host_dashboard_screen.dart` | Greeting + name. Stats grid: Active Experiences, Upcoming Guests, Pending Requests, Upcoming Earnings (NPR, = sum of confirmed-booking totals). "Needs Attention" = first pending request card (traveler name, count, trip dates, Review button) + unread-messages row. "Upcoming Experience" card (image, dates, location, spots filled, occupancy bar, Manage / Message Guests). Quick actions: Create Experience, Manage Bookings. Notification bell → `/host/profile/notifications`. | Navigate; no data entry |
| `/host/experiences` | `host_experiences_screen.dart` | Filter chips (All / Published / Drafts / Pending Review / Paused). Cards: image, title, location, start date, `booked/capacity`, price per guest, status chip. FAB "Create". | Filter; open detail; launch create |
| `/host/experiences/create` (+ `/:id/edit`) | `create_host_experience_screen.dart` | **9 build steps** + preview: Basic Info (title/location/description), Photos (device picker + 3 bundled assets), Trip Details, Itinerary list, What's Included list, What to Bring list, Dates & Availability (start/end/capacity), Pricing (price per guest), Meeting Point (text + stub "map pin" that hardcodes Lakeside, Pokhara). Step counter "of 10". | Enter everything; "Save draft" and "Preview"→"Submit for review" **both throw in production** (§0) |
| `/host/experiences/create/preview`, `/host/experiences/:id/preview` | `host_experience_preview_screen.dart`, `host_listing_preview_screen.dart` | Read-only render of the draft / published listing as a traveler would see it. Preview screen's "Submit for review" throws (§0); listing preview's Book button is deliberately disabled. | View only |
| `/host/experiences/submitted` | `host_experience_submitted_screen.dart` | "Submitted for review" confirmation. | Go to Experiences |
| `/host/experiences/:id` | `host_experience_detail_screen.dart` | Header card (image, title, location, status chip, departure range, `booked/capacity`, guest price). Control list: Preview listing, Edit, Manage dates & availability, View booking occupancy, View related bookings, Message confirmed guests, Pause/Resume. | Navigate; Pause/Resume **throws** (§0) |
| `/host/experiences/:id/availability` | `host_availability_screen.dart` | Start date, end date, capacity fields, seeded from the experience. Disclaimer "in-memory only". | Edit + "Update availability locally" **throws** (§0) |
| `/host/bookings` | `host_bookings_screen.dart` | Two tabs. **Booking details**: status filter chips (All/Requests/Confirmed/Completed/Cancelled), optional per-experience filter banner, cards (traveler initial+name, traveler count, status pill, experience title, trip date range, NPR total). **Payments**: summary card (Total booking value, Advance collected, Remaining) + per-booking card (booking total / advance / remaining + transaction rows: provider, amount, `STATUS · date`, provider reference). | Filter; open booking detail |
| `/host/bookings/:id` | `host_booking_detail_screen.dart` | Traveler initial+name, traveler count. Detail rows: Experience, Dates, Request total, Status, Submitted. "Traveler note" card (**hardcoded string** `Booking from your host account.` from the Supabase repo, not a real column). "Application answers" card (**hardcoded placeholder** `No structured application-answer fields are stored yet.`). Buttons: Message traveler; if confirmed → View departure details / Message departure group; if requested → Decline / Accept + disclaimer. | Message; Accept/Decline **throws** (§0) |
| `/host/bookings/:bookingId/travelers/:travelerId` | `host_traveler_detail_screen.dart` | Traveler avatar+name. Rows: Email, Phone, Emergency contact, Dietary notes. From the Supabase repo these are `full_name` + `contact_phone`; **email = `Not provided`, emergency = `Not provided`, dietary = `None provided`** (hardcoded — columns do not exist). Message traveler button. | Message |
| `/host/departures/:experienceId` | `host_departure_detail_screen.dart` | Experience title, date range, location, `guests confirmed / capacity` + progress bar. Buttons: View participant list, Message departure group, Update departure availability. | Navigate |
| `/host/departures/:experienceId/guests` | `host_guest_list_screen.dart` | Departure header (title, date, `N confirmed guests`, progress vs hardcoded `/8`). List of confirmed travelers (name + dietary-notes subtitle, which is the hardcoded `None provided`). | Open a traveler; Message group |
| `/host/messages` | `host_messages_screen.dart` | Searchable conversation inbox (realtime `watchConversations`): identity, experience title, last message, unread badge. | Search; open a thread |
| `/host/messages/:id` | `host_conversation_screen.dart` | Full thread: bubbles, delivered/seen receipts, edit/delete mutations, attachment support, pending/failed states, realtime. | Send / edit / delete messages, attach, mark read |
| `/host/profile` | `host_profile_screen.dart` | Avatar (initial), display name + verified tick, "Host account". Menu: View Public Profile, Edit Host Profile, Verification & Documents, Earnings & Payouts, Reviews, Hosting History, Notifications, Help & Support, Hosting Guidelines, Terms & Policies. Switch-to-traveler-mode card. Logout. | Navigate; switch mode; log out |
| `/host/profile/edit` | `edit_host_profile_screen.dart` | Display name, bio, location, languages. "Save profile locally" (copy says session-only but this one **does persist** name/bio/location via `updateHostProfile`). | Edit + save (partial persist) |
| `/host/profile/public` | `host_business_screen.dart` (`publicProfile`) | Sage header card: avatar, name + verified, intro. Items: name→bio, Location. Edit-profile button. | View; go to edit |
| `/host/profile/verification` | `host_business_screen.dart` (`verification`) | **Stub.** One item: "Host status — Approved / Active". No document list, no expiry, no re-upload. | View only |
| `/host/profile/earnings` | `host_business_screen.dart` (`earnings`) | Intro "Display only. Secure payout processing is not connected." One item: "Upcoming booking value — Confirmed bookings — NPR <sum of confirmed totals>". "Manage payout method" button → `showUnavailableNotice`. | View only |
| `/host/profile/reviews` | `host_business_screen.dart` (`reviews`) | **Stub** — `_displayOnly('Reviews')`: single "Coming soon" item. | Nothing |
| `/host/profile/history` | `host_business_screen.dart` (`history`) | **Stub** — "Coming soon". | Nothing |
| `/host/profile/notifications` | `host_business_screen.dart` (`notifications`) | **Stub** — "Coming soon" (mock had 3 sample items; Supabase path returns `_displayOnly`). | Nothing |
| `/host/profile/help` `/guidelines` `/terms` | `host_business_screen.dart` | **Stubs** — "Coming soon" / "not available yet". | Nothing |

---

## 2. Gap table — against the "HOST DASHBOARD SHOULD SHOW" list

Status: **PRESENT** (rendered from live backend data) / **PARTIAL** (rendered but hardcoded, incomplete, or non-functional) / **NOT PRESENT**.

| # | Item | Status | Where (file) | Note |
|---|---|---|---|---|
| 1 | Basic details already acquired | **PARTIAL** | `host_profile_screen.dart`, `host_business_screen.dart` (`publicProfile`) | Only name / bio / location / languages surface. The application captured province/district/locality, host type, org name, capacity, availability, pricing model, inclusions, cancellation policy, identity type — none of that is shown back to the approved host. `verification` page is a 1-line stub. |
| **Per-booking:** | | | | Data source: `SupabaseHostModeRepository.getBookings` (`bookings` + `booking_participants` + `host_booking_payment_transactions()` RPC) |
| 2 | Booking id | **NOT PRESENT** | — | `bookings.booking_ref` (unique) exists in DB; no host screen renders it. Booking detail rows are Experience/Dates/Request total/Status/Submitted only. |
| 3 | Customer name | **PRESENT** | `host_booking_detail_screen.dart:52`, `host_bookings_screen.dart` | `bookings.contact_name` |
| 4 | Number of people | **PRESENT** | `host_booking_detail_screen.dart:56` | `adults + children` |
| 5 | Date | **PARTIAL** | `host_booking_detail_screen.dart:69` | Shows the **experience departure** date range, not a per-booking date; no time-of-day anywhere (`experience_departures` has `start_date`/`end_date` only, no time). |
| 6 | Time | **NOT PRESENT** | — | No time column on `experience_departures` or `bookings`. |
| 7 | Service (which experience) | **PRESENT** | `host_booking_detail_screen.dart:67` | `experienceTitle` |
| 8 | Amount | **PRESENT** | `host_booking_detail_screen.dart:74` | `bookings.total_paisa` |
| 9 | Customer contact info | **PARTIAL** | `host_traveler_detail_screen.dart:54` | Phone = `bookings.contact_phone`. **Email hardcoded `Not provided`**, **emergency contact hardcoded `Not provided`** — no columns. |
| 10 | Payment status | **PRESENT** | `host_bookings_screen.dart` Payments tab (`_PaymentTransactionRow`) | `payments.status` via `host_booking_payment_transactions()` |
| 11 | Special request | **NOT PRESENT** | `host_booking_detail_screen.dart:88` renders `item.note`, but Supabase repo hardcodes it to `Booking from your host account.` | No `special_request` / `notes` column on `bookings`. `applicationAnswers` likewise hardcoded to a placeholder string. |
| **Money totals:** | | | | Payments tab computes from booking totals + paid transactions only |
| 12 | Total sales | **PARTIAL** | `host_bookings_screen.dart` `_PaymentsTab` ("Total booking value"), `host_business_screen.dart` earnings ("Upcoming booking value") | Sum of booking totals in view / sum of confirmed-booking totals. Not a real sales ledger; no date-scoped "sales". |
| 13 | Refund | **NOT PRESENT** | — | No refund figure anywhere on the host surface; no refund/ledger table. |
| 14 | Not payable | **NOT PRESENT** | — | Concept doesn't exist in code (depends on commission direction). |
| 15 | Pending settlement | **PARTIAL** | `host_bookings_screen.dart` `_PaymentsTab` ("Remaining amount" / "Remaining") | "Remaining" = `booking total − paid transactions`, i.e. amount still to collect **from the traveler**, not amount the platform owes the host. No settlement concept. |
| 16 | Paid amount | **PARTIAL** | `host_bookings_screen.dart` `_PaymentsTab` ("Advance collected") | = sum of `payments` rows with status `paid`. Gross traveler payment, not host-payable net. |
| **Reputation:** | | | | |
| 17 | Total users | **NOT PRESENT** | — | No unique-guest count. Dashboard "Upcoming Guests" = headcount of confirmed bookings only. |
| 18 | Overall rating | **NOT PRESENT** | `host/profile/reviews` is a stub | `experiences.rating_avg` / `rating_count` exist and are trigger-maintained; not read anywhere in the host surface. |
| 19 | Individual review | **NOT PRESENT** | `host/profile/reviews` is a stub | `reviews` table (rating, title, body, photos) exists and is populated on the traveler side; host surface renders "Coming soon". |
| **Ops:** | | | | |
| 20 | Upcoming bookings | **PRESENT** | `host_dashboard_screen.dart` ("Upcoming Guests" stat, "Upcoming Experience" card), `host_bookings_screen.dart?status=confirmed` | Filter + dashboard widgets exist. No single dedicated "upcoming bookings" list sorted by date, but the pieces are there and backend-driven. |
| 21 | Report customer | **NOT PRESENT** | — | No flag/report action on any host booking, traveler, or conversation screen. (`report_trip_message` exists but is traveler-facing message-level, not "report this customer".) No `user_reports` / `customer_reports` table. |

---

## 3. Blockers for PARTIAL / NOT PRESENT rows, grouped

### Group A — UI task only (data exists, screen doesn't render it)

| Item | Missing render | Data already available |
|---|---|---|
| 1 Basic details | Approved-host "your details" view; real verification/documents page | `host_applications.application_data` (full JSON), `host_documents` (as of `20260909120000`), `host_accounts` |
| 2 Booking id | booking ref on booking detail/list | `bookings.booking_ref` |
| 5 Date (per-booking) | booking-level date instead of departure range | `bookings.created_at`; departure `start_date` |
| 17 Total users | distinct guest count | `bookings.user_id` (+ `booking_participants`) |
| 18 Overall rating | rating figure on reviews page | `experiences.rating_avg`, `experiences.rating_count` |
| 19 Individual review | review list on reviews page | `reviews` (rating/title/body/photos), joined by `experience_id` for host's own experiences |
| 20 Upcoming bookings | (already effectively present) dedicated date-sorted list if wanted | `bookings` + departures |

Also UI-only but blocked on the read-only-repo fix (§0), not on schema: experience create/edit/submit, pause/resume, availability update, booking accept/decline. The screens and validation exist; they need `SupabaseHostModeRepository` to implement the writes (against existing tables + the existing `prevent_client_booking_status_change` / `prevent_client_host_app_status_change` service-role triggers, so accept/decline needs an edge function or RPC).

### Group B — data doesn't exist yet (missing table / column)

| Item | Missing schema |
|---|---|
| 6 Time | no time-of-day column on `experience_departures` (or `bookings`) |
| 9 Customer contact info | `bookings` has no `contact_email`; no emergency-contact column; `booking_participants` has no email/phone/emergency/dietary — host UI already has placeholders wired for all four |
| 11 Special request | no `special_request` / `notes` column on `bookings`; no structured per-booking application answers |
| 21 Report customer | no `customer_reports` / `user_reports` table; no RPC; no host UI |

### Group C — blocked on the settlement ledger (no payout code anywhere in the repo)

Confirmed absent: no `settlements`, `payouts`, `ledger`, `host_balances`, or `refunds` table in `supabase/migrations/`; no payout edge function; earnings screen literally says "Secure payout processing is not connected" and the payout button calls `showUnavailableNotice`.

| Item | Needs |
|---|---|
| 13 Refund | refund records + refund edge/RPC (ties to cancellation path — N3) |
| 15 Pending settlement | settlement ledger: what the platform owes the host, per booking/period, net of fees, minus already-paid-out |
| 16 Paid amount (host-payable) | payout records (distinct from traveler `payments`) |
| 12 Total sales (true) | date-scoped sales aggregation off a ledger rather than summing booking rows |

### Group D — blocked on the commission-direction decision

| Item | Why |
|---|---|
| 14 Not payable | "not payable" only has meaning once it's decided whether the platform collects and remits to the host (host is principal) or the host collects and owes commission (host is agent). The number, and whether it's even shown to the host, depends on that. |
| 12/15/16 (net figures) | the net-vs-gross split in every money row depends on the same decision |

**Summary:** items 2, 5, 17, 18, 19 and most of item 1 are pure UI tasks on existing data. Items 6, 9, 11, 21 need additive schema. Items 13, 15, 16 (and a true version of 12) wait on the settlement ledger (N3). Item 14 and the net/gross framing of all money rows wait on the commission-direction decision. The entire experience-management + booking-decision surface is built but non-functional pending the read-only-repo fix (§0).

---

## 4. Application & create-experience flows vs the doc's screen counts

The doc text isn't in the repo; comparison is against `docs/HOST_APPLICATION_CONTRACT.md` and the code.

### 4a. Create-experience flow vs "only ask 7 things"

Live flow (`create_host_experience_screen.dart`) asks **9 steps** before a 10th preview/submit step:

1. Basic Information — title, location, description
2. Photos — device picker + 3 bundled asset options (min 1)
3. Trip Details — free text, ≥20 chars
4. Itinerary — structured list, ≥1 item
5. What's Included — structured list, ≥1 item
6. What to Bring — structured list, ≥1 item
7. Dates & Availability — start date, end date, capacity 1–100
8. Pricing — price per guest (NPR)
9. Meeting Point — instructions text + stub map pin

vs a 7-item target this asks **more**: itinerary, what-to-bring, and a separate meeting-point step are the extras; a 7-thing version would likely fold itinerary/inclusions/bring into one "what's included" step and drop the meeting-point step (or merge it into basics). It also **can't submit** in production (§0). Note it overlaps heavily with the host application questionnaire (which already collected hosting type, capacity, availability, pricing, inclusions) — a published experience currently re-asks most of it.

### 4b. Host application screens vs the doc's "Screens 1-4"

Two flows exist:

- **Legacy (dead, matches a 4-screen shape):** `host_step_1..4_screen.dart` — (1) personal + district + bio, (2) experience title + category + duration + group size + price + description, (3) ID type + number + document upload, (4) **bank payout details** (bank, account name, account number, branch). Not routed; only exercised by `test/host_application_test.dart`. Backed by `host_provider.dart` + `HostRepository.submitHostApplication`.
- **Live:** `host_questionnaire_screen.dart` — **8 steps** (see §1a), backed by `HostRepository.saveQuestionnaireDraft` / `submitQuestionnaire` and the `host-applications` contract. `host_applications.current_step` is bounded `check (current_step between 1 and 8)` — the `0011` value of `1 and 4` was widened by `20260906120000_shared_host_questionnaire.sql` (2026-09-06) to match the live flow, so there is no client/DB mismatch. (An earlier draft of this audit said otherwise; corrected.) Regression guard: `supabase/tests/host_applications_current_step.test.sql`.

Where the live flow **asks more** than a 4-screen version: it splits into 8 steps and adds province/district/locality granularity, availability type + days/date-range + availability note, pricing model (per person / per group / starting / custom quote), inclusions checklist + details, cancellation policy + custom text, identity front **and** back, conditional business-registration and safety/guide-certification uploads, host photo, multiple location photos, optional business logo, and an explicit terms checkbox.

Where it **asks less / drops** vs the legacy flow: **no bank / payout details are collected anywhere in the live flow** (consistent with §3 Group C — there is no payout system). No standalone "duration in hours" field (replaced by availability model). No fixed category picker tied to `categories` (hosting type is free-standing, mirrored to `category_id` only when a matching category exists, per the contract).

---

*Read-only audit. No code, schema, or migrations changed. P2's notification-copy halt is unchanged.*
