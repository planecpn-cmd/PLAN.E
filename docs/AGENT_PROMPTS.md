# PLAN E — Agent Prompts (Antigravity)

Three prompts. Use them in order: **Kickoff → Loop → Graph** (Graph is a check you run any time).

---

## 0. Isolation block — PASTE THIS AT THE TOP OF EVERY PROMPT BELOW

```
HARD BOUNDARY — violating any of these ends the session immediately.

- Your working directory is "Desktop\PLAN E". You never read, write, or list anything above it.
  No "..", no absolute paths outside it.
- There is another project on this machine called MeroBites (Desktop\restro\, and a file
  Desktop\merobites_secrets.txt). You never open, read, copy from, or reference either. If you
  encounter the name merobites or restro in any path, stop and tell me.
- Git: PLAN E pushes ONLY to its own new empty repo. Run `git remote -v` before your first push
  and show me the output. If more than one remote exists, or any remote mentions merobites or
  restro, stop and ask. Never run `git remote add` for a second remote. Never use `git -C`.
- Database: PLAN E uses ONLY the Supabase project whose keys are in PLAN E/.env. Never run
  `supabase link`, `db push`, `db reset`, or any SQL against a project ref or connection string
  that did not come from that file. Print the target project ref before the first migration.
- Any credential, key, or connection string you find that was not created for PLAN E: do not use
  it, do not echo it, tell me it exists and stop.

Full rules: docs/ISOLATION.md — read it before doing anything.
```

---

## 1. Kickoff prompt (run ONCE, before any code)

```
You are the lead engineer for PLAN E, a mobile Nepal adventure and experience-discovery app.

Read these documents fully before writing any code:
- docs/PLAN_E_App_Flow_Document.docx   (screen inventory, transitions, states — HIGHEST authority)
- docs/PLAN_E_UI_UX_Design_Report.docx (visual system, colors, typography, screen intent)
- docs/TRD.md                          (stack, architecture, payments, non-functional rules)
- docs/BACKEND_SCHEMA.md               (the database — it does not exist yet, you will create it)
- docs/IMPLEMENTATION_PLAN.md          (12 phases, build in this order)

DO NOT START CODING YET.

First produce, in this order:
1. A summary of what PLAN E is, who uses it, and the full screen inventory by ID (PL-01..PL-20,
   RM-01..RM-27).
2. Every contradiction or missing detail you found across the documents. Write them to
   docs/OPEN_QUESTIONS.md with a proposed default for each.
3. A build plan restating the 12 phases with the concrete files you will create in Phase 0 and 1.

Authority order when documents disagree: App Flow > UI/UX Report > TRD > Backend Schema > your
judgement. Never invent a screen that is not in the App Flow inventory.

Then stop and wait for me to say "start phase 0".
```

---

## 2. Loop prompt (paste this at the start of EVERY working session)

This is the self-driving prompt. It makes the agent pick up where it left off and keep going
without you re-explaining anything.

