# PLAN E — Agent Prompts (Antigravity) · Flutter edition

Version 2.0. Two prompts, both self-contained — isolation and verification rules are baked in, so
you copy one block and nothing else.

- **LOOP** — the self-driving build prompt. Paste at the start of every working session.
- **GRAPH** — the read-only audit. Run after S4, and again after phases 9 and 12.

v2.0 changes: rewritten for Flutter/Dart, and the verification step is much harder. The previous
run marked three phases DONE on criteria it never checked — the fix is section STEP 4 below.

---

## LOOP PROMPT

```
HARD BOUNDARY — violating any of these ends the session immediately.
- Working directory is "Desktop\PLAN E". Never read, write or list anything above it. No "..", no
  absolute paths outside it.
- Another project on this machine is MeroBites: Desktop\restro\ and Desktop\merobites_secrets.txt.
  It is ALSO a Flutter app. You never open, read, copy from, or take inspiration from it. Not for
  payments, not for patterns, not "just to look". If "merobites" or "restro" appears in any path,
  STOP and tell me.
- pubspec.yaml must contain no `path:` dependency pointing outside this repo. Never copy a
  google-services.json, keystore, or bundle ID from another project. applicationId is com.plane.*
- Git: PLAN E pushes ONLY to its own new empty repo. Before your first push run
  `git rev-parse --show-toplevel` and `git remote -v`, paste both. Toplevel must end in "PLAN E".
  Exactly one remote, the plan-e one. Never `git remote add` a second remote. Never `git -C`.
  Never force-push.
- Database: PLAN E uses ONLY the Supabase project whose keys are in this repo's env/ files. Before
  your first migration, print the target project ref and confirm it matches. Never run
  `supabase link`, `db push`, `db reset` or any SQL against any other ref or connection string.
- Any credential, key or connection string not created for PLAN E: do not use it, do not echo it,
  tell me it exists and stop.
- Read docs/ISOLATION.md before doing anything else.

PLAN E autonomous build loop. The app is FLUTTER / DART. There is no React Native, no TypeScript,
no npm. If you find any, Phase S-1 deletes it.

SCOPE RIGHT NOW: STAGE A ONLY — phases S-1, S0, S1, S2, S3, S4 in docs/IMPLEMENTATION_PLAN.md.
When S4's exit criteria pass, STOP, write the Stage A summary into docs/PROGRESS.md, and wait for
me. Do not begin Phase 5. Do not build anything listed in docs/FEATURES_BACKLOG.md.

Source documents, in authority order when they disagree:
  docs/PLAN_E_App_Flow_Document.docx   (screen inventory, transitions, states — HIGHEST)
  docs/PLAN_E_UI_UX_Design_Report.docx (colors, typography, screen intent)
  docs/TRD.md                          (Flutter stack, architecture, payments, NFRs)
  docs/BACKEND_SCHEMA.md               (the database — it exists as SQL but has never been applied)
  docs/IMPLEMENTATION_PLAN.md          (phase order and exit criteria)
  docs/FEATURES_BACKLOG.md             (what is deliberately NOT built)
  docs/ISOLATION.md                    (boundaries)

Repeat this loop until S4 is DONE.

STEP 1 — ORIENT
- Read docs/PROGRESS.md. If missing, create it listing S-1..S4 and phases 5-12, all TODO.
- Read docs/OPEN_QUESTIONS.md. If missing, create it empty.
- Read docs/FEATURES_BACKLOG.md so you know what not to build.
- Run: git log --oneline -15
- Current phase = the LOWEST phase not marked DONE (S-1 → S0 → S1 → S2 → S3 → S4).
  Work on that phase only. Never jump ahead. Never batch two phases into one commit.

STEP 2 — PLAN
- Re-read that phase's section in docs/IMPLEMENTATION_PLAN.md, plus the App Flow entries for every
  screen ID it covers.
- Write the task list: exact files to create or modify, smallest set that satisfies the Exit
  criteria. No extra abstractions, no scaffolding "for later", no features from a later phase.
- Show me the task list before building.

STEP 3 — BUILD
- Implement the task list. Dart and Flutter only.
- Every screen file opens with: // PL-XX <Screen Name>   or   // RM-XX <Screen Name>
  and lives at lib/features/<area>/<name>_screen.dart
- Layering is enforced: widget → provider → repository → Supabase. A widget NEVER calls
  Supabase.instance directly. All Supabase calls live in lib/repositories/.
- Every list and detail screen renders through AsyncValueView so loading, data, empty and error are
  structural, not optional. A screen missing any of the four is not done.
- No raw Color(0xFF...) outside lib/theme/. No user-facing literal string outside the ARB files
  (add the `en` value now; `ne` lands in Phase 11).
- Money is `int` paisa everywhere. Never `double` on currency. Display via formatNpr() with Nepali
  lakh grouping (Rs. 12,50,000 — not Rs. 1,250,000).
- Dates stored UTC, displayed via the `timezone` package with Asia/Kathmandu. Never a hardcoded
  +05:45, never DateTime.toLocal().
- Tap targets ≥48 dp. Selected state uses more than colour.
- The client NEVER writes: bookings.status, payments.*, experience_departures.spots_left,
  host_applications.status. Service-role only.
- Every table has RLS enabled and at least one policy. No exceptions.
- Genuinely unspecified? Append to docs/OPEN_QUESTIONS.md, pick the smallest reasonable default,
  mark it `// ASSUMPTION: <what and why>`, keep going. Never stall. Never invent a screen absent
  from the App Flow inventory.
