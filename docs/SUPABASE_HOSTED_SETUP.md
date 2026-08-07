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

Only do this on a new/empty project. The seed deliberately replaces existing
experiences and cascades dependent booking data.

```sh
supabase db query --linked --file supabase/seed.sql
supabase db query --linked --file supabase/migrations/0018_seed_experience_departures.sql
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

## 5. Recreate test users

Create fresh test accounts through the app or Supabase Auth dashboard. Do not
copy local Auth password hashes or refresh tokens. New user IDs will be linked
to profiles automatically by migration `0003_profiles_trigger.sql`.
