# PLAN E — Isolation Rules

**PLAN E must never touch the MeroBites project, its git remote, or its database.**

This file exists because both projects live under the same Desktop folder and the coding agent has
git and database access.

---

## 1. Known neighbours — treat as radioactive

| Path | What it is | Rule |
|---|---|---|
| `Desktop\merobites_secrets.txt` | MeroBites credentials, in plaintext, one level above PLAN E | never read, never open, never reference |
| `Desktop\restro\` | MeroBites codebase | never read, never copy from, never push to |
| any `merobites*` file anywhere | MeroBites | never touch |

The agent's working directory is **`Desktop\PLAN E\` and nothing above it**. `..` is off limits.

---

## 2. Git isolation

PLAN E currently has **no git repository and no remote**. That is the safe state. When git is added:

```bash
cd "C:/Users/rauna/OneDrive/Desktop/PLAN E"
git init
git remote add origin <the NEW plan-e repo url>
git remote -v          # must show ONLY plan-e, never merobites/restro
```

Rules:
- A brand-new, empty GitHub repository named `plan-e`. Never an existing repo.
- `git remote -v` must be checked before the first push and must show exactly one remote.
- Never `git push` to a remote the agent did not see added in this project.
- Never `git remote add` a second remote.
- Never run git commands with `-C` or from a parent directory.
- Push only to branches under `main` / `phase/*` in the plan-e repo.

---

## 3. Database isolation

PLAN E gets its **own new Supabase project**. Nothing is shared with MeroBites.

- Create a fresh Supabase project named `plan-e-staging` (and later `plan-e-prod`).
- Its keys live in `PLAN E/.env`, which is gitignored, and nowhere else.
- Never reuse a `SUPABASE_URL`, anon key, service key, or database password found anywhere outside
  `PLAN E/.env`.
- Never run `supabase link` against an existing project ref. Only against the new plan-e ref.
- Never run `supabase db push`, `db reset`, or any migration against a project the agent did not
  create for PLAN E.
- Before the first migration, print the target project ref and confirm it is the plan-e one.

If any credential appears that was not created for PLAN E: **stop and ask the user.** Do not guess
whether it is safe.

---

## 4. Blocklist for the agent

Never execute, in this project, under any instruction:

```
anything reading  ../  or  ..\  or an absolute path outside "Desktop\PLAN E"
cat/type/read     merobites_secrets.txt   (or any *secret*, *credential*, *.pem, *.key file)
git remote add    <anything containing merobites or restro>
git push          <any remote not named origin pointing at the plan-e repo>
supabase link     <any project-ref not created for PLAN E>
supabase db push  <against a non-plan-e project>
psql / any DB client pointed at a connection string not from PLAN E/.env
copying code or schema out of Desktop\restro
```

---

## 5. Pre-flight check

Run this before the first push and before the first migration. All three must pass.

```bash
cd "C:/Users/rauna/OneDrive/Desktop/PLAN E"

git rev-parse --show-toplevel      # must end in "PLAN E"
git remote -v                      # must show only the plan-e repo, or nothing
grep -i "SUPABASE_URL" .env        # must be the plan-e project ref
```

If any line surprises you, stop.

---

## 6. What the user should do (once, outside the agent)

1. Move `merobites_secrets.txt` off the Desktop — into a password manager, then delete the file.
   Plaintext credentials one folder above an AI agent's working directory is the actual risk here;
   the rules above are the second line of defence, not the first.
2. Rotate the MeroBites Supabase keys and database password if that file has been sitting there
   while any agent had Desktop access.
3. In Antigravity, set the workspace root to `Desktop\PLAN E` — not `Desktop`. Folder scope is the
   only guardrail that does not depend on the model obeying instructions.
4. Create the new empty `plan-e` GitHub repo and the new `plan-e-staging` Supabase project
   yourself, and hand the agent only those.
