# PLAN E — Leftover Features & Backlog

Version 1.0 · Everything NOT in the Stage A skeleton, with the condition that unlocks it.

Rule: nothing here gets built early because it looks easy. Each item has a **Trigger** — the thing
that must be true before it is worth the code. If the trigger has not happened, the item stays here.

Priority key: **P0** = required before public launch · **P1** = required before scale ·
**P2** = nice, later · **P3** = probably never, written down so it stops being re-proposed.

---

## 1. Deferred from Stage A (walled off, UI already built)

These have screens in the skeleton but no working logic. They are the first things Stage B turns on.

| # | Feature | Screen | Stage | Priority | Trigger |
|---|---|---|---|---|---|
| 1.1 | Payment via Khalti | RM-09 | 7 | P0 | Khalti merchant account + sandbox keys exist |
| 1.2 | Payment via eSewa | RM-09 | 7 | P0 | Khalti live and stable first |
| 1.3 | Real booking creation (server quote) | PL-10 | 7 | P0 | Phase 7 starts |
| 1.4 | Booking confirmation record | PL-11 | 7 | P0 | 1.3 done |
| 1.5 | Trip chat (Realtime) | RM-11 | 8 | P0 | at least one confirmed booking exists |
| 1.6 | Gear checklist writes | RM-12 | 8 | P1 | 1.3 done (seeds from `bring_list`) |
| 1.7 | Budget tracker writes | RM-13 | 8 | P1 | 1.3 done |
| 1.8 | Leave a review | RM-14/15 | 9 | P0 | a booking can reach `completed` |
| 1.9 | Host application submit | PL-19/20 | 10 | P1 | a human is available to review applications |
| 1.10 | Map tiles + markers | RM-08 | 6 | P1 | Google Maps API key with billing |
| 1.11 | Push notifications | — | 11 | P1 | bookings exist to notify about |
| 1.12 | Nepali (ne) translation | all | 11 | P0 | strings are stable, i.e. after Stage B |

---

## 2. Known gaps in the source documents

Open questions that must be answered by a human, not guessed. Mirror these into
`docs/OPEN_QUESTIONS.md` as the agent hits them.

| # | Question | Blocks | Current default |
|---|---|---|---|
| 2.1 | Khalti or eSewa merchant account — which exists today? | Phase 7 | assume Khalti sandbox |
| 2.2 | Is Saved a bottom-nav destination or Profile-only? (App Flow §6.2 conflict) | S4.3 | Profile-only, per the final screens |
| 2.3 | Where does the Home points chip navigate? | S4.2 | non-interactive display |
| 2.4 | Host application steps 1, 3, 4 content — never wireframed | S4.6 | step 1 = personal/contact, step 3 = pricing & availability, step 4 = review & submit; all marked ASSUMPTION |
| 2.5 | Cancellation and refund policy text | Phase 7 | no self-serve cancellation in v1 |
| 2.6 | Host payout mechanism after approval | out of v1 | manual, off-app |
| 2.7 | Are experiences authored in Nepali too, or is only the UI bilingual? | Phase 11 | UI bilingual, content English |
| 2.8 | Are guest interests merged into a new account? | S4.1 | offer a one-time merge on sign-up |
| 2.9 | Which of the three Home app-bar variants is final? | S4.2 | location + notifications + points |

---

## 3. Features named in the docs but out of v1 scope

| # | Feature | Priority | Trigger |
|---|---|---|---|
| 3.1 | Admin dashboard (approve hosts, moderate experiences, review payments) | P1 | more than ~10 host applications per week; until then use the Supabase dashboard |
| 3.2 | Host operations console (manage listings, departures, participants after approval) | P1 | first host is approved |
| 3.3 | Automated refunds | P1 | more than ~5 refund requests per month |
| 3.4 | Self-serve booking cancellation | P1 | refund policy is written |
| 3.5 | Payment methods management (save a wallet, default method) | P2 | Khalti supports tokenised repeat payments |
| 3.6 | My Reviews editing / deletion | P2 | users ask |
| 3.7 | Draft bookings resume across devices | P2 | drafts are actually used |
| 3.8 | Notification preferences (per-type toggles) | P2 | users complain about volume |

---

## 4. Product features not yet in any document

Candidate v2 work. None of this is designed, none of it is approved.

