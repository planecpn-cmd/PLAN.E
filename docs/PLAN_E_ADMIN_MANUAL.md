# Plan E Admin — a guide for founders and staff

This guide is for the people who will actually use the admin panel: a
founder, or a staff member a founder has given access to. It does not
assume you know how to code, read a database, or write technical commands.
If a sentence here does not make sense, that is the guide's fault, not
yours — tell whoever manages the panel so it can be fixed.

Where something is not finished yet, or has not been tested by a real
person clicking through it, this guide says so plainly. It does not
describe anything that does not exist.

---

## 1. What this is

The admin panel is a private website where Plan E staff review host
applications, review listings, look up bookings and payments, and manage
user accounts. Travelers and hosts never see it and never need to know it
exists.

It is a **separate website** from planenepal.com, the public site
travelers and hosts use. It lives at a different address —
**admin.planenepal.com** — and runs on completely separate computer
systems. Nothing you do on the admin panel can accidentally show up on the
public site, and nothing on the public site can be used to reach the admin
panel. They are built, deployed, and secured independently.

## 2. Signing in

Go to **admin.planenepal.com**. You will see a sign-in box asking for an
email and password (or a "Continue with Google" button, if that has been
set up for your account).

You can only sign in if a founder has already added you as **staff** with
your email. Signing up does not work here — there is no "create an
account" option, and there should never be one. If you can sign in but see
almost nothing — no menu links, an empty dashboard — you are signed in
correctly but have not been given any permissions yet. That is normal for
a brand-new staff account before a founder assigns it any work areas.

**If you cannot sign in at all:**

- Double-check the email and password. If you forgot your password, use
  the site's password reset (if available) or ask a founder to set a new
  one for you.
- If you sign in and immediately see a page saying **"Not authorized"**,
  your account exists but is not an active staff member — or it was
  suspended. Contact a founder.
- If nothing on the page responds at all, or you see a technical error
  message instead of the sign-in box, do not try to fix it yourself.
  Screenshot it and send it to whoever manages the panel technically.

## 3. Super admin vs. moderator — what each can do

Every staff member has a set of **permissions** (also called "scopes").
A founder has every permission there is. A **moderator** has only the
permissions a founder chose to give them — usually two or three, matched
to the work they actually do.

Think of permissions as separate light switches, not one big master
switch. Giving someone "see host applications" does not also give them
"approve host applications" — those are two different switches, on
purpose, so that one person can look something over and a *different*
person makes the final call. This is deliberate, not a bug: it means one
person alone can't quietly wave something through without anyone else
being able to see it happened.

| What | Founder | A moderator with only the matching permission |
|---|---|---|
| See host applications and their documents | ✅ | ✅ (needs "review host applications") |
| **Approve or reject** a host application | ✅ | ❌ needs a *separate* "decide host applications" permission |
| See the listing review queue, config, feature flags | ✅ | ✅ (needs "manage listings") |
| **Approve or send back** a listing | ✅ | ❌ needs a *separate* "decide listings" permission |
| See all bookings and their details | ✅ | ✅ (needs "read bookings") |
| See all payments and the stuck-payment list | ✅ | ✅ (needs "read payments") |
| **Cancel a booking, re-verify a payment, create a refund** | ✅ | ❌ needs a *separate* "act on payments" permission |
| See and search all users, their booking history, their spend | ✅ | ✅ (needs "manage users") — this permission also grants the next row |
| **Suspend or reactivate a user account** | ✅ | ❌ needs "manage users" (same permission as the row above) |
| Add or manage other staff | ✅ | ❌ founder only |

A founder decides who gets which permissions, and can give or take them
away at any time from the Staff area. If you think you should have access
to something you do not, ask a founder — don't try to work around it.

**One current wrinkle worth knowing:** if a moderator is given *only* the
"decide" side of host applications or listings (or only "act on
payments"), without the matching "review"/"manage"/"read" permission, they
can technically make the final call through the system, but they will not
be able to open the screen to actually do it — the page will tell them
they're not authorized. In practice, always give the pair together (e.g.
both "review host applications" **and** "decide host applications") so the
person can actually use the panel. This has been flagged to the technical
team to fix or document more clearly; for now, granting the pair together
avoids the problem entirely.

## 4. The screens, one by one

