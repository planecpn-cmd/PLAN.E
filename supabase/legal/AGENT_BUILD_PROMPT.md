# AGENT PROMPT — Implement Plan E Legal Documents (Flutter app + Next.js web)

Implement the 13 legal documents in `plan-e-legal/` across both Plan E clients. They
must render identically in substance, be versioned, and — where a document requires
acceptance — record that acceptance in a way that stands up months later.

**Read this whole document before writing code.** Confirm the data model in §2 with the
user before creating any table.

---

## 0. The mistake to avoid

Do not hardcode 13 markdown files into 13 screens in each client. That gives you 26
copies of text that must be edited in lockstep, and no record of which version a user
accepted.

**Build one delivery mechanism.** Documents live in one place, are versioned, are
fetched by both clients, and acceptance is recorded against a version ID.

---

## 1. Scope

| Document | Slug | App | Web | Acceptance |
|---|---|---|---|---|
| Terms of Service | `terms-of-service` | ✓ | ✓ | Sign-up |
| Privacy Policy | `privacy-policy` | ✓ | ✓ | Sign-up |
| Booking Terms | `booking-terms` | ✓ | ✓ | Checkout |
| Cancellation Policy | `cancellation-policy` | ✓ | ✓ | Checkout |
| Refund Policy | `refund-policy` | ✓ | ✓ | Reference |
| Payment Policy | `payment-policy` | ✓ | ✓ | Reference |
| Grievance Policy | `grievance-policy` | ✓ | ✓ | Reference |
| Account Deletion Policy | `account-deletion-policy` | ✓ | ✓ | Reference |
| Community Guidelines | `community-guidelines` | ✓ | ✓ | Sign-up |
| Safety and Risk Policy | `safety-and-risk-policy` | ✓ | ✓ | Reference |
| Risk Acknowledgment | `risk-acknowledgment` | ✓ | ✓ | **Per booking**, high-risk only |
| Emergency Policy | `emergency-policy` | ✓ | ✓ | Reference |
| Cookie Policy | `cookie-policy` | — | ✓ | Cookie banner |

---

## 2. Data model

Two new Supabase tables. **Confirm with the user before creating them.**

```sql
create table legal_documents (
  id            uuid primary key default gen_random_uuid(),
  slug          text not null,
  version       text not null,              -- '1.0', '1.1'
  locale        text not null default 'en', -- 'en', 'ne'
  title         text not null,
  body_md       text not null,
  effective_at  timestamptz not null,
  requires_acceptance boolean not null default false,
  is_current    boolean not null default false,
  created_at    timestamptz not null default now(),
  unique (slug, version, locale)
);

create table legal_acceptances (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete restrict,
  document_id   uuid not null references legal_documents(id),
  booking_id    uuid references bookings(id),   -- risk acknowledgment only
  accepted_at   timestamptz not null default now(),
  client        text not null,                  -- 'flutter' | 'web'
  app_version   text,
  ip_address    inet,
  unique (user_id, document_id, booking_id)
);
```

**Design notes, do not change without asking:**

- `on delete restrict` on `user_id`, not cascade. An acceptance record is evidence; it
  must survive account deletion. Account deletion anonymises the linked user row, it
  does not remove the acceptance.
- Acceptance references a **document version**, never a slug. "They accepted the Terms"
  is worthless; "they accepted Terms v1.2 at 14:03 on 12 March from the Flutter client"
  is evidence.
- `is_current` is enforced by a partial unique index so only one version per
  slug+locale can be current.

### RLS

- `legal_documents`: **anonymous SELECT** on `is_current = true`. Legal documents must
  be readable before sign-up and indexable by search engines. Older versions readable by
  the users who accepted them.
- `legal_acceptances`: a user may INSERT and SELECT **their own rows only**. No UPDATE,
  no DELETE by anyone but service role. An acceptance record must not be editable.

---

## 3. Seeding

