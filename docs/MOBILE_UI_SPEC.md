# PLAN E — Mobile App UI Spec

Reverse-documented from the shipped Flutter app (`lib/`) as the reference for planning the website UI. Every screen below is real, current code — not the design mockups in `_incoming/`.

---

## 1. Design tokens (`lib/theme/`)

**Colors** (`tokens.dart`):
| Token | Hex | Use |
|---|---|---|
| `forest` | `#18372D` | primary brand, active nav, buttons |
| `deep` | `#01251C` | dark accents, gradients |
| `ivory` / `white` | `#FFFFFF` | backgrounds, cards |
| `sage` | `#E7ECE7` | tinted backgrounds, chip fill |
| `ink` | `#24312D` | body text |
| `gold` | `#8F5E1B` | accents, dividers, price highlights (WCAG AA 5.07:1 on ivory) |
| `error` / `errorContainer` | `#BA1A1A` / `#FFDAD6` | error states |
| `success` / `successContainer` | `#2E6C40` / `#D2E8D4` | success states |
| `warning` / `warningContainer` | `#7D5200` / `#FFDDB3` | warnings, pending states |
| `border` / `borderSubtle` | `#CBD5CE` / `#E2E8E4` | card borders |
| `cardBackground` / `cardBackgroundAlt` | `#FFFFFF` / `#FAF8F5` | card surfaces |
| `skeletonBase` / `skeletonHighlight` | `#E3E8E4` / `#F2F5F3` | loading shimmer |

**Spacing scale:** 4 / 8 / 12 / 16 / 20 / 24 / 32 / 40 (xs4 → huge40). Standard screen padding: 16px horizontal, 12px vertical.

**Radii:** sm 8px, md 16px (cards), lg 24px, pill 999px (buttons/chips).

**Touch target minimum:** 48×48.

**Typography** (`typography.dart`) — sans-serif system font, plus `DancingScript` cursive for the splash tagline and a serif override used for headlines app-wide:
| Style | Size | Weight |
|---|---|---|
| displayLarge | 32 | bold |
| displayMedium | 28 | bold |
| headingLarge | 24 | 700 |
| headingMedium | 20 | 600 |
| bodyLarge | 16 | 400 |
| bodyMedium | 14 | 400 |
| caption | 12 | 400 |

Headlines across the app consistently use a serif face at large sizes (e.g. "Discover Nepal your way.", "Plans", "Saved Experiences") — this is a deliberate departure from the sans body font, worth carrying to web as a display/serif pairing.

---

## 2. Navigation map

Bottom tab bar (5 tabs, pill-shaped floating bar, icons only — no labels): **Home · Explore · Plans · Saved · Profile**.

Full route tree (from `lib/router.dart`):

```
/                              splash (auto-redirects)
/welcome                       first-run entry
/onboarding/1,2,3               intro carousel
/interests                      pick 3+ interests

/auth/sign-up /login /forgot-password /reset-result
/auth/otp-verify /set-new-password /required

/home                            ┐
/explore  /map                   │  bottom-tab shell
/search   /collection/:slug      │
/plans /trips(→/plans?tab=past)  │
/saved                           │
/profile                         ┘

/filter                          modal sheet
/experience/:id
/booking/:id  /booking/confirmation/:bookingId
/itinerary/:bookingId /chat/:bookingId /gear/:bookingId /budget/:bookingId
/review/:bookingId /review/submitted

/profile/edit /payment-methods /notifications /language /help /settings /my-reviews
/notifications                   (feed, distinct from /profile/notifications prefs)
/ai-planner

/host                             become-a-host landing
/host/step-1..4  /host/submitted  application wizard
/host/dashboard                   ┐
/host/experiences (+/create/.../:id/edit/.../:id/availability/.../:id)
/host/bookings (+/:id, +/:bookingId/travelers/:travelerId)
/host/messages (+/:id)            │  host-mode bottom-tab shell
/host/profile (+/public/edit/verification/earnings/reviews/history/notifications/help/guidelines/terms)
/host/departures/:experienceId (+/guests)
```