Every screen only appears in your menu if you have the matching
permission. If you don't see a screen listed here in your own menu, you
don't have access to it — that's expected, not an error.

### Config & feature flags

Shows a short list of on/off switches for parts of the app (for example,
whether AI-generated itineraries are turned on, or whether a particular
payment provider is available). Each switch shows whether it's on, and a
plain description of what it controls.

**Action:** click "Turn on" / "Turn off" next to a switch. You'll be asked
for a short reason before it takes effect — you cannot flip a switch
without explaining why.

**What happens after:** the switch changes immediately, and the change
is permanently logged with your name, the time, and your reason. Nothing
else happens automatically — flipping a switch does not send any message
to anyone.

*This screen renders correctly and every flag shows the right state, but
flipping a switch has not yet been confirmed all the way through by a real
person — see §13.*

### Host applications

Shows everyone who has applied to become a host, and where each
application currently stands (submitted, under review, approved,
rejected). Opening one shows everything the applicant wrote, and their
uploaded documents.

**Action:** if you have the right permission, you can approve, reject, or
ask for changes, always with a note. See §5 below for the full walk-through.

**What happens after:** approving turns the applicant into a real host who
can start creating listings. Rejecting or asking for changes does not
(yet) send the applicant anything — see §10, "notifications don't send
yet."

### Experiences (listings)

Shows listings hosts have submitted for review — by default, only the
ones waiting for a decision. You can switch the filter to see published,
draft, paused, or archived listings too. Opening one shows everything the
host entered, its photos, and its trip dates.

**Action:** approve it, or send it back to the host with a reason. See §6
below.

**What happens after:** approving makes the listing visible to travelers
immediately, with its photos public. Sending it back returns it to the
host as a draft they can edit and resubmit — the reason you give is what
they'll see is wrong.

### Bookings

Shows every booking made on the platform — who booked, when, how many
people, how much, and its current status. You can filter by status.
Opening one shows the full detail: the trip dates, the payment record, and
a timeline of what's happened to that booking.

**Action:** if you have the right permission, you can cancel a booking,
with a required reason. See §7 below.

*This screen has been checked end to end, including who can see it and
who can't. The list and detail views were confirmed working with real
data. Cancelling a booking itself still needs one real person to click it
once — see §7 and §13.*

### Payments

Shows every payment — its status, and a comparison of "what we think
happened" versus "what the payment provider (Khalti or eSewa) says
happened." Has a separate view for payments that have been stuck for more
than half an hour. See §8 for what "stuck" means and what to do about it.

**Action:** re-verify a stuck payment, or create a refund on a paid
payment.

*Confirmed working end to end, including actually creating a refund and
watching it record correctly with no money moving. See §9 for a real
caveat found while testing it.*

### Users

Shows a search box and a list of every traveler and host — their name,
phone, how many bookings they've made, and how much they've spent in
total (this is calculated automatically from real bookings, not a
separate number anyone types in). A country field is shown as "not
collected" for everyone — Plan E does not currently ask for or store
anyone's country, anywhere. That is expected, not a missing feature.

**Action:** suspend or reactivate an account, with a reason. See §9.

## 5. Reviewing a host application, start to finish

1. Open **Host applications**. New applications show up here as
   "submitted."
2. Click the application to open it. Read what the applicant wrote, and
   open each uploaded document to check it.
3. Type a short note explaining what you found.
4. Choose an action:
   - **Mark under review** — if you're still looking into it, or waiting
     on something.
   - **Approve** — the applicant becomes a live host immediately, able to
     create listings. This is permanent for that application; a founder
     would have to remove their host status separately.
   - **Reject** — turns the applicant down. Give a clear reason; it's
     what explains the decision if it's ever questioned later.
   - **Request changes** — sends it back as needing more information,
     without a final yes or no.
5. Your name, the time, your note, and the decision are recorded
   permanently, whichever you choose.

If you only have permission to review (not decide), you'll see the same
screen but only a "record a recommendation" option — a colleague with
decide permission makes the final call based on what you wrote.

## 6. Reviewing a listing (experience), start to finish

1. Open **Experiences**. It opens on listings waiting for review by
   default.
2. Click one to open it. Review the title, description, photos, price,
   and trip dates the host entered.
3. Set the listing's category, region, and difficulty — these are things
   the host cannot set themselves; a reviewer sets them so listings stay
   consistent across the app.
