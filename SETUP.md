# SETUP.md: what the owner must do for the pipeline to run

Everything else is in the repo:
- `.github/workflows/gates.yml`, `deploy.yml`, `agent.yml`
- `.github/CODEOWNERS`
- `webapp/gates/*` and `webapp/playwright.config.ts`
- `agent/graph-state.json`
- `supabase/migrations/20260910200000_*`, `20260910200100_*`

Do the steps in this order. **Read §6 (merge order) before merging anything** — it is not "merge whenever"; two steps in it must happen by hand, with your own credentials, before `infra/pipeline` goes in.

---

## ⚠ Local git safety: never verify merge order in a live session's checkout

If you (or an agent) need to check whether several branches merge together
cleanly before actually merging into `main` — which is exactly what §6 below
requires — do it in a **dedicated git worktree**, never in this checkout
(`PLAN E/`). A plain `git checkout` / `git merge` here moves the one shared
`HEAD` and working tree for *everything* pointed at this directory. If an
interactive Claude Code session (or you, in another terminal) has
uncommitted edits at that moment, they are silently discarded the instant
something else checks out a different ref — there is no prompt, no
conflict, nothing to undo.

This already happened once: a local merge-order check walked through
`tmp/gate-verify` / `tmp/final-merge-check`, octopus-merging the `p0crit/*`
branches with `infra/pipeline` in this exact directory, while an
interactive session had uncommitted `admin-panel/p0-test-harness` work in
progress. The edits vanished. No commits were lost — only what hadn't been
committed yet — and it was caught only because that session happened to
diff file contents against what it expected.

**The fix — a second, fully independent working copy:**

```bash
git worktree add ../PLAN-E-automation infra/pipeline
```

`../PLAN-E-automation` shares this repo's `.git` object store (so it sees
every branch and commit) but has its own `HEAD`, index, and working files.
Do every temporary checkout, octopus-merge dry run, or "does this actually
merge cleanly" check **there** — `cd ../PLAN-E-automation` first, not
`PLAN E/`. Nothing done in that worktree can ever touch this checkout's
`HEAD` or its uncommitted files, no matter what branch it lands on or what
it merges into what.

```bash
git worktree list                          # every worktree + which branch each is on
git worktree remove ../PLAN-E-automation   # tear it down once the check is done
```

This worktree already exists on disk as of 2026-09-11 — reuse it (`git
fetch` + `git checkout <ref>` inside it) rather than creating another one.

**Rule of thumb:** `PLAN E/` is for the work a human or a single active
session is actively looking at. Anything scripted, unattended, or
exploratory that needs to move `HEAD` around — including this file's own
§6 merge-order dry-runs — belongs in a worktree, never here.

---

## 0. One-time: push the branches (this environment has no push access)

```bash
git push -u origin p0crit/5-lint-and-omit-happening p0crit/1-reject-past-departure p0crit/2-jsonld-no-rating p0crit/3-remove-rating-badges p0crit/4-past-departures-closed infra/pipeline
```

Open one PR per branch into `main`. Do not merge any of them yet — see §6 for the order and the two manual steps in between.

---

## 1. Repository secrets

Add these under **Settings → Secrets and variables → Actions → New repository secret**.