Load the 13 markdown files as version `1.0`, locale `en`, `is_current = true`.

**Strip the frontmatter block from each file** (the title, "Effective:", "Operated by"
lines) into the table columns rather than leaving them in `body_md` — the clients render
that header from structured fields.

Set `requires_acceptance = true` for: `terms-of-service`, `privacy-policy`,
`booking-terms`, `cancellation-policy`, `community-guidelines`, `risk-acknowledgment`.

**Do not seed with placeholders unfilled.** `[SUPPORT EMAIL]`, `[REGISTERED ADDRESS]`
and the rest must be replaced with real values first. Publishing a legal document
containing `[COMPANY REG NO]` is worse than not publishing it. If the user has not
supplied them, stop and ask — do not invent values.

---

## 4. Flutter app

### Routes

```
/legal                      index — list all documents
/legal/:slug                document viewer
```

Reached from: Profile → Settings → Legal & Info (replacing the current Terms/Privacy
stubs), and from contextual links at sign-up and checkout.

### Viewer screen

- Standard `AppBar` with the document title
- `flutter_markdown` rendering, styled with the app's own `tokens.dart` — serif headings,
  sans body, `ink` text, `gold` for links and table header rules. **Do not use the
  package's default styling**
- Tables must render. Several documents rely on them
- "Last updated" and version number at the top, muted
- Long documents get a jump-to-section list built from the H2 headings
- Wrapped in `AsyncValueView`, so loading, error and empty states come free
- **Cache locally** on fetch. These must be readable offline — a traveller on a trek
  with no signal needs the Emergency Policy more than anyone

### Acceptance UI

**At sign-up**, below the form, above the submit button:

> By creating an account you agree to our **Terms of Service**, **Privacy Policy** and
> **Community Guidelines**.

Bold parts are tappable and open the viewer. One combined statement, not three
checkboxes — but record **three separate acceptance rows**, one per document version.

**At checkout**, above "Proceed to Pay":

> By booking you accept the **Booking Terms** and the **Cancellation Policy** for this
> experience.

**Risk Acknowledgment** — a full screen, not a checkbox, inserted in the booking flow
between the form and the payment sheet, for experiences with difficulty Moderate,
Challenging or Strenuous, or in the climbing / rafting / paragliding / canyoning
categories, or above 3,000 m.

- Full text rendered, scrollable
- The three confirmation checkboxes from the document, each ticked individually
- Continue button disabled until all three are ticked
- **The user must scroll to the bottom before the checkboxes enable.** This is one of
  the few places where a scroll gate is justified — it is the difference between a
  record that means something and one that does not
- On continue: write `legal_acceptances` with `booking_id`, then proceed to payment

### Version changes

On app launch, compare the current version of each `requires_acceptance` document
against the user's latest acceptance. If a newer version exists, show a non-dismissible
sheet summarising what changed with a link to the full text and a single Accept action.

Per the Terms, material changes take effect **14 days** after notification — so do not
block usage before the effective date. Show an informational banner during the notice
period, and the blocking sheet only after.

---

## 5. Next.js web

### Routes

```
/legal                      index
/legal/[slug]               document page
```

### Rendering

- **Server-rendered.** These pages must be indexable — search engines and app store
  reviewers both fetch them, and app stores reject store listings whose privacy policy
  URL does not resolve to real content
- `remark`/`rehype` to HTML, styled with the same design tokens
- Sticky table-of-contents sidebar at `lg`, built from H2s; inline collapsible at `base`
- Max content width ~720px for readability — this is the one place a narrow column is
  correct, because it is body text
- Per-page `<title>`, meta description, and canonical URL
- Print stylesheet. People print these

### Public URLs

App stores require a publicly reachable privacy policy URL that works **without login**.
Confirm `/legal/privacy-policy` returns full content to an anonymous request:

```
curl -s https://[DOMAIN]/legal/privacy-policy | grep -i "Individual Privacy Act"
```

