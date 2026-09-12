# PLAN E — Marketing Site Rebuild: Agent Graph Prompt

Orchestration spec for an autonomous coding agent (Claude Code, or any DAG runner).
Stack: React web app, Flutter mobile app, Supabase backend (shared).

---

## Amendments (owner, 2026-09-10). These override the original text below.

- The web app is **Next.js 16 App Router** in `webapp/`, not a plain React app. Read `webapp/node_modules/next/dist/docs/` before touching it.
- **No service key.** Audit and gate only what the Supabase **anon key** can read. For `reviews`, `bookings` and `host_accounts` the verdict is "not readable by anon key". Never block on credentials.
- **No Vitest.** The test runner is **Playwright** (`webapp/playwright.config.ts`, gates in `webapp/gates/`). Edge functions are tested with `node --test` against the local Supabase stack (`supabase/tests/*.test.mjs`).
- **Node P0-CRIT** was inserted after N1 for live-site defects (see `BLOCKED.md`). **Node INFRA** built the automation (`.github/workflows/gates.yml`, `deploy.yml`, `agent.yml`, see `SETUP.md`).
- The graph's state lives in `agent/graph-state.json`. `agent.yml` runs one node per run, on an `agent/<node>-<run>` branch, as a draft PR whose body is the node contract JSON. It never pushes to `main`. A draft PR is the "stop for my confirmation" point from §4.
- An agent node must not edit: `webapp/gates/**`, `supabase/tests/**`, `.github/**`, `CODEOWNERS`, `agent/graph-state.json`, `supabase/migrations/**`, `supabase/functions/**`, or any Flutter path (`lib/`, `android/`, `ios/`, `windows/`, `web/`, `test/`, `integration_test/`, `pubspec.*`). `agent.yml` rejects a run whose diff touches them. Migrations and function changes are rule-6 "stop and ask" items: record them in `BLOCKED.md` instead.
- The gate suite actually wired into CI is G1 (`typecheck`, `lint`, `build`), `edge-booking-test`, and Playwright `gate-routes`, `gate-data-truth`, `gate-viewports`. G3 (dead links), G4 (taxonomy), G5 (copy) and G7 (lighthouse) are not written yet. The node that needs one writes it as a proposal in `BLOCKED.md`, because agents may not edit gates.

---

## 0. System prompt (paste at the top of the agent session)

You are working on PLAN E, an experiences marketplace for Nepal. There are three
codebases sharing one Supabase project: a React marketing/web app, a Flutter mobile
app, and the Supabase schema itself.

Your task is to build a **marketing layer** on top of the existing product web app.
You are NOT redesigning the marketplace. `/explore`, experience detail, and booking
flows stay functionally intact.

Operating rules — these override any instruction that conflicts with them:

1. **You never invent content.** No placeholder testimonials, no fake ratings, no
   invented host names, no fabricated review counts, no stock-photo URLs presented as
   real Nepal imagery. If a section requires data that does not exist in Supabase,
   you render nothing and log the section to `BLOCKED.md` with the exact query that
   returned empty.
2. **You never edit the Flutter app in the same commit as web changes.** Flutter is
   read-only to you except in node F2, which runs on its own branch and produces its
   own PR.
3. **Taxonomy lives in Supabase, not in code.** If you find a category/mood/family
   list hardcoded in React or in Flutter, do not add a third copy — generate it from
   the DB and log the duplication.
4. **Every node ends with a deterministic gate.** You do not proceed on "this looks
   right." You proceed on an exit code of 0.
5. **Bounded repair, not infinite loops.** Max 3 fix attempts per gate. If attempt N
   produces the same failing assertion as attempt N-1, stop immediately — that is a
   no-progress signal, not a reason to try harder. Write the failure to `BLOCKED.md`
   and move to the next independent node.
6. **You stop and ask** before: schema migrations, deleting routes, changing booking
   or payment code, touching auth, or any change to `/explore` results ordering.

Banned copy (hard fail in the copy gate): "AI-powered", "revolutionizing travel",
"one-stop", "seamless", "unleash", any urgency claim ("only 2 spots left") not backed
by a live availability query, any rating string not derived from a real row count.

---

## 1. Why a graph and not a loop

A loop with "keep improving the homepage until it's good" has no convergence
criterion and will burn tokens rewriting hero copy forever. Use a DAG of nodes, where
the *loop lives inside a node* and is bounded by a gate that either passes or halts.