---

## 3. Reusable component library (`lib/widgets/`)

These are the atoms every screen composes from — the equivalent set is what a website design system needs to define first.

| Widget | What it is |
|---|---|
| `AppCard` / `PlanECard` | Base card: white, rounded, 1px border, optional shadow/tap |
| `AppButton` | primary / secondary / text variants, loading spinner, icon slot, full-width option |
| `AppTextField` | Labeled input, prefix/suffix icon, validator, obscure-text toggle |
| `ExperienceCard` | Core listing card — image, title, location, stars, price, bookmark toggle; horizontal/poster/square variants |
| `ExperienceFamilyCard` | Dark gradient-over-photo category tile |
| `ExperienceMoodGrid` | Icon+label mood tiles (Relax/Explore/Learn/Connect) |
| `FilterChipPill` | Pill-shaped selectable chip (forest when active) — the universal filter/sort control |
| `SectionHeader` | Title + subtitle + optional "See All" action link |
| `ContentRail` | Horizontal-scroll row under a `SectionHeader` |
| `RatingStars` | 5-star display, optionally interactive for rating input |
| `PriceBottomBar` | Sticky bottom bar: price + CTA button |
| `ProgressSteps` | Horizontal numbered stepper for multi-step flows |
| `CounterField` | Label + (–/+) stepper for quantities |
| `AppTabs` | Pill-style horizontal tab selector |
| `OrnamentDivider` | Thin gold hairline with a centered rotated-square accent |
| `PlanEBackground` | Shared ivory background with faint contour-line texture |
| `PlanELogo` | Wordmark built from individually positioned letters |
| `AsyncValueView` | Universal loading (skeleton) / error / empty / data wrapper — used on nearly every data-driven screen |
| `EmptyStateView` / `ErrorStateView` | Icon + title + description + optional retry/CTA |
| `AppToast` | Success/error/info snackbar |
| `AppSkeleton` | Pulsing placeholder box/circle for shimmer loading |
| `OfflineBanner` | Full-width warning banner: "You are currently offline, displaying cached data" |
| `TripPresenceIndicator` | "Online now" / typing indicator banner above chat |
| `PrivateTripAttachment` | Resolves private storage path → signed URL, renders inline in chat |

**Pattern used everywhere:** loading → 3 stacked skeletons; error → icon + message + Retry; empty → icon + title + description + optional action button. Carry this 3-state pattern to every data list on the website.

---

## 4. Onboarding

### Splash (`/`)
Full-bleed hero photo, white wash. Animated wordmark: "N E P A L" letters fade in, morph into "PL[▲]NE" (the A becomes a mountain glyph), 🇳🇵 fades in. Cursive tagline "Plan Your Experience". Footer: "powered by CodePeak Nepal". Pure animation, 2.8s, then auto-routes based on session/onboarding state — no buttons.

### Welcome (`/welcome`)
Full-bleed hero photo + gradient. Header: logo + "PLAN YOUR EXPERIENCE" caption. Hero text bottom-left: "Experience Nepal 🇳🇵" + gold underline + subtitle. Floating white card: Continue with Phone / Google / Apple (iOS only) / divider "or continue with email" / Continue with Email / text-button "Continue as Guest". Trust-badge row: Secure & Safe · Local Experts · 24/7 Support.

### Onboarding carousel (`/onboarding/1-3`)
Header: logo + Skip. 3-slide swipeable `PageView`, each a circular icon badge + serif title + description: "Explore Nepal Differently", "Find Your Kind of Experience", "Make Your Time Meaningful". Dot indicator. Bottom button: Next → Select Interests on last slide. Copy is CMS-overridable.

### Interests (`/interests`)
Header: back + logo + Skip. Heading "What are\nyou into?" + "select at least 3". Body grouped by experience family: family name + description, then a `Wrap` of icon+label filter chips per category. Live counter "{n} / 3 selected" (turns green at 3+). Bottom Continue button, disabled until 3 selected.

