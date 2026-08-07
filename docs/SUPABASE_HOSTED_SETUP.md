# Hosted Supabase setup

This repository contains everything portable that is needed to recreate the
PLAN E backend:

- database schema and RLS policies in `supabase/migrations/`;
- 9 categories, 10 regions, 10 interests, and 30 experiences in
  `supabase/seed.sql`;
- three current departure schedules per published experience through migration
  `0018_seed_experience_departures.sql` (90 departures with the current seed);
- all Edge Functions in `supabase/functions/`;
- safe environment-variable names and placeholders in
  `supabase/functions/.env.example`.

Local Auth sessions, password hashes, refresh tokens, gateway secrets, and
customer-linked test bookings/payments are intentionally not stored in Git.
Those records are either security credentials or reference a local Auth user
that does not exist in a new hosted project. The 11 current local payment
attempts are test transactions and must not be migrated as real payments.

## Scripted setup

`tool/setup_hosted_backend.sh` performs sections 1, 3, and 4 in one run. It
links the project, pushes migrations, and writes `env/local.json`, reading the
publishable key from the CLI so it never has to be pasted by hand:

```sh
supabase login
tool/setup_hosted_backend.sh --project-ref <PROJECT_REF>
```

Add `--with-functions` to upload secrets and deploy Edge Functions, and
`--check` to run preflight checks without changing anything. The catalog seed is
deliberately excluded from the default run — see section 2. Run
`tool/setup_hosted_backend.sh --help` for all options.

The manual steps below remain accurate and are what the script automates.

## Setup without a terminal

When no terminal is available (working from a phone, for example), the schema
can be applied from the Supabase dashboard instead:

1. Open `supabase/hosted_schema_bundle.sql` on GitHub and copy it.
2. In the dashboard, open the project and go to **SQL Editor > New query**.
3. Paste the file and run it.

The bundle covers migrations 0001-0017 plus 0019, which is everything the schema
needs including the service-role grants used by Edge Functions. Regenerate it
with `tool/build_schema_bundle.sh` after changing any migration.

This path applies **only to an empty database**. Tables use bare `create table`
and the taxonomy inserts in 0004 have no `on conflict` clause, so running it
against a project that already has the schema aborts on a duplicate object or
slug. The failure rolls back rather than corrupting data, so a duplicate-object
error simply means the schema is already installed.

Two limitations are worth knowing before choosing this route. Edge Functions
cannot be deployed from the dashboard — that step needs the CLI. And applying
SQL by hand leaves the CLI migration history empty, so a later `supabase db
push` will try to re-apply everything; reconcile it once you have a terminal:

```sh
supabase migration repair --status applied <version>
```

Prefer the scripted setup whenever a terminal is available.

## 1. Create and link the project

Install the Supabase CLI, sign in, create a hosted Supabase project, and copy
its project reference from the dashboard. From the repository root run:

```sh
supabase login
supabase link --project-ref <PROJECT_REF>
supabase db push --linked
```

`db push` installs all committed migrations, including tables, grants, RLS,
views, profile triggers, and departure generation.

## 2. Load the application catalog

**Destructive.** Only do this on a new/empty project. The seed deliberately
replaces existing experiences and cascades dependent booking data, so running it
against a project that already holds real bookings will destroy them.

```sh
supabase db query --linked --file supabase/seed.sql
supabase db query --linked --file supabase/migrations/0018_seed_experience_departures.sql
```

The scripted equivalent requires an explicit flag and a typed confirmation of
the project ref:

```sh
tool/setup_hosted_backend.sh --project-ref <PROJECT_REF> --with-seed
```

The second command is repeated because the migration runs before the external
seed during first deployment. Its inserts are idempotent.

## 3. Configure server-only payment secrets

Create a temporary file outside Git (for example
`supabase/functions/.env.hosted`) using this structure:

```dotenv
KHALTI_API_BASE_URL=https://dev.khalti.com/api/v2
KHALTI_SECRET_KEY=<YOUR_KHALTI_SANDBOX_SECRET>
KHALTI_PUBLIC_KEY=<YOUR_KHALTI_SANDBOX_PUBLIC_KEY>
ESEWA_MERCHANT_CODE=EPAYTEST
ESEWA_SECRET_KEY=<YOUR_ESEWA_SECRET>
PUBLIC_SUPABASE_URL=https://<PROJECT_REF>.supabase.co
```

Upload the secrets and deploy every function:

```sh
supabase secrets set --env-file supabase/functions/.env.hosted
supabase functions deploy
```

Never place `SUPABASE_SERVICE_ROLE_KEY`, payment secrets, or database passwords
in Flutter assets, Dart defines, commits, screenshots, or chat messages.

## 4. Configure Flutter on each development machine

Get the project URL and public anon/publishable key from the Supabase dashboard.
The anon key is intended for client applications; the service-role key is not.

```sh
flutter run -d <DEVICE_ID> \
  --dart-define=SUPABASE_URL=https://<PROJECT_REF>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<ANON_OR_PUBLISHABLE_KEY>
```

The same two client values can be used on macOS, Windows, and Android devices.
All of them will then read and write the same hosted database from any network.

Alternatively, write the values once to `env/local.json` (gitignored) and run
`flutter run` with no defines. `AppSupabaseClient.initialize()` prefers a
`--dart-define` when present and falls back to the file per key, so either value
can be overridden independently.

`env/` is declared as a Flutter asset in `pubspec.yaml`, which means everything
in `env/local.json` is extractable from a shipped build. The anon key is safe
there by design and is constrained by RLS. The optional `DEMO_EMAIL` and
`DEMO_PASSWORD` auto-login values are not — keep them out of any build you
distribute.

## 5. Recreate test users

Create fresh test accounts through the app or Supabase Auth dashboard. Do not
copy local Auth password hashes or refresh tokens. New user IDs will be linked
to profiles automatically by migration `0003_profiles_trigger.sql`.
