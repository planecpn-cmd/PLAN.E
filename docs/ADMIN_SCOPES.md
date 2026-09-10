# Admin scopes — what each one lets a staff member do

Every person with access to the admin panel has a **staff record** with a
**status** (`active` or `suspended`) and a set of **scopes**. Scopes are the
permission switches. A staff member sees a menu item and can use the matching
tools only if they hold that scope; everything else is invisible and refused.

**Founders hold all nine scopes.** A **moderator** holds only the scopes a
founder grants them — usually two or three. Suspending a staff member's status
removes all access at once, regardless of scopes.

There is no "super-admin toggle" separate from this list. If a staff member can
do something in the panel, it is because of one of these nine scopes (plus, for
a couple of legacy config tools, a separate `role = admin` flag that only
founders have).

---

## The nine scopes

### Host onboarding

| Scope | Can see | Can change |
|---|---|---|
| **`hosts:review`** | The queue of people applying to become hosts, each application's answers, and their uploaded ID / business / safety documents. | Nothing directly. Can write a **recommendation** ("recommend approve / reject / ask for changes") for a colleague with `hosts:decide` to act on. |
| **`hosts:decide`** | (Also sees the queue.) | **Approves or rejects a host application.** Approve turns the person into a live host who can create listings; reject turns them down. |

Two-person rule: a `hosts:review` moderator triages and recommends; a
`hosts:decide` colleague makes the call. A founder holds both and can do it
alone.

### Listings (experiences)

| Scope | Can see | Can change |
|---|---|---|
| **`content:manage`** | The queue of listings hosts have submitted for review, each listing's full content, its photos, and its departure/itinerary. Also: app configuration and feature flags. | **Feature flags** (on/off). For a listing: write a **recommendation**, and set the listing's category / region / difficulty as a suggestion. Cannot publish a listing. |
| **`content:decide`** | (Same as above.) | **Approves a listing** — it goes live in the traveller app, its photos become public, and its category/region/difficulty are locked in. Or sends it back to the host to fix (with a required reason). |

Same two-person split as host onboarding: `content:manage` recommends,
`content:decide` publishes.

### Bookings and money — *screens land in P3; the scopes exist so they can be granted ahead of time*

| Scope | Can see | Can change |
|---|---|---|
| **`bookings:read`** | Every booking: who booked, how many people, dates, the experience, contact details, payment state, and the legal terms they accepted. | Nothing (read-only). |
| **`payments:read`** | Every payment record and its status (initiated / paid / failed). | Nothing (read-only). |
| **`payments:act`** | (Also sees payments.) | **Acts on a payment** — issue a refund, resolve a stuck payment. *(Reserved — the tools are P3.)* |
| **`finance:read`** | Settlement, payout, and invoice/tax data. | Nothing (read-only). *(Reserved — the data is P4/P5.)* |

### Staff

| Scope | Can see | Can change |
|---|---|---|
| **`staff:manage`** | Every other staff member's record and their scopes. | **Add, suspend, and re-scope staff members.** *(The screen is P3; today only the founder bootstrap and manual SQL create staff records.)* |

Without `staff:manage`, a staff member can see only **their own** staff record —
enough to sign in, nothing more.

---

## Founder vs moderator — at a glance

| Action | Founder | Moderator with `hosts:review` + `content:manage` | Moderator with `content:decide` too |
|---|---|---|---|
| See host applications & documents | ✅ | ✅ | ✅ |
| Recommend on a host application | ✅ | ✅ | ✅ |
| **Approve / reject a host application** | ✅ | ❌ (needs `hosts:decide`) | ❌ |
| See the listing review queue | ✅ | ✅ | ✅ |
| Recommend on a listing / suggest its taxonomy | ✅ | ✅ | ✅ |
| **Publish a listing / send it back** | ✅ | ❌ | ✅ |
| Toggle feature flags, edit config | ✅ | ✅ | ✅ |
| See all bookings & contact details | ✅ | ❌ (needs `bookings:read`) | ❌ |
| See all payments | ✅ | ❌ (needs `payments:read`) | ❌ |
| **Refund / resolve a payment** | ✅ *(when P3 ships)* | ❌ | ❌ |
| See / manage other staff | ✅ | ❌ (needs `staff:manage`) | ❌ |
| See finance / settlement data | ✅ *(when it ships)* | ❌ | ❌ |

Rule of thumb for granting: give a moderator the **read** scope for the area
they work in, plus **`hosts:review`** or **`content:manage`** if they triage.
Hold back the **decide/act** scopes (`hosts:decide`, `content:decide`,
`payments:act`, `staff:manage`) for people you trust to make the final call
alone.

---

## Where this is enforced

- The **menu** hides links a staff member has no scope for.
- Every **page** re-checks the scope on load and redirects away if it is missing.
- Every **action** (the API behind a button) re-checks the scope a third time and
  writes an audit-log row naming who did what.
- The **database** itself only shows a staff member the rows their scopes allow,
  even if they bypass the panel.

All four layers check the same nine scopes. Changing what a staff member can do
is always: change their scopes.

*Source of truth: the `staff_members_scopes_known` CHECK in
`supabase/migrations/20260908120000_*` / `20260910120000_*`, and
`admin/src/lib/scopes.ts`.*