---

## 5. Auth

All auth screens share one shape: AppBar title → heading + subtitle → `AppTextField` stack → primary button (loading state) → "OR" divider → Google/Apple buttons → footer link to the other flow.

- **Sign Up** (`/auth/sign-up`): Full Name, Email, Password (show/hide), Confirm Password. → OTP verify.
- **Login** (`/auth/login`): Email-or-Phone, Password, "Forgot Password?" link.
- **Forgot Password** (`/auth/forgot-password`): Email-or-Phone → email path goes to OTP verify, phone path goes to Reset Result.
- **Reset Result** (`/auth/reset-result`): static confirmation, green icon, one button back to Login.
- **Auth Required** (`/auth/required`): full-screen gate, visually identical to Welcome, shown when a guest attempts a gated action; dynamic copy "to {action}"; has a "Not Now" dismiss.
- **OTP Verify** (`/auth/otp-verify`): 6-digit code field, "Resend code in {n}s" cooldown timer (30s).
- **Set New Password** (`/auth/set-new-password`): New Password + Confirm, both obscured.

---

## 6. Home (`/home`)

Rendered inside pull-to-refresh, scaled to 0.9.

1. **Hero** (full-bleed photo, dark gradient): logo + "Use current location" row; notification bell (unread gold dot); points pill "{n} pts"; headline "Discover Nepal\nyour way."; white pill search bar → `/search`; two buttons "Curated Trips" and (if AI flag on) "Plan with AI".
2. **"Happening This Week" rail** — horizontal square cards, "See All" action.
3. **Five category sections** (Adventure Together / Soul & Mind / Meet People / Give Back / Live Like a Local): header + "See All", horizontal filter-chip row, horizontal grid of cards. Selecting a chip switches the rail to a filtered "Most Popular" view with an "Overview" toggle back.

Bookmark taps route guests to `/auth/required`. One-time silent location fetch on load (no permission-prompt dialog shown).

---

## 7. Explore (`/explore`)

- Collapsing hero header (photo) → "Explore" title + bell, collapses down to a floating pill search bar.
- Inline search results (if query non-empty): count + list of horizontal cards.
- "Browse by experience" — 2-column grid of dark gradient family tiles, "All filters" action opens the Filter sheet.
- "Explore by mood" — icon mood grid (Relax/Explore/Learn/Connect).
- "Explore by location" — horizontal scroll of gradient region cards (icon watermark + English/Nepali name).
- Floating action button bottom-right → `/map`.

Search is debounced 350ms; pull-to-refresh supported.

### Map (`/map`)
Full-screen `flutter_map` (OpenStreetMap tiles). Pill markers (icon + title, gold price sub-pill). Zoom/recenter controls top-right. Tapping a marker shows a floating preview card (thumbnail, title, rating, price, "View Experience"). Bottom fixed panel: "Meeting Point" + lat/lng, "Copy Address" and "Open in Maps" (native intent) buttons.

---

## 8. Search & filtering

### Search Results (`/search`)
Collapsing header morphs from logo into a search field on scroll; breadcrumb label (family • category) fades in. Family-scoped category chip row if a family is active. "Recent Searches" chip strip when field is focused/empty. Results: full-width cards with the standard loading/error/empty triad; "Reset Search" action on empty.

### Collection ("See All") (`/collection/:slug`)
AppBar with dynamic title per slug (Recommended for You, Trending, Live Like a Local, etc.), subtitle description + count, then a plain list of full-width cards.

### Filter sheet (`/filter`, modal)
"Filter & Sort" + Reset All. Facets, each a `Wrap` of pill chips unless noted:
- Sort By: Relevance, Highest Rated, Most Popular, Price ↑/↓, Duration: Shortest, Newest
- Experience family
- Difficulty (only for families that support it): Any/Easy/Moderate/Challenging/Strenuous
- Price Range (NPR): two numeric fields, Min/Max
- Duration: Any, Up to 2h, Half day, Full day, Weekend, Up to 3 days
- Experience type (progressively filtered by family)
- Region
- "Apply Filters" button

