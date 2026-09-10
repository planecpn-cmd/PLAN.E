# SETUP.md: what the owner must do for the pipeline to run

Everything else is in the repo:
- `.github/workflows/gates.yml`, `deploy.yml`, `agent.yml`
- `.github/CODEOWNERS`
- `webapp/gates/*` and `webapp/playwright.config.ts`
- `agent/graph-state.json`
- `supabase/migrations/20260910200000_*`, `20260910200100_*`

Do the steps in this order.

---

## 0. One-time: push the branches (this environment has no push access)

```bash
git push -u origin p0crit/1-reject-past-departure p0crit/2-jsonld-no-rating p0crit/3-remove-rating-badges p0crit/4-past-departures-closed infra/pipeline
```

Open one PR per branch into `main`, then merge in this order:

1. The four `p0crit/*` PRs.
2. `infra/pipeline`.

Merging `infra/pipeline` triggers `deploy.yml`, so finish sections 1–3 below **before** merging it.

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
| `ANTHROPIC_API_KEY` | agent | console.anthropic.com → API Keys. Set a monthly spend limit on the key; the agent runs nightly. |
| `AGENT_APP_ID` | agent | App ID of the GitHub App from §2 |
| `AGENT_APP_PRIVATE_KEY` | agent | The full `.pem` private key generated for that App (paste the whole file, including BEGIN/END lines) |

No other secrets are read. The service-role key is deliberately **not** used anywhere.

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

## 4. Branch protection on `main`

Do this after `infra/pipeline` has run `gates.yml` once, so the check names exist. In **Settings → Rules → Rulesets → New branch ruleset**, target `main`:

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

---

## 5. Actions settings

In **Settings → Actions → General**:

- **Actions permissions**: "Allow all actions and reusable workflows". The workflows use `actions/*`, `supabase/setup-cli` and `actions/create-github-app-token`.
- **Workflow permissions**: "Read repository contents and packages permissions". This is the default; the workflows escalate nothing, and the agent pushes with the App token.

That is all. The nightly agent run is a no-op until you open gate H1: set `"H1": { "approved": true }` in `agent/graph-state.json` in a PR (CODEOWNERS applies).