4. Choose:
   - **Approve** — the listing goes live immediately. Its photos become
     public, and the category/region/difficulty you set are locked in.
   - **Reject** or **Request changes** — sends it back to the host as a
     draft, with your reason. It is not visible to travelers while it's
     back with the host.
5. If a host edits a listing that's *already* live, their edit does not
   change what travelers see right away — it creates a pending update
   that waits for review the same way a new listing would, so a change
   can't accidentally go live unreviewed. If the host tries to submit a
   second edit while one is already waiting for review, they'll see a
   clear message telling them so, rather than a confusing generic error.

## 7. Finding a booking and cancelling it

1. Open **Bookings**. Use the status filter, or scroll the list, to find
   the one you need. There is currently no search-by-name box on this
   screen — you filter by status and scroll.
2. Click the booking to see its full detail: guest, dates, payment, and a
   timeline of everything that's happened to it so far.
3. If the booking can still be cancelled (it hasn't already been
   completed, or already cancelled), you'll see a **Cancel booking**
   button.
4. Click it, type a reason, and confirm. You'll be asked to confirm once
   more before it actually happens, since this can't be undone from the
   panel.

**What the customer sees:** the booking's status changes to "cancelled"
immediately, and that's what they'll see the next time they open the app.
**There is currently no automatic message sent to the traveler telling
them their booking was cancelled or why** — see §10. If you cancel a
booking, it's worth reaching out to the traveler directly (by phone, or
however Plan E normally contacts customers) so they aren't left finding
out only by chance.

Cancelling a booking does **not** automatically refund any payment on it.
If a refund is owed, that's a separate step — see §8.

## 8. The stuck-payment queue

Sometimes a traveler starts paying, but Plan E never hears back clearly
from the payment provider (Khalti or eSewa) about whether it actually
went through. A payment sitting in the "initiated" state for **more than
30 minutes** shows up in the **Payments → stuck** filter.

**When to re-verify:** if a payment has been stuck for a while, click
**Re-verify with gateway**. This asks the payment provider directly, one
more time, what actually happened. If they confirm the payment went
through, the booking is completed automatically as if the payment had
succeeded normally. If they say it didn't go through, nothing changes —
it's safe to click.

**When *not* to re-verify:** a payment that's only been "initiated" for a
few minutes is very likely still in progress — the traveler may still be
on the payment page. Re-verifying too early won't cause any harm, but it
also won't tell you anything useful yet; give it time to actually get
stuck first.

Re-verifying never charges anyone anything extra — it only *asks* what
already happened. It cannot start a new payment or move any money.

## 9. Refunds — what actually happens today

**The refund button does not yet send money.** Clicking "Create refund"
records that a refund is owed — the amount, who requested it, and why —
so there's a clear paper trail. It does **not** call Khalti or eSewa to
actually send the money back. That live connection exists in the system
but is deliberately switched off until a founder has tested it carefully
in a safe environment and turned it on.

Until then, if a refund is genuinely owed, Plan E needs to send that money
back to the customer by whatever method it normally uses outside the
panel (bank transfer, or directly through the Khalti/eSewa merchant
dashboard) — the "Create refund" button is a record-keeping step, not
a way to actually pay someone back yet.

**One thing to watch for:** the screen does not currently show you that a
refund has already been recorded for a payment — after clicking "Create
refund," the button is still sitting there as if nothing happened. Before
clicking it, check whether the payment already has a refund on record
another way (ask a founder, or whoever tracks this outside the panel) —
don't rely on the screen to remind you. This has been flagged for a fix;
in the meantime, the system won't let a refund total more than what was
actually paid, so the worst case is a confusing duplicate record, not lost
money.

## 10. Suspending a user

Open a user's row (traveler or host) on the **Users** screen and click
**Suspend**, with a reason. A suspended user cannot sign in or use the app
normally until someone reactivates them the same way, from the same
screen.

**"Suspend" and "block" are currently the same single action.** There is
no separate, harsher "block" option yet — if your situation calls for a
stronger response than a normal suspension (for example, a safety
concern), say so clearly in the reason field, since the system itself
doesn't currently distinguish the two. Suspending someone does **not**
automatically cancel their existing confirmed bookings — those stay as
they are unless you separately cancel them.

## 11. Why every action asks for a reason