---

## 9. Experience detail (`/experience/:id`)

Two presentations depending on category taxonomy.

**Standard:**
1. Full-bleed cover photo (265px) + back/share/save circular buttons overlay.
2. Spots-left strip: sage "⚡ Instant confirmation" or a colored bar "N spots available on D MMM" (turns orange/fire icon at ≤5 left).
3. Title block: optional "FAMILY • TYPE" pill tag, serif title, location, star rating.
4. Quick-stats grid: Duration, Group size, Min age (+ Difficulty/Altitude for adventure family).
5. "About this experience" card — description clamped to 4 lines with Read more/Show less.
6. Organizer card — avatar, host name, "Verified local host".
7. Schedule card (if itinerary exists) — day/time + title + description rows.
8. Price card (sage tint) — big price + "/ person".
9. What's Included / What to Bring — checklists (only if non-empty).
10. Meeting Point card — address + "View on Map" → `/map`.
11. Things to Know — bullet list.
12. Reviews — up to 2 shown, "No reviews yet" fallback.
13. **Sticky bottom bar**: price + "JOIN NOW" → `/booking/:id`.

**Limited-package presentation** (curated multi-day treks): swipeable photo gallery with counter; centered content column with Basic Info, expandable per-day Schedule (`ExpansionTile`), Checklist, Things to Know, disabled "Download Itinerary", and a **Choose Your Package** radio choice between a fixed Standard Package (price + inclusions) and a "Plan It Your Own Style" dynamic customization form (locked items, exclusive-choice radios, optional add-ons with note fields) — ends in "not available yet" for actual customization. Sticky bottom bar: "CHOOSE PACKAGE" scrolls down, "CONTINUE" only enabled for Standard.

---

## 10. Booking & confirmation

### Booking form (`/booking/:id`)
AppBar "Booking Form" → `ProgressSteps` (Booking Details, Confirmation) → form:
- Experience header card (title, location, price/adult)
- Departure date list — radio cards, spots-left warning in red if <5
- Guest counts — Adults/Children `CounterField`s, capped by max spots
- Contact info — Name, Nepali phone, optional notes
- Price breakdown card — Adults/Children lines, 5% service fee, total
- Sticky bottom bar: total + "Proceed to Pay"

**Payment sheet** (modal): order summary, "Quote valid for 15 mins" countdown chip, gateway choice (Khalti / eSewa — eSewa hidden if flagged off), "Pay {amount} via {Gateway}" → in-app webview → verifies → `/booking/confirmation/:id`.

### Confirmation (`/booking/confirmation/:id`)
Green check circle, "Booking Confirmed!". Receipt card: status pill + ref, contact, guests, date, total paid. "Next steps" card: View schedule → `/itinerary/:id`, Message host → `/chat/:id`. Buttons: "VIEW MY PLANS" → `/plans`, "BACK TO HOME".

---

## 11. Plans, trip tools, reviews, saved

### Plans (`/plans`)
Serif "Plans" heading, 4 tabs: Upcoming / Drafts / History / Cancelled.
- **Upcoming card**: cover photo w/ gradient title, CONFIRMED badge, date+guests, total paid, itinerary/chat icon shortcuts. Also renders an extra "Experience Tools" section (Schedule/Messages/Gear/Budget/Directions tool cards, conditionally shown per experience family).
- **Draft card**: DRAFT badge, estimated total, Delete + Continue buttons.
- **History card**: COMPLETED, "View Details" + "Leave Review"/"Reviewed" (disabled once done).
- **Cancelled card**: CANCELLED, "Book Again".

### Itinerary (`/itinerary/:bookingId`)
Experience banner card + tool shortcuts row (Messages/Gear/Budget) + "Experience Schedule" day cards (D{n} badge + title + description).