| Secret | Used by | Value |
|---|---|---|
| `NEXT_PUBLIC_SUPABASE_URL` | gates, deploy, agent | `https://dtebgbrqynxahuzmbtbc.supabase.co` |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | gates, deploy, agent | Supabase → Project Settings → API → `anon` `public` key |
| `SUPABASE_PROJECT_REF` | deploy | `dtebgbrqynxahuzmbtbc` |
| `SUPABASE_ACCESS_TOKEN` | deploy | supabase.com → Account → Access Tokens → generate. It must belong to an account with **Owner/Admin on the project**. The account used in this session got 403. |
| `SUPABASE_DB_PASSWORD` | deploy | Supabase → Project Settings → Database → database password (reset it there if unknown) |
| `CLOUDFLARE_API_TOKEN` | deploy | Cloudflare → My Profile → API Tokens → template **"Edit Cloudflare Workers"**, scoped to the account that owns Worker `plan-e` and the `planenepal.com` zone |
| `CLOUDFLARE_ACCOUNT_ID` | deploy | Cloudflare dashboard → Workers & Pages → right sidebar "Account ID" |
| `ANTHROPIC_AGENT_KEY` | agent | console.anthropic.com → API Keys. Create a **key dedicated to this workflow** — do not reuse a key from anything else, in this repo or elsewhere. Set a spend limit on it. Because it is dedicated, you can rotate or revoke it any time without touching other integrations, and its usage in the Anthropic console tells you exactly what the agent has spent. |
| `AGENT_APP_ID` | agent | App ID of the GitHub App from §2 |
| `AGENT_APP_PRIVATE_KEY` | agent | The full `.pem` private key generated for that App (paste the whole file, including BEGIN/END lines) |

No other secrets are read. The service-role key is deliberately **not** used anywhere.

`agent.yml` runs on **manual dispatch only** — there is no schedule. Trigger it from the Actions tab, or `gh workflow run agent.yml`, when you want the next node picked up. Nothing runs on its own.

---

## 2. GitHub App for the agent (one time)

This is required so agent PRs trigger `gates.yml` and are authored by the app rather than by you. You cannot approve your own PR, so an app-authored PR is what lets your CODEOWNERS review count.

1. Go to **github.com → Settings → Developer settings → GitHub Apps → New GitHub App**.
   - Name: `plan-e-agent`. Homepage URL: the repo URL. Untick **Webhook → Active**.
   - Repository permissions: **Contents: Read and write**, **Pull requests: Read and write**, **Metadata: Read-only**. Nothing else.
   - "Where can this app be installed": **Only on this account**.
2. After creating it, copy the **App ID** into `AGENT_APP_ID`. Click **Generate a private key** and put the `.pem` in `AGENT_APP_PRIVATE_KEY`.
3. Click **Install App**, then **Only select repositories**, then `planecpn-cmd/PLAN.E`.

---

## 3. Cloudflare: turn off the Git auto-build

`deploy.yml` now deploys the webapp *after* the DB migrations and the edge function. Cloudflare's own Git integration currently builds on every push to `main`. That would deploy the webapp in parallel and out of order.

- Go to **Cloudflare → Workers & Pages → `plan-e` → Settings → Build**.
- Disconnect the Git repository, or disable automatic builds for `main`.
- Keep the Worker's existing environment variables. `NEXT_PUBLIC_SUPABASE_*` are also passed at build time from the secrets above.

---

## 4. Actions settings

In **Settings → Actions → General**:

- **Actions permissions**: "Allow all actions and reusable workflows". The workflows use `actions/*`, `supabase/setup-cli` and `actions/create-github-app-token`.
- **Workflow permissions**: "Read repository contents and packages permissions". This is the default; the workflows escalate nothing, and the agent pushes with the App token.

---

## 5. `supabase login` locally (needed for steps (c) and (d) below)

Steps (c) and (d) in §6 use your own Supabase CLI session, not a repo secret, because they must run **before** `infra/pipeline` (and therefore `deploy.yml`) exists on `main`. On your machine, with the Supabase CLI installed:

```bash
supabase login
supabase link --project-ref dtebgbrqynxahuzmbtbc
```

This needs an account with Owner/Admin on the project. The account used in this session got a 403 doing the same thing — use a different one if that happens to you too.

---

## 6. Merge order

Merge in exactly this order. Steps (c) and (d) are commands you run by hand, not PRs.
If you want to dry-run whether these branches actually merge together before
doing it for real, do that in the dedicated worktree from the callout above
(`../PLAN-E-automation`) — not in `PLAN E/`.

