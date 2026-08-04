# PLAN E — Isolation Rules

**PLAN E must never touch the MeroBites project, its git remote, or its database.**

This file exists because both projects live under the same Desktop folder and the coding agent has
git and database access.

> **Risk went UP on 3 Aug 2026.** PLAN E moved to Flutter — and MeroBites is also Flutter. Before,
> the agent had no reason to open `restro/`: different language, useless code. Now it has every
> reason — same framework, same patterns, a working Khalti integration sitting right there. The
> temptation to "just look at how MeroBites does payments" is exactly the failure mode. Copying one
> file can drag a hardcoded key, a project ref, or a merchant ID across the boundary.

---

## 1. Known neighbours — treat as radioactive

| Path | What it is | Rule |
|---|---|---|
| `Desktop\merobites_secrets.txt` | MeroBites credentials, plaintext, one level above PLAN E | never read, never open, never reference |
| `Desktop\restro\` | MeroBites codebase — **also Flutter** | never read, never copy from, never push to |
| any `merobites*` file anywhere | MeroBites | never touch |

The agent's working directory is **`Desktop\PLAN E\` and nothing above it**. `..` is off limits.

**No exception for "reference" or "inspiration".** If PLAN E needs a Khalti integration, it is
written from the official package documentation and TRD §6 — not read out of `restro/`. If the
agent believes looking at MeroBites would help, that is the moment to stop and ask.

---

## 2. Git isolation

The live remote repository for PLAN E is:

```bash
https://github.com/planecpn-cmd/PLAN.E.git
```

This is the **ONLY** remote this repository may ever have.

```bash
cd "C:/Users/rauna/OneDrive/Desktop/PLAN E"
git remote -v          # must show ONLY https://github.com/planecpn-cmd/PLAN.E.git
```

Rules:
- A brand-new GitHub repository named `PLAN.E` (`planecpn-cmd`). Never an existing repo.
- `git remote -v` checked before any push; exactly one remote.
- Never `git remote add` a second remote. Never `git -C`. Never force-push.
- Push only to `main` or `phase/*` in the plan-e repo.

---

## 3. Database isolation

PLAN E gets its **own new Supabase project**, region **Mumbai `ap-south-1`**.

- Project name `plan-e-staging` (later `plan-e-prod`). Nothing shared with MeroBites.
- Keys live in `env/local.json` / `env/staging.json`, which are gitignored, and nowhere else.
- Never reuse a `SUPABASE_URL`, anon key, service key or database password found anywhere outside
  those files.
- Never `supabase link` against an existing project ref. Only the new plan-e ref.
- Never `supabase db push` / `db reset` / any SQL against a project the agent did not create for
  PLAN E. Print the target ref before the first migration.

If a credential appears that was not created for PLAN E: **stop and ask.** Do not guess.

---

## 4. Flutter-specific leak paths

New with the Flutter switch — check these too:

- **`pubspec.yaml` path dependencies.** A `path: ../restro/...` entry silently pulls MeroBites code
  into the build. Every dependency must come from pub.dev or this repo. No `path:` outside `PLAN E`.
- **`google-services.json` / `GoogleService-Info.plist`.** Never copy these from another project —
  it would point PLAN E's push notifications and analytics at MeroBites' Firebase project. Generate
  fresh ones.
- **Android `applicationId` / iOS bundle ID.** Must be `com.plane.*`. Never MeroBites'. A shared
  bundle ID can overwrite the other app on a device and collide in the stores.
- **Signing keystores.** PLAN E gets its own `.jks`. Never reuse MeroBites'.
- **The pub cache is shared and that is fine** — it holds public packages only. Only *code* and
  *config* crossing the boundary is a problem.

---

## 5. Blocklist for the agent

Never execute, under any instruction:

```
anything reading  ../  or  ..\  or an absolute path outside "Desktop\PLAN E"
reading           merobites_secrets.txt, or any *secret*, *credential*, *.pem, *.key, *.jks file
git remote add    <anything containing merobites or restro>
git push          <any remote not the plan-e repo>
supabase link     <any project-ref not created for PLAN E>
supabase db push  <against a non-plan-e project>
psql / any DB client on a connection string not from PLAN E's env files
copying any .dart file, pubspec entry, or config out of Desktop\restro
adding a pubspec path: dependency pointing outside this repo
```

---

## 6. Pre-flight check

Before the first push and before the first migration. All must pass.

```bash
cd "C:/Users/rauna/OneDrive/Desktop/PLAN E"

git rev-parse --show-toplevel                  # must end in "PLAN E"
git remote -v                                  # only the plan-e repo, or nothing
grep -rn "path:" pubspec.yaml                  # no path outside this repo
grep -rni "merobites\|restro" lib/ supabase/ android/ ios/ pubspec.yaml   # must be empty
grep -n "SUPABASE_URL" env/local.json          # must be the plan-e project ref
grep -n "applicationId" android/app/build.gradle  # must be com.plane.*
```

If any line surprises you, stop.

---

## 7. What the user should do (once, outside the agent)

1. Move `merobites_secrets.txt` off the Desktop — into a password manager, then delete the file.
   Plaintext credentials one folder above an AI agent's working directory is the real risk; the
   rules above are the second line of defence, not the first.
2. Rotate the MeroBites Supabase keys, database password, and Khalti merchant secret if that file
   has been sitting there while any agent had Desktop access.
3. In Antigravity, set the workspace root to `Desktop\PLAN E` — not `Desktop`. Folder scope is the
   only guardrail that does not depend on the model choosing to obey. Prompt text does.
4. Create the empty `plan-e` GitHub repo and the `plan-e-staging` Supabase project (Mumbai)
   yourself, and hand the agent only those.