### Trip Chat (`/chat/:bookingId`)
Presence indicator banner. Chat bubbles (forest = me, bordered card = other), attachments, edited tag, pending/failed/retry, delivered/seen ticks. Long-press → Edit/Delete (own) or Report/Block (other). Input bar: attach icon, pill text field, circular send button.

### Gear Checklist (`/gear/:bookingId`)
Progress card ("checked / total, pct%" + progress bar). "Add Custom Item" button. Checkbox list items, strikethrough when checked, "Custom" badge + delete for user-added items.

### Budget Tracker (`/budget/:bookingId`)
"Total Spent" card, category breakdown (icon + amount + % bar per category), "Log Expense" button → modal (name, amount, category dropdown). Recent expenses list with delete.

### Leave Review (`/review/:bookingId`)
"How was your experience?" heading. Rating card: dynamic label (Poor→Excellent) above 5 large tappable stars. Optional title + body fields. "Submit Review" → success dialog → `/trips` (i.e. `/plans?tab=past`).

### Saved (`/saved`)
Logged-out: empty state + "Log in". Logged-in: "Saved Experiences" heading, 2-column grid cards with a heart-remove button overlay on each photo.

---

## 12. Profile & settings

### Profile (`/profile`)
Centered avatar, name, location, "EDIT PROFILE" pill. Stats card: History / Saved / Points (tappable). Settings list card: My Plans, My Reviews, Payment Methods, Notifications, Language & Region, Help & Support, Settings, (admin only) Message moderation. Dynamic host CTA button (3 states: Become a Local Host / Host Under Review / Host Verified). "LOGOUT" text button.

### Edit Profile (`/profile/edit`)
Avatar with camera-upload badge. Form: Name, Phone, Location, Bio. Save button.

### Payment Methods (`/profile/payment-methods`)
3 mocked gateway cards (Khalti default / eSewa / Cash on Arrival) with radio selection, "DEFAULT" badge.

### Notification Preferences (`/profile/notifications`)
5 toggle rows: Trip Updates, Host & Direct Messages (real OS push-permission flow), Weather Alerts, Promotions, App Sound & Vibration.

### Language & Region (`/profile/language`)
Language list (English, Nepali, Nepal Bhasa, Tamang) + Currency list (NPR/USD). Selection-only, not persisted.

### Help & Support (`/profile/help`)
Hero card: "Need Immediate Help?" + Call Us / Live Chat (stub) buttons. FAQ accordion (4 items). Email support row.

### More Settings (`/profile/settings`)
App Preferences (Dark Theme toggle, Offline Maps toggle, Clear Cache). Legal & Info (Terms/Privacy stubs, Open Source Licenses — real). Footer: app version.

### My Reviews (`/profile/my-reviews`)
List of the user's own reviews: experience title, date, stars, comment.

### Notification Feed (`/notifications`)
Distinct from preferences — this is the inbox. "Mark all read" action. List tiles: type icon (booking/chat/host/promo/system), bold-if-unread title, 2-line body, relative time, unread gold dot.

---

## 13. AI Trip Planner (`/ai-planner`)

Two input modes toggled by pill chips:
- **Guided**: trip type chips (Trekking/Wildlife/Culture/Wellness/Adventure), duration counter (1–21 days), pace chips, "who's going" chips, optional budget field, optional free-text extra.
- **Describe it**: single large free-text field with example placeholder.

"Generate My Plan" button (disabled while offline — explicit "no offline fallback" messaging). Result view: summary text, optional warning notes, itinerary picks grouped by day, each a card linking to `/experience/:id`. A clarifying-question branch can appear before the final plan ("Yes, show me that" / "No, let me try again").

---

## 14. Become a Host (traveler-facing application, `/host`, `/host/step-1..4`)