Every action in this panel that changes something — approving,
rejecting, cancelling, suspending, flipping a switch — asks you to type a
short reason first, and none of them work without one. This is not
red tape for its own sake.

That reason, along with your name and the exact time, is written to a
permanent record that nobody — not even a founder — can quietly edit or
delete afterward. If a decision is ever questioned later (by a customer,
a host, or anyone else), that record is what shows *why* it was made and
*who* made it. It protects you as much as it protects Plan E: a clear,
honest reason on record is your best defense if a decision you made in
good faith is ever second-guessed.

Take the extra ten seconds to write a real reason, not a placeholder like
"ok" or a single letter. Future-you, or whoever looks at this later, will
need to actually understand it.

## 12. If something looks wrong

- **A screen shows an error message, or looks broken:** don't try to
  retype the URL, refresh repeatedly, or guess at a workaround. Take a
  screenshot and send it to whoever manages the panel technically,
  along with what you were doing right before it happened.
- **You're not sure if an action already went through:** check the
  screen again after a moment — most actions update the page immediately.
  If you're still unsure, do **not** click the button again "just in
  case." Ask, rather than risk doing something twice (for example,
  cancelling the same booking twice, or double-suspending someone).
- **You suspect a security problem** — for example, you can see or do
  something you don't think you should be able to — stop, don't explore
  further to "test" it, and report it immediately to whoever manages the
  panel technically.
- **You don't have a permission you think you need:** ask a founder.
  Don't ask anyone to share their own login with you — every action is
  tied to the person who did it, and sharing a login breaks that record.

Do **not**: edit anything directly in the database, ask a developer to
"just fix it in the database real quick," or try to use a workaround
outside this panel for anything the panel is meant to handle. If the
panel can't do something you need, that's a real gap worth reporting —
not something to route around quietly.

## 13. What is honestly not finished or not yet tested

This section exists so nobody assumes something works just because it's
on the screen. As of this guide, plainly:

- **Notifications don't send yet.** When a host application or a listing
  is approved, rejected, or sent back for changes, the system is wired up
  to notify the host — but the actual message text has not been written
  yet, so **nothing is sent**. Hosts currently find out only by checking
  the app themselves. The same is true for bookings: cancelling a booking
  does not message the traveler either (see §7). This will change once
  the message wording is finalized and turned on — nothing needs to
  change on your end when it does.
- **The Bookings and Payments screens have now been walked through with
  real test data — the list, the detail page, creating a refund, and
  attempting a re-verify all behaved exactly as described in §7, §8, and
  §9.** Everything on these two screens is confirmed, not assumed, with
  two specific exceptions — see the next bullet.
- **Two actions have never actually been clicked by a person, for the same
  technical reason: cancelling a booking, and turning a config switch on
  or off.** Both ask for confirmation with a pop-up dialog box before they
  do anything, and the automated tool used to check the rest of this panel
  is not able to click through that kind of pop-up — so these two are the
  only actions in the whole panel that remain unconfirmed end to end.
  Nothing suggests either is broken (both open correctly and ask for a
  reason exactly as designed up to that point), but neither has been
  proven to work all the way through. **These should be the first two
  things a real tester tries** — cancel a test booking, and flip a config
  switch — before trusting the rest of the panel for real use.
- **Refunds record intent only — no money moves yet** (§9) — this has now
  been directly confirmed by creating a real refund and checking the
  database: the payment stayed "paid," the refund sat as "pending," and
  no gateway was ever contacted. Don't tell a customer a refund has been
  sent because the button was clicked. **Separately: the refunds screen
  does not show you a refund that already exists for a payment**, so it is
  possible to create two refunds for the same payment without the screen
  warning you. The total is still capped at what was actually paid — the
  system won't let refunds add up to more than that — but check whether a
  payment already has a refund on record (ask a founder, or check outside
  the panel) before creating a second one.
- Re-verifying a stuck payment (§8) has been confirmed to correctly
  require the right permission, and to fail visibly (not silently) when
  the gateway connection isn't configured — but hasn't yet been exercised
  against a real payment provider outside of Plan E's own testing — if it
  behaves unexpectedly the first few times it's used for real, that's
  expected growing pain, not cause for alarm; report what happened.

If you find something else that doesn't match what this guide says,
that's more useful to know than not — please report it rather than
quietly working around it.