**(a) Merge `p0crit/5-lint-and-omit-happening` into `main`.**
Lint fixes, no functional change, and removes the "Happening This Week" homepage section (it ranked by rating with no date filter and can't be made truthful — see the commit message). Safe first because nothing later depends on it and it touches no backend.

**(b) Merge the four fix PRs into `main`, any order:** `p0crit/1-reject-past-departure`, `p0crit/2-jsonld-no-rating`, `p0crit/3-remove-rating-badges`, `p0crit/4-past-departures-closed`.
`main` now has the webapp code fixed and the new edge-function guard in `supabase/functions/create-booking-intent/index.ts`. **Nothing is deployed yet** — Cloudflare's own Git build is still off from §3 having not run, and there is no CI deploy until `infra/pipeline` merges. Production is unchanged at this point.

**(c) Manually deploy the fixed edge function:**

```bash
supabase functions deploy create-booking-intent --project-ref dtebgbrqynxahuzmbtbc
```

Do this now, before (e), so the past-departure booking guard is live as soon as possible — it is the one server-side fix in this batch (P0-CRIT item 1), and every day it waits is a day a past-dated departure can still be booked.

**(d) Reconcile production migrations, then apply the two new ones:**

```bash
supabase migration list --project-ref dtebgbrqynxahuzmbtbc
```

Compare that against `supabase/migrations/` on `main`. This session's branch history includes `admin-panel/p0-test-harness`, which may hold migrations not yet on `main` — if `migration list` shows anything applied on the remote that isn't in `main`'s `supabase/migrations/`, stop and reconcile that first (bring the missing files onto `main`, or `supabase migration repair` to mark them, whichever is actually true) rather than proceeding. Once the history is consistent, apply the two new ones by hand, in order:

```bash
supabase db push --project-ref dtebgbrqynxahuzmbtbc --include-all
```

This runs `20260910200000_close_past_departures_unpublish_demo.sql` (closes the 90 past-dated departures, unpublishes `demo-ram-mardi-himal-trek`) and `20260910200100_recategorise_mislabelled_listings.sql` (a no-op — every statement in it is commented out until you decide the categories in BLOCKED.md B8). Doing this by hand now, not through `deploy.yml`, means you see its output directly and can stop if `migration list` disagreed with `main`.

**(e) Merge `infra/pipeline` into `main`.**
This is the first time `deploy.yml` exists on `main`, so this merge **triggers a production deploy**: `db push` (a no-op now — you already applied both migrations in (d)), `functions deploy create-booking-intent` (a no-op — already deployed in (c)), then the webapp build and Cloudflare deploy (this one is not a no-op: it ships everything from (a) and (b) to planenepal.com). This is also the first run of `gates.yml`, which creates the check names branch protection needs in (f).

Do §1 (secrets), §2 (GitHub App), §3 (Cloudflare auto-build off) and §4 (Actions settings) before this step — `deploy.yml` needs the secrets, and §3 stops Cloudflare from racing this deploy.

**(f) Turn on branch protection last, once gates are green.**
Confirm `gates.yml` passed on the `infra/pipeline` PR (or open a small follow-up PR and watch it) before adding required checks — turning them on first, before the check names exist, blocks every PR including your own. In **Settings → Rules → Rulesets → New branch ruleset**, target `main`:

- **Restrict deletions**: on
- **Block force pushes**: on
- **Require a pull request before merging**: on
  - Required approvals: **1**
  - **Require review from Code Owners**: on
  - **Dismiss stale approvals when new commits are pushed**: on
- **Require status checks to pass**: on
  - **Require branches to be up to date before merging**: on
  - Add exactly these checks, all from GitHub Actions:
    - `typecheck`
    - `lint`
    - `build`
    - `edge-booking-test`
    - `gate-routes`
    - `gate-data-truth`
    - `gate-viewports`
- **Bypass list**: add **Repository admin** (you), set to "Allow for pull requests only". You cannot approve your own PRs, so without this you could never merge your own changes. Agent PRs have no bypass and always need your review.

After (f), the pipeline is fully live. The agent still does nothing until you open gate H1: set `"H1": { "approved": true }` in `agent/graph-state.json` in a PR (CODEOWNERS applies), then dispatch `agent.yml` yourself when you want it to pick up the next node.