- **Landing** (`/host`): hero pitch, 4 benefit tiles, 4-step "How it works", testimonial card, CTA (adapts to application status).
- **Step 1/4 — Basic Details**: `ProgressSteps` (Basic Info/Experience/ID Verify/Bank Details). Host name, mobile, Nepal district dropdown, bio.
- **Step 2/4 — Experience Details**: title, category dropdown, duration + max guests counters, price/guest (live NPR preview), description.
- **Step 3/4 — Identity Verification**: government ID type dropdown, ID number, photo upload tile (empty→uploading→uploaded states).
- **Step 4/4 — Bank Payout**: bank dropdown (7 Nepal banks/wallets), account holder, account number, branch. Submit.
- **Submitted** (`/host/submitted`): vertical status timeline (Submitted → Under Review → Verification → Approved), application detail rows, "Back to Profile"/"Back to Home".

---

## 15. Host management dashboard (`/host/dashboard` and below)

Own 5-tab bottom nav shell (`HostModeScaffold`): **Dashboard · Experiences · Bookings · Messages · Profile**.

- **Dashboard**: greeting header + bell; 2×2 stat grid (Active Experiences, Upcoming Guests, Pending Requests, Upcoming Earnings); "Needs Attention" request card; "Upcoming Experience" card with occupancy bar; Quick Actions (Create Experience / Manage Bookings).
- **Experiences list**: status filter chips (All/Active/Draft/Pending/Paused), FAB "Create", listing cards.
- **Experience detail (manage)**: hero card + action list (Preview, Edit, Manage dates, View occupancy, Related bookings, Message guests, Pause/Resume).
- **Create Experience wizard**: 10 steps — Basic Info, Photos (picker + 3 stock presets), Trip Details, Itinerary (list editor), What's Included, What to Bring, Dates & Availability, Pricing, Meeting Point — with a progress bar and step counter; ends in a full read-only Preview screen, then Submitted confirmation.
- **Bookings list**: status filter chips (All/Requests/Confirmed/Completed/Cancelled), optional experience-scoped filter banner.
- **Booking detail**: traveler card, detail rows, Accept/Decline (requested) or Message/View-departure (confirmed).
- **Messages list**: searchable conversation list, unread badges, group vs 1:1 icon.
- **Conversation**: same chat-bubble pattern as traveler Trip Chat, plus attachments and moderation actions.
- **Host Profile**: settings list (Public Profile, Edit, Verification, Earnings, Reviews, History, Notifications, Help, Guidelines, Terms) + "Switch to traveler mode" + Logout.
- **Departure Detail / Guest List / Traveler Detail**: occupancy summary, participant roster, individual traveler contact/emergency info.

**Note for web planning:** several host actions are explicitly local-only/mocked in the current app (pause/resume, accept/decline, edit host profile, update availability all say "temporary frontend state" in their own UI copy) — the website's host dashboard should treat these as real backend-backed actions rather than copying the mock, since `bookings.status` transitions are service-role-only per the DB schema.

---

## 16. Cross-cutting patterns to carry into the website

1. **3-state data pattern everywhere**: loading skeleton → error (icon + message + Retry) → empty (icon + title + description + optional CTA) → data. Apply uniformly to every list/detail page.
2. **Sticky bottom action bar** on any screen with a single primary commit action (experience detail, booking form) — price on the left, CTA on the right.
3. **Card-based lists**, never bare rows — consistent rounded-white-bordered card is the base unit for listings, settings rows, and dashboard tiles alike.
4. **Pill chips** for every filter/sort/tag control, not dropdowns, except where a field genuinely needs free text or a date.
5. **Guest-gating**: any save/booking/host action redirects an unauthenticated user to an auth prompt with a *dynamic reason string* ("to save this" / "to complete: Host Application") rather than a generic login wall — worth doing on web too.
6. **Two-tier host experience**: a marketing/application flow for prospective hosts, completely separate from the operational host dashboard — mirror this split as two different site sections/subdomains-in-spirit on web (e.g. `/become-a-host` vs `/host/*` app shell).
7. **Serif display type + sans body** is the one deliberate typographic contrast in an otherwise flat, icon-forward design language — a website should keep this same pairing for continuity.