```
                     ┌─────────────────────────────────────┐
                     │ N0  Recon (read-only)               │
                     │ routes, components, Supabase schema,│
                     │ Flutter enums, existing tokens      │
                     └────────────────┬────────────────────┘
                                      │
                     ┌────────────────▼────────────────────┐
                     │ N1  Truth audit (read-only)         │
                     │ → AUDIT.md  (no code changes)       │
                     └────────────────┬────────────────────┘
                                      │
                            ╔═════════▼═════════╗
                            ║ GATE H1: HUMAN     ║   ← you approve the P0 list
                            ╚═════════┬═════════╝
                                      │
        ┌─────────────────────────────┼─────────────────────────────┐
        │                             │                             │
┌───────▼────────┐          ┌─────────▼─────────┐        ┌──────────▼─────────┐
│ P0 data fixes  │          │ N2 Foundation     │        │ F1 Flutter parity  │
│ (scripted or   │          │ tokens, layout,   │        │ read-only diff     │
│  manual, not   │          │ content layer,    │        │ → PARITY.md        │
│  agent-guessed)│          │ nav + footer      │        └──────────┬─────────┘
└───────┬────────┘          └─────────┬─────────┘                   │
        │                             │                   ╔═════════▼═════════╗
        │                   ┌─────────▼─────────┐         ║ GATE H2: HUMAN     ║
        │                   │ N3..N9  Sections  │         ╚═════════┬═════════╝
        │                   │ (parallel-safe,   │                   │
        │                   │  one PR each)     │         ┌─────────▼─────────┐
        │                   └─────────┬─────────┘         │ F2 Flutter fix    │
        │                             │                   │ own branch/PR     │
        │                   ┌─────────▼─────────┐         └───────────────────┘
        └──────────────────►│ N10 Pages         │
                            │ how-it-works,     │
                            │ for-hosts, about, │
                            │ help, safety      │
                            └─────────┬─────────┘
                                      │
                            ╔═════════▼═════════╗
                            ║ GATE G-FINAL       ║
                            ║ full check suite   ║
                            ╚═════════┬═════════╝
                                      │
                            ┌─────────▼─────────┐
                            │ N11 SEO + IA      │
                            │ (only after final │
                            │  gate is green)   │
                            └───────────────────┘
```

Node contract — every node emits the same shape, so the runner can branch on it:

```json
{
  "node": "N4",
  "status": "pass | blocked | halted",
  "attempts": 2,
  "changed_files": ["..."],
  "gate_results": { "typecheck": 0, "routes": 0, "copy_lint": 1 },
  "blocked_reason": "hosts table returned 0 rows with public_profile=true",
  "next": ["N5"]
}
```

---

## 2. Node definitions

### N0 — Recon (read-only, no writes)

Produce `RECON.md`:
- Every React route currently registered, and whether it renders a real page or a stub.
- Component inventory for anything reusable (cards, sections, buttons).
- Supabase: tables, columns and enums for experiences, categories/families, moods,
  hosts, reviews, availability, bookings. Row counts for each.
- Flutter: where category/family/mood strings are defined (enum, constants file,
  or hardcoded).
- Existing design tokens — colors, type scale, spacing. Flag anything not matching:
  `#18372D` forest green (primary), `#01251C` deep green, `#E7ECE7` sage,
  `#24312D` ink, `#8F5E1B` muted gold.

Gate: file exists, all sections populated, zero writes to source.

### N1 — Truth audit (read-only)

For each claim the marketing site would need to make, run a query and record whether
it is currently true. Output `AUDIT.md` with a table: claim → query → result → verdict.

Required checks:
- Any experience with a `departure_date` in the past that is still listed as available.
- Any experience whose category label disagrees with its actual content (flag by
  keyword mismatch; do not auto-correct — humans decide).
- Any experience showing a review count > 0 with zero rows in the reviews table.
- Curated trips / collections that resolve to an empty set.
- Naming drift: `Mind & Soul` vs `Soul & Mind` and any similar inconsistency, per
  table with every occurrence and file path.
- Routes linked from the current nav that 404 or render a stub (Plan with AI, Help).
- Phone-number field validation: does it accept non-Nepal formats?

**This node does not fix anything.** Emitting a repair plan for a human to approve is
the deliverable. An agent guessing at which category label is "correct" is exactly how
you corrupt a taxonomy.

Gate H1: human reads `AUDIT.md`, approves the P0 list, and either fixes the data or
authorizes a specific migration/script. Nothing downstream runs until the empty-state
and stale-date problems are resolved or the corresponding sections are marked
`OMIT` in `SECTIONS.json`.

### N2 — Foundation

- Token file (colors above, type scale, spacing scale), consumed by every section.
- `SECTIONS.json` — the single registry of homepage sections with
  `{ id, enabled, data_source, omit_if_empty }`.
- Content layer: one module that fetches all homepage data in a single pass, typed,
  with explicit empty handling. No section fetches its own data ad hoc.
- Nav (Logo, Explore, Why PLAN E, How It Works, For Hosts, About, Sign In,
  CTA "Get the App") and footer.