Empty result means the page is client-rendered and the RLS or SSR setup is wrong.

### Acceptance UI

Same copy and same rules as the app. The Risk Acknowledgment is a **step in the booking
flow**, not a modal — modals get dismissed and produce weak records.

### Cookie banner

Web only, from `cookie-policy`.

- Appears on first visit, before any non-essential cookie is set
- Three actions: **Accept all**, **Reject all**, **Manage preferences**
- **"Reject all" is exactly as prominent as "Accept all"** — same size, same weight, same
  position. A greyed-out or hidden reject button is a compliance failure
- Preferences: Strictly necessary (locked on), Functional, Analytics
- No analytics script loads until consent is given
- Honour `navigator.doNotTrack`
- Choice stored 12 months; "Cookie settings" link permanently in the footer

---

## 6. Cross-client consistency

Both clients read the **same rows**. Never hardcode legal text in either codebase.

Verify: open `/legal/cancellation-policy` on web and the same screen in the app. Same
version number, same effective date, same text. Any divergence means a client has a
hardcoded copy — find and remove it.

---

## 7. Contextual links

Legal text is useless where nobody sees it. Link from the moment of relevance:

| Where | Link to |
|---|---|
| Experience page, near price | Cancellation Policy (host-specific terms if any) |
| Checkout price breakdown | Payment Policy — on the service fee line |
| Booking confirmation | Cancellation Policy, Refund Policy |
| Plans → cancel action | Cancellation Policy, before confirming |
| Profile → Help & Support | Grievance Policy |
| Settings → Delete Account | Account deletion Policy, before confirming |
| Experience page, high-risk | Safety and Risk Policy |
| Trip chat, itinerary screens | Emergency Policy — and surface the emergency numbers directly, not behind a link |
| Review submission | Community Guidelines |
| Website footer | All of them |

**Emergency numbers get special treatment.** Put them somewhere reachable in two taps
from any screen during an active booking, and cache them offline. A phone number behind
a network request is a phone number you cannot call when you need it.

---

## 8. Accessibility and localisation

- Real semantic headings, correct hierarchy, no skipped levels
- Tables use `<th>` with scope, and remain readable on a 375px viewport
- Body text minimum 16px, line-height at least 1.6
- Full keyboard navigation and visible focus on web
- Screen-reader tested on the acceptance flows specifically

**Nepali translation:** the schema supports it via `locale`, but do not machine-translate
legal text. Leave `ne` unseeded until a human translation is commissioned. A bad
translation of a liability clause is a liability.

---

## 9. Testing

- [ ] All 13 render correctly in both clients, tables intact
- [ ] `/legal/privacy-policy` returns full content to an anonymous `curl`
- [ ] Sign-up writes three acceptance rows with correct `document_id`s
- [ ] Checkout writes booking-terms and cancellation-policy acceptances
- [ ] Risk Acknowledgment appears only for qualifying experiences
- [ ] Risk Acknowledgment cannot be completed without scrolling and ticking all three
- [ ] Acceptance rows reference version IDs, not slugs
- [ ] A user cannot update or delete their own acceptance rows
- [ ] Account deletion does not delete acceptance rows
- [ ] Documents readable offline in the app after first load
- [ ] Cookie banner blocks analytics until consent; reject is equally prominent
- [ ] Publishing a new version triggers re-acceptance after the 14-day notice period
- [ ] No hardcoded legal text remains in either codebase

---

## 10. Stop and ask

- Placeholders are unfilled — **never invent a company registration number, address,
  phone number or officer name**
- The user has not confirmed the two new tables
- A document's stated timeline conflicts with what the system can actually do (e.g. the
  Refund Policy promises initiation within 7 working days — confirm operations can meet
  it, because a published timeline you miss is a consumer protection breach)
- The Payment Policy's host payout timing is still `[PAYOUT TIMING — CONFIRM]`
- Anything requires a schema change beyond the two tables above