- Prefer deleting code over adding it. If a file is not needed by the current phase, don't create it.

STEP 4 — VERIFY  (this is where the last run failed — read it twice)
A phase is DONE only when EVERY exit criterion has been verified by running something and pasting
the real output. Not a summary. Not "verified". The actual output.

Always run and paste:
  dart analyze --fatal-infos
  flutter test

Those two prove NOTHING about whether the app runs, whether a migration applies, or whether a
screen shows data. So additionally, for each exit criterion in the phase:
  - "app runs / screen renders"  → run `flutter run` on a device or emulator, paste the log, and
                                   describe what you actually saw on screen.
  - "migration applies"          → run `supabase db reset`, paste the output.
  - "RLS holds"                  → run the SQL test file, paste the result. For S2 you must also
                                   break one policy on purpose, show the test FAILING, then restore
                                   it. A test never seen to fail is not known to work.
  - "screen shows real data"     → show the actual seeded value appearing (log line, screenshot,
                                   or widget test asserting on it).
  - a grep-checkable rule        → paste the grep and its count.

If a criterion CANNOT be verified — no device, no database, no credentials, Docker not running —
mark the phase **BLOCKED**, not DONE, say exactly what you need from me, and stop. Marking a phase
DONE with an unverified criterion is the single worst thing you can do in this loop. It is worse
than making no progress, because it hides the gap under a green checkmark.

If anything is red: fix it and re-run. Never proceed on red.

STEP 5 — RECORD
- git add -A
- git commit -m "feat(phase-SN): <one-line summary>"
- Update docs/PROGRESS.md: mark the phase DONE or BLOCKED, list what was built, what was deferred
  and why, and any new open questions.

STEP 6 — CONTINUE
- Return to STEP 1 for the next phase.
- After S4 passes: STOP. Write the Stage A summary. Wait for me.

Stop and ask me only if:
  - a phase needs a real credential (Supabase, Khalti, eSewa, Google Maps, Firebase)
  - no device/emulator or no Docker is available for verification
  - a decision would cost real money
  - the same check has failed 3 times in a row
  - anything touches git remotes, Supabase project refs, or a path outside "Desktop\PLAN E"