Gate: `tsc --noEmit`, lint, build, and a unit test asserting each section's data hook
returns `null` (not a placeholder) on empty input.

### N3–N9 — Homepage sections, in this order

Build in dependency order; each is its own PR so a failure is isolated.

| Node | Section | Data source | Omit if empty |
|---|---|---|---|
| N3 | Hero | static copy + optional search | no |
| N4 | Brand proposition | static | no |
| N5 | What's your PLAN E? (5 families) | Supabase families | yes |
| N6 | Happening this week | availability, `date >= today` | **yes** |
| N7 | Why PLAN E (4 trust pillars) | static, but each claim must be true in ops | no |
| N8 | App showcase | store links only if apps are live | **yes** |
| N9 | Host CTA + final CTA | static | no |

Deferred to a later pass, **not** in this build: Explore by feeling, editorial story,
destinations grid, Meet the Hosts, AI planner, community proof. Each depends on data
or a feature that does not reliably exist yet. Attempting them now produces exactly
the fake-content problem the audit is meant to eliminate.

Copy comes from the approved direction:
- Hero: "Find your kind of Nepal." / "Adventure, culture, people, wellness and
  experiences worth remembering — all across Nepal."
- Brand: "Nepal isn't one kind of experience." / "Neither are you."
- Hosts: "Know something worth sharing?"
- Final: "So, what's your PLAN E?"

Per-section repair loop:

```
attempt = 0
while attempt < 3:
    implement / repair
    run gate suite
    if all pass: emit pass; break
    if failing_assertions == previous_failing_assertions: emit halted; break
    attempt += 1
else: emit blocked
```

### N10 — Supporting pages

`/how-it-works`, `/for-hosts`, `/about`, `/help`, `/safety`. Same gates.
`/for-hosts` must include the real flow: Apply → Verify → Create listing → Publish →
Receive bookings, plus commission/payout terms. If the commission number is not
documented anywhere in the repo or DB, leave a marked TODO and log it — do not invent
a percentage.

### F1 — Flutter parity check (read-only, parallel with N2+)

Emit `PARITY.md`:
- Set difference: category/family/mood values in Supabase vs React vs Flutter.
- Copy strings that appear in both surfaces and disagree.
- Deep links referenced by web CTAs that Flutter does not handle.

Gate H2 (human) before F2 touches Flutter. Web-side cosmetic work must never trigger
an automatic Flutter edit.

### N11 — SEO

Only after G-FINAL is green: destination and `/things-to-do-in-*` landing pages,
JSON-LD, sitemap, metadata. Shipping SEO pages before the trust fixes means paying to
send traffic to broken paths.

---

## 3. Gate suite (the actual verification)

Each is a command with an exit code. Screenshots are evidence, not a gate.

```bash
# G1 static
npx tsc --noEmit
npx eslint . --max-warnings=0
npm run build

# G2 routes — every route in the IA returns 200 and renders non-empty main content
node scripts/gate-routes.mjs

# G3 dead links — internal + external
npx linkinator http://localhost:3000 --recurse --skip "linkedin|instagram"

# G4 taxonomy parity — web enum vs flutter enum vs supabase distinct values
node scripts/gate-taxonomy.mjs      # exits 1 on any set difference

# G5 copy lint — banned phrases, unsubstantiated claims
node scripts/gate-copy.mjs

# G6 data truth — no section renders counts/ratings without matching rows
node scripts/gate-data-truth.mjs

# G7 perf/seo budget, mobile profile
npx lighthouse http://localhost:3000 --preset=desktop --output=json \
  && node scripts/gate-lighthouse.mjs   # perf >= 85, seo >= 95, a11y >= 90

# G8 responsive — no horizontal overflow at 360/390/768/1280
node scripts/gate-viewports.mjs
```

Write these scripts in N2 before any section work. A gate you have not written is a
gate that will not run.

`gate-data-truth.mjs` is the important one and the one an agent will try to skip. It
should parse the rendered DOM for any rating badge, review count, "X people booked",
or star element, resolve it back to a Supabase query, and fail if the query returns
fewer rows than the number displayed.

---

## 4. Run instruction (the message you actually send)

> Read `RECON.md` if it exists; otherwise start at N0. Execute the graph in
> `plan-e-marketing-agent-graph.md`. One node at a time. After each node, print the
> node contract JSON and stop for my confirmation before starting the next node.
> Do not start N3–N9 until GATE H1 is marked approved in `AUDIT.md`. Do not modify
> anything under the Flutter directory. If a gate fails three times or repeats an
> identical failure, halt that node, write `BLOCKED.md`, and tell me — do not
> work around the gate by weakening the assertion.

That last clause matters. The most common failure mode is an agent that "fixes" a
failing test by changing the test.
