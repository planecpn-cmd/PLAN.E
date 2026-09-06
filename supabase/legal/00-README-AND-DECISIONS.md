# PLAN E — Legal Document Set

Drafts for review by a Nepal-licensed advocate before publication. Not legal advice.

**Prepared for:** Plan E, operated by Code Peak Nepal Pvt. Ltd.
**Jurisdiction assumed:** Federal Democratic Republic of Nepal
**Currency:** NPR
**Last drafted:** [DATE]

---

## Documents in this set

| # | File | Purpose |
|---|---|---|
| 01 | `terms-of-service.md` | Master user agreement — governs everything |
| 02 | `privacy-policy.md` | Data collection, use, sharing, rights |
| 03 | `booking-terms.md` | The booking contract itself |
| 04 | `cancellation-policy.md` | Who can cancel, when, and what happens |
| 05 | `refund-policy.md` | How money comes back |
| 06 | `payment-policy.md` | Gateways, fees, currency, host payouts |
| 07 | `grievance-policy.md` | Complaint intake, escalation, timelines |
| 08 | `account-deletion-policy.md` | Deletion request and what is retained |
| 09 | `community-guidelines.md` | Conduct for travellers and hosts |
| 10 | `safety-and-risk-policy.md` | Plan E's and hosts' safety obligations |
| 11 | `assumption-of-risk.md` | Traveller risk acknowledgment |
| 12 | `emergency-policy.md` | Incident response, SAR, evacuation |
| 13 | `cookie-policy.md` | Web only |
| — | `AGENT_BUILD_PROMPT.md` | Instructions for implementing these in app + web |

---

## Structural decisions baked into these drafts

**Change these consistently across all documents if your lawyer disagrees.**

### 1. Plan E is an intermediary, not the service provider

The host is the party contracting to deliver the experience. Plan E operates the
booking platform and collects payment as the host's limited collection agent.

**Why this matters:** it determines who is liable when an experience goes wrong. It is
the single most important decision in this set.

**The counter-argument your lawyer must address:** Nepal's Consumer Protection Act 2075
protects the consumer's relationship with whoever they transacted with. Because Plan E
takes the payment, sets the cancellation rules, vets hosts and presents the listing, a
court or the Department of Commerce may treat Plan E as jointly liable regardless of
the intermediary label. **Do not assume the label protects you.** Consider whether you
want intermediary framing with voluntary remediation, or to accept principal liability
and price it in.

### 2. Liability is not excluded, it is disclosed and bounded

These drafts do **not** contain a blanket negligence waiver. Terms excluding liability
for a business's own negligence are vulnerable under the Consumer Protection Act 2075
and are unlikely to be enforceable in Nepal. Instead: honest disclosure of inherent
risks, clear allocation between host and platform, and a monetary cap where lawful.

### 3. Statutes referenced (verify current versions)

- Consumer Protection Act, 2075 (2018) and Rules 2076
- Electronic Transaction Act, 2063 (2008)
- Individual Privacy Act, 2075 (2018)
- Tourism Act, 2035 (1978) and Trekking/Rafting regulations
- Companies Act, 2063 (2006)
- Nepal Rastra Bank Payment Systems Oversight Framework
- Foreign Exchange (Regulation) Act, 2019 — if you ever accept foreign currency

### 4. Placeholders to fill before publication

`[REGISTERED ADDRESS]` `[COMPANY REG NO]` `[PAN/VAT NO]` `[SUPPORT EMAIL]`
`[SUPPORT PHONE]` `[GRIEVANCE OFFICER NAME]` `[GRIEVANCE EMAIL]` `[EMERGENCY HOTLINE]`
`[DPO EMAIL]` `[EFFECTIVE DATE]` `[INSURANCE POSITION]`

### 5. Open questions for the business, not the lawyer

- **Insurance.** Do you carry public liability? Do you require hosts to? Several clauses
  cannot be finalised without an answer. If the answer is "no insurance anywhere", say
  so plainly in the documents rather than staying silent — silence is worse.
- **Guest bookings.** The app has "Continue as Guest". Can a guest book? If yes, how do
  they accept terms and receive refunds without an account?
- **Foreign travellers.** Likely a large share of your users. Do the documents need an
  English/Nepali bilingual version? Consumer Protection Act rights apply regardless of
  the traveller's nationality.
- **Minors.** Experiences list a minimum age. Who consents for a minor participant?
- **Host payout timing.** Currently unspecified. It determines your refund exposure — if
  you pay the host before the experience runs, you are funding refunds from your own
  balance.

### 6. Redundancy note

Cancellation, Refund and Payment are three documents covering one commercial
transaction. Users will not read three. They are kept separate here because you asked
for them separately and because linking them individually is useful, but the app should
present them as one "Booking, Payment and Cancellation" section with three anchors.