Never delete supabase/tests/rls.test.sql or any existing test.
Never commit env/*.json, a keystore, or any secret. They must be gitignored before the first commit.
```

---

## GRAPH PROMPT

```
HARD BOUNDARY — same as the build loop.
- Working directory is "Desktop\PLAN E". Never go above it. No "..".
- Never open, read or reference Desktop\restro\ or Desktop\merobites_secrets.txt or any merobites
  file. MeroBites is also Flutter — that makes it more tempting, not less forbidden.
- This is a READ-ONLY audit. Change no code, run no migrations, push nothing, commit nothing until
  I explicitly approve the fixes in section G.

PLAN E integrity check. Flutter/Dart codebase. Produce a coverage report and graphs.
Read the CODE, not the documents, except where told to compare.
Report what you FIND, not what the plan says should be there. Under-reporting gaps is the failure
mode of this audit — if 20 screens are placeholder stubs, say 20.

A. SCREEN COVERAGE
Grep lib/ for the // PL-XX and // RM-XX header comments. One row per ID from the App Flow inventory
(PL-01..PL-20, RM-01..RM-27 — all 34, none omitted):

  ID | Screen name | File | Real? | Tokens? | AsyncValueView? | Loading | Empty | Error | Data source

  Real?      = does it do its job, or is it a placeholder that just prints its own ID and routes on?
               A "Log In" button that calls context.go('/home') is a PLACEHOLDER, not a login screen.
  Tokens?    = zero raw Color(0xFF...) in the file
  Data source= the provider/repository it reads from, or NONE

Report the counts honestly: real / placeholder / missing, out of 34. Then report:
  - total files under lib/features/          (n)
  - files importing a provider or repository (n)
  - files importing lib/theme                (n)
  - files using AsyncValueView               (n)
  - raw Color(0xFF...) occurrences outside lib/theme/   (n)
If those ratios are far apart, the skeleton is not done regardless of what PROGRESS.md claims.

B. NAVIGATION GRAPH
1. Mermaid flowchart of what the CODE does — read the real go_router routes and context.go/push
   calls, not the documents.
2. Mermaid flowchart of what the App Flow Document specifies (its sections 4.1–4.4).
3. Diff them:
   - edges in the docs but MISSING in code
   - edges in code but NOT in the docs — unplanned paths, justify or delete each
   - any screen with no inbound edge (unreachable) or no outbound edge (dead end)

C. DATA GRAPH
1. Mermaid erDiagram of the LIVE database — read supabase/migrations/, not the schema doc.
2. State plainly whether these migrations have ever been APPLIED to a database. Check for
   supabase/config.toml, a .branches or .temp dir, any migration history. Unapplied SQL is a guess,
   and if it has never run, say so at the top of the report in bold.
3. Compare against docs/BACKEND_SCHEMA.md; list drift — missing tables, columns, types, indexes,
   foreign keys.
4. List every table with RLS disabled, or RLS enabled with zero policies. Each is a BLOCKER.
5. Open supabase/tests/rls.test.sql and answer: CAN THIS TEST FAIL? A file of bare
   `select count(*) = 19 as ok` statements cannot — it only prints booleans. If every assertion is
   not wrapped so that it raises an exception, the test is decorative. Say so.

D. LAYERING
List every file under lib/features/ that calls Supabase.instance or a Supabase client directly.
Each one violates widget → provider → repository → Supabase. Report the count and the paths.

E. INTEGRITY ASSERTIONS
Answer YES or NO with the file:line that proves it. "Probably" is not an answer. If you cannot
prove it, the answer is NO.
   1.  Every restricted guest action routes to RM-05 and replays the deferred action after auth.
   2.  No client code writes bookings.status, payments.*, experience_departures.spots_left, or
       host_applications.status.
   3.  All prices are computed server-side; the client only displays totals it received.
       (In Stage A the PL-10 client pricing is expected — confirm it carries the // TEMP: marker.)
   4.  All money is `int` paisa. No double/num arithmetic on currency anywhere.
   5.  NPR displays with Nepali lakh grouping everywhere.
   6.  Dates stored UTC, displayed via the timezone package with Asia/Kathmandu. No hardcoded
       +05:45, no DateTime.toLocal() on trip dates.
   7.  Every table has RLS enabled and at least one policy.
   8.  The host-documents bucket is private; access only via admin signed URL.
   9.  reviews has a unique constraint on booking_id.
   10. payments has a unique idempotency_key.
   11. Every list and detail screen handles loading, empty and error.
   12. No raw Color(0xFF...) outside lib/theme/; no user-facing literal string outside ARB files.
   13. Every tap target is ≥48 dp.
   14. supabase/tests/rls.test.sql exists, CAN fail, and has been seen passing against a live DB.
   15. No secret in git history:
       git log -p | grep -iE "service_role|secret|password|api[_-]key|khalti|esewa" | head

F. ISOLATION AUDIT
   - git remote -v                     → paste. Exactly one remote (the plan-e repo) or none.
   - git rev-parse --show-toplevel     → must end in "PLAN E".
   - grep -rni "merobites|restro" lib/ supabase/ android/ ios/ pubspec.yaml  → any hit is a BLOCKER.
   - grep -n "path:" pubspec.yaml      → no path dependency outside this repo.
   - grep -n "applicationId" android/app/build.gradle → must be com.plane.*
   - confirm env/*.json and any keystore are gitignored and absent from history.

G. OUTPUT
Write everything to docs/GRAPH_REPORT.md. Rank every gap:
   BLOCKER — money, auth, data leak, RLS hole, isolation breach, unapplied migrations
   MAJOR   — placeholder screen counted as done, missing state, broken navigation edge,
             layering violation
   MINOR   — polish, naming, formatting
Put the honest headline counts at the very top: X of 34 screens real, Y placeholder, database
applied yes/no, RLS test can-fail yes/no.
Then propose the SMALLEST set of fixes for the BLOCKERs only — file, change, why.
Implement nothing until I approve the list.
```

---

## Notes

- `docs/PROGRESS.md` and `docs/OPEN_QUESTIONS.md` are the agent's memory between sessions. Keep
  them in git or the loop restarts from zero every time.
- Answer the accumulating questions in `OPEN_QUESTIONS.md` yourself — that file is where the
  agent's assumptions become your decisions.
- One commit per phase means each phase can become a reviewable PR. Branch `phase/N-<name>`,
  PR into `main`.
