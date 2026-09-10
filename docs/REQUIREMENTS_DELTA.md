# Requirements delta

**Source:** client doc `HOST_AND_SUPER_ADMIN_DOCS_REQUIREMENT.docx` (held outside
this repo).

Nothing already built is invalidated. What changes: two open questions get
answered, one item **contradicts shipped code**, and eight items are new
(`N1`–`N8`).

---

## Contradictions with shipped code

### C1 — Commission: wrong rate *and* wrong direction

Client doc: *"PLAN E COMMISSION 10–15% / YOU GET ———"* — a **host-side
deduction**. Shipped code: `create-booking-intent` adds **5% on top** to the
traveller.

Consequences:

- Rate moves to `app_config`, **per-category or per-host** (10–15% is a range).
- **Gross booking value** and **Plan E revenue** become different numbers.
- **Payouts become mandatory**, not out-of-v1 — Plan E holds host money by
  design. The client host dashboard confirms it: *"PENDING SETTLEMENT / PAID
  AMOUNT / NOT PAYABLE"*.
- `create-booking-intent` is **Rule-4 frozen** — this needs its own decision and
  node, not an in-place edit.

### C2 — Identity + bank details are **required**

Doc items 7 (identity) and 10 (bank). `submit-host-application` validates then
**discards** both. Encrypted storage of these is now a **prerequisite for
settlement**, not an open question.

### C3 — "Superadmin can change anything / access to everything"

- **Read access:** satisfied — founders hold all nine scopes.
- **Write access:** deliberately **not** blanket. Every mutation is a **named
  action with a mandatory reason, written to `admin_audit_log`** — never a
  free-form row edit. If something can only be done today by hand-editing a row,
  that is a **missing named action** — add the action, do not add blanket write.

---

## Questions this answers

- **Q1 — Principal vs agent:** evidence points hard at **principal**. Screen 4
  makes business registration optional (*"Do you have a registered business? No —
  no problem, you can continue"*), so many hosts have no PAN. An agency model
  needs the **host's** PAN on the customer invoice — impossible for unregistered
  hosts. Still needs the accountant's written answer before P4.
- **Q2 — Refunds:** confirmed **required** (appears in both the host dashboard
  and the super-admin doc).

---

## New work

| # | Item | Status / size |
|---|---|---|
| **N1** | Experience approval queue | **DONE** (built) |
| **N2** | Host dashboard | Mostly **exists**. The audit showed the money rows blocked on N3; the rest is UI wiring over existing data. Smaller than first estimated. |
| **N3** | Settlement / payout ledger — *pending settlement, paid amount, not payable* | Blocked on **C1** and **C2**. Large, financially load-bearing. |
| **N4** | Complaints + enquiries — *"pending enquiries – host and users", "view complaints", "report customer"* | No tables exist. Medium. |
| **N5** | User management — suspend / reactivate / block; per-user total spending; booking count; country (not collected anywhere today) | **Folds into P3.** |
| **N6** | Overview dashboard + revenue charts (daily / weekly / monthly / yearly; today's activity counters) | **DEFER** — every revenue counter must be rewritten once C1's commission direction flips. Build after N3. |
| **N7** | Availability model — closed dates, blocked dates, minimum advance booking, "available anytime" | Partly the multi-departure limitation already logged in `H1_HOST_WRITE_PATH.md`. **"Available anytime" is a different booking model** (on-request), not a calendar field. |
| **N8** | Host profile fields — logo separate from profile photo, Instagram, years of experience, tourism/activity licence, meet-up point, what to bring, per-service cancellation policy | Partly in `application_data` JSON, unmodelled. |

---

## Open questions for founders

1. **Commission:** actual rate; what determines position in 10–15%; deducted
   from the host or added to the traveller?
2. **Settlement cadence:** on completion, weekly, on request? What makes an
   amount *"not payable"*?
3. **Hosts without business registration:** same payout path? Tax withheld at
   source?
4. **Experience approval:** every listing, or only a host's first?
5. **Complaints:** handled by moderators or founders? What states?
6. **"Available anytime":** instant booking with no fixed date, or
   host-confirmed request? Different products.
7. **"Block" vs "suspend":** do they differ? Does either affect confirmed
   bookings?

---

## P3 scope decisions (from this delta)

- `payments:act` is **in scope now** — wire it. Re-verify a stuck payment is
  P3's highest-value control.
- `finance:read` stays **reserved** (P4).
- **N5 folds into P3:** suspend / reactivate / block for **travellers as well as
  hosts**. Founder question 7 (does "block" differ from "suspend"?) is
  unanswered and not decidable from the code — implemented as **one action
  (`suspend` / `reactivate`)**, flagged.
- Per-user **total spending** and **booking count** are derived reads.
  **Country is not collected anywhere** — rendered absent, not invented.
- **C3 governs every P3 mutation:** named action + mandatory reason →
  `admin_audit_log`. No free-form row editing anywhere in the ops console.
- **Refund HALT stands:** build the `refunds` table, state machine, audit path,
  and UI; the Khalti/eSewa refund call is **stubbed behind a feature flag
  defaulting off**. No live refund call.