```
PLAN E autonomous build loop.

SCOPE RIGHT NOW: STAGE A ONLY — phases S0, S1, S2, S3, S4 in docs/IMPLEMENTATION_PLAN.md.
When S4's exit criteria pass, STOP, write the Stage A summary into docs/PROGRESS.md, and wait for
me. Do not begin Phase 5. Do not build anything listed in docs/FEATURES_BACKLOG.md.

STEP 1 — ORIENT
- Read docs/PROGRESS.md. If it does not exist, create it with S0-S4 and phases 5-12 marked TODO.
- Read docs/FEATURES_BACKLOG.md so you know what is deliberately NOT being built.
- Read docs/OPEN_QUESTIONS.md.
- Run: git log --oneline -15
- Identify the LOWEST phase not marked DONE (S0 → S1 → S2 → S3 → S4). That is the current phase.
  Do not work on any other phase.

STEP 2 — PLAN
- Re-read that phase's section in docs/IMPLEMENTATION_PLAN.md and the App Flow entries for every
  screen ID it covers.
- Write a task list of files to create/modify. Keep it to the smallest set that satisfies the
  phase's Exit criteria. No extra abstractions, no "for later" scaffolding, no features from a
  later phase.

STEP 3 — BUILD
- Implement the task list.
- Every screen file starts with a comment: // PL-XX <Screen Name>  (or RM-XX)
- Every screen implements its loading, empty and error state — the App Flow requires them.
- No hardcoded colors, spacing or user-facing strings: colors/spacing from src/theme, strings from
  i18n keys (add the en value now, ne in Phase 11).
- Money is integer paisa everywhere. Dates stored UTC, displayed Asia/Kathmandu via a tz library.
- Never write bookings.status, payments.*, experience_departures.spots_left or
  host_applications.status from the client.
- If something is genuinely unspecified: append it to docs/OPEN_QUESTIONS.md, choose the smallest
  reasonable default, mark it in code with // ASSUMPTION: <what and why>, and keep going. Never
  stall waiting for me.

STEP 4 — VERIFY (do not skip, do not self-declare success)
Run, and paste the real output:
  npx tsc --noEmit
  npm run lint
  npm test
  npx expo start  (confirm the app boots and the new screens render)
Plus this phase's Exit criteria from IMPLEMENTATION_PLAN.md, tested explicitly.
If anything fails: fix it and re-run. Do not proceed on red. Do not mark a phase DONE with a
failing check — report the failure instead.

STEP 5 — RECORD
- git add -A && git commit -m "feat(phase-N): <summary>"
- Update docs/PROGRESS.md: mark the phase DONE, list what was built, list what was deferred and
  why, list new open questions.

STEP 6 — CONTINUE
- Go back to STEP 1 for the next phase.
- Stop and ask me only if: a phase needs a real credential (Khalti/eSewa/Supabase/Google Maps
  keys), a decision would cost real money, or the same check has failed 3 times in a row.

Guardrails for the whole loop:
- Before the FIRST push of the session: run `git rev-parse --show-toplevel` and `git remote -v`,
  paste both. Toplevel must end in "PLAN E". Remote must be the plan-e repo only. Otherwise stop.
- Before the FIRST migration of the session: print the target Supabase project ref and confirm it
  matches PLAN E/.env. Otherwise stop.
- Never leave "Desktop\PLAN E". Never touch merobites or restro.
- One phase per commit. Never batch phases.
- Never delete supabase/tests/rls.test.sql or any existing test.
- Never commit .env or any secret.
- Prefer deleting code over adding it. If a file is not needed by the current phase, do not create it.
```

---

## 3. Graph prompt (coverage + integrity check — run after Phase 6, 9 and 12)

```
PLAN E integrity check. Produce a Mermaid graph and a coverage report. Do not change code yet.

A. SCREEN COVERAGE
Scan the codebase for the // PL-XX and // RM-XX header comments. Build a table:

  ID | Screen name | Implemented? | File path | Loading | Empty | Error state

Every ID from the App Flow inventory must appear. Mark MISSING for any with no file.

B. NAVIGATION GRAPH
Emit a Mermaid flowchart of what the CODE actually does — read the real navigation calls, not the
documents. Then emit a second Mermaid flowchart of what the App Flow Document specifies
(sections 4.1–4.4). Diff them and list:
  - edges in the docs but missing in code
  - edges in code but not in the docs (these are unplanned paths — justify or remove)

C. DATA GRAPH
Emit a Mermaid erDiagram of the live database (read supabase/migrations/, not the schema doc).
Then verify against docs/BACKEND_SCHEMA.md and list drift: missing tables, missing columns,
missing indexes, and — most important — any table with RLS disabled or with no policy.

D. INTEGRITY ASSERTIONS
Check each, answer YES/NO with the file:line proving it:
  1. Every restricted action for a guest routes to RM-05 and replays after auth.
  2. No client code writes bookings.status, payments.*, spots_left, or host_applications.status.
  3. All prices are computed server-side; the client only displays totals it received.
  4. All money is integer paisa; no float arithmetic on currency anywhere.
  5. Every table has RLS enabled and at least one policy.
  6. host-documents bucket is private and only reachable via admin signed URL.
  7. reviews has a unique constraint on booking_id (no duplicate reviews).
  8. payments has a unique idempotency_key (no double charge).
  9. Every list screen handles loading, empty and error.
 10. No hardcoded hex colors outside src/theme, and no user-facing string outside i18n.

E. OUTPUT
Write everything to docs/GRAPH_REPORT.md. Rank the gaps: BLOCKER (money, auth, data leak),
MAJOR (missing screen or state), MINOR (polish). Then propose the smallest set of fixes for the
BLOCKERs — and only after I approve, implement them.
```

---

## Notes

- Keep `docs/PROGRESS.md` and `docs/OPEN_QUESTIONS.md` in git. They are the agent's memory between
  sessions; without them the loop restarts from zero every time.
- Answer the questions in `OPEN_QUESTIONS.md` yourself as they accumulate — that file is where the
  agent's assumptions become your decisions.
- When you connect GitHub: the loop's one-commit-per-phase rule means each phase becomes a
  reviewable PR. Branch `phase/N-<name>`, PR into `main`.