| # | Feature | Value | Cost | Priority |
|---|---|---|---|---|
| 4.1 | Group booking / invite friends to a trip | high for trekking, which is social | medium | P1 |
| 4.2 | Wishlist sharing / public collections | organic growth | low | P2 |
| 4.3 | Guide and organizer profiles with their own experience list | trust, big lever in adventure travel | medium | P1 |
| 4.4 | In-app permits helper (TIMS / ACAP / Sagarmatha NP guidance) | genuinely Nepal-specific, no competitor does it well | medium | P1 |
| 4.5 | Offline trail info pack (download an itinerary before losing signal) | real problem above 3000 m | high | P1 |
| 4.6 | Altitude/acclimatisation warnings on high-altitude treks | safety, differentiator | low | P1 |
| 4.7 | Weather and best-season indicator per experience | decision support | low | P2 |
| 4.8 | Points / loyalty programme (the chip already exists in the UI) | retention | medium | P2 |
| 4.9 | Referral codes | acquisition | low | P2 |
| 4.10 | Multi-day itinerary builder (combine several experiences into one trip) | high-intent travellers | high | P2 |
| 4.11 | Insurance add-on partner integration | revenue | medium | P2 |
| 4.12 | Porter / guide hiring as a standalone service | revenue, real Nepal market | high | P2 |
| 4.13 | Photo gallery contributed by past travellers | social proof | medium | P2 |
| 4.14 | Emergency contact / SOS with meeting-point coordinates | safety | medium | P1 |
| 4.15 | Price alerts and low-availability nudges | conversion | low | P3 |
| 4.16 | AI trip recommender chat | flashy | high | P3 |

---

## 5. Technical debt accepted in the skeleton

Each of these is a deliberate corner cut. Each has a named ceiling and an upgrade path. They are
not bugs; do not "fix" them early, and do not let them be forgotten.

| # | Shortcut | Ceiling | Upgrade path |
|---|---|---|---|
| 5.1 | Client-side price display on PL-10 | wrong the moment prices change server-side | Phase 7 server quote replaces it — code is marked `// TEMP:` |
| 5.2 | Client-side search query | relevance ranking is weak | Phase 5 `search-experiences` Edge Function |
| 5.3 | No PostGIS — bounding-box filter only | fine to a few thousand pins | add PostGIS when radius search or clustering is needed |
| 5.4 | Availability per departure date, not per seat | ~1000 bookings/day | per-seat inventory table |
| 5.5 | Postgres `tsvector` search | no typo tolerance, no synonyms | dedicated search service only if users complain |
| 5.6 | No offline write sync | reads cache, writes fail loudly | outbox pattern, already used for chat in Phase 8 |
| 5.7 | Manual host review in the Supabase dashboard | breaks past ~10/week | 3.1 admin dashboard |
| 5.8 | Images served from Supabase Storage without a CDN | slow on Nepali 3G at scale | put a CDN in front, generate 3 sizes |
| 5.9 | No rate limiting beyond Supabase defaults | abuse risk on auth and payment endpoints | Edge Function rate limiter before public launch — **P0** |
| 5.10 | Manual `completed` flip in Phase 9 cron | timezone edge cases at Kathmandu midnight | verify with the tz library, test around 00:00 +05:45 |

---

## 6. Explicitly rejected

Written down so nobody re-proposes them.

| Feature | Why not |
|---|---|
| Web or tablet version | App Flow is mobile-only by definition; the whole design system assumes portrait phone |
| Multi-currency | NPR only; foreign cards settle through the wallet's own conversion |
| Stripe / PayPal | cannot settle NPR domestically |
| Firebase instead of Supabase | no relational integrity for bookings and participants; RLS is the security model |
| BLoC | Riverpod covers it with far less ceremony at this size |
| Custom Dart backend | doubles the surface area for an MVP where RLS covers most rules |
| React Native / Expo | evaluated and built as a throwaway skeleton, then rejected: the maintainer debugs in Dart and Khalti/eSewa ship official Flutter SDKs. Do not reintroduce |
| In-app wallet / stored balance | financial licensing burden in Nepal, no product need |
| Social feed | not the product; PLAN E is discovery and planning |

---

## 7. Pre-launch gate

Nothing ships publicly until all of these are true:

- [ ] Payment path verified end to end with real money on a live Khalti account
- [ ] Duplicate webhook and expired quote both proven safe
- [ ] `supabase/tests/rls.test.sql` green, every table has RLS enabled and at least one policy
- [ ] `host-documents` bucket private, admin signed URL only
- [ ] Rate limiting on auth and payment endpoints (5.9)
- [ ] Nepali translation complete for every user-facing string
- [ ] WCAG AA contrast verified, 44 pt targets, dynamic type without clipping
- [ ] Privacy policy published, PII deletion path exists
- [ ] Crash-free sessions above 99% in internal testing
- [ ] `integration_test` E2E green: onboarding, book, chat, review, host apply
