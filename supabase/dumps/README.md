# Database dumps

Snapshots taken from the hosted project with `supabase db dump --linked`.
These are **reference artifacts**, not the source of truth — `supabase/migrations/`
is. Regenerate after any migration change.

| File | Contents |
| --- | --- |
| `schema_public.sql` | `public` schema only: enums, tables, indexes, views, functions, triggers, RLS policies, grants. |
| `data_catalog.sql` | Catalog rows only (`categories`, `regions`, `interests`, `experiences`, `experience_departures`, `itinerary_items`). |

## Regenerating

```sh
export SUPABASE_DB_PASSWORD=<db-password>
supabase db dump --linked --schema public --file supabase/dumps/schema_public.sql
supabase db dump --linked --data-only --use-copy --schema public \
  -x public.bookings -x public.booking_participants -x public.payments \
  -x public.profiles -x public.device_tokens -x public.notifications \
  -x public.trip_messages -x public.budget_entries -x public.gear_checklist_items \
  -x public.reviews -x public.saved_experiences -x public.user_interests \
  -x public.host_applications \
  --file supabase/dumps/data_catalog.sql
```

## What is deliberately excluded

- **`auth` schema.** `--data-only` without `--schema public` pulls
  `auth.users`, `auth.refresh_tokens`, and `auth.mfa_factors`, which hold
  password hashes, session tokens, and MFA secrets. Always pass
  `--schema public`.
- **User-linked tables** (bookings, payments, profiles, reviews, messages).
  They reference Auth user IDs that do not exist in another project, and the
  payment rows are gateway test transactions.
- **`storage` schema.** Supabase provisions it on every project; the only
  project-specific parts (the `avatars` bucket and its four policies) live in
  migration `0017_profile_avatars.sql`.

## Notes

`itinerary_items` is populated by migration `0020_seed_itinerary_items.sql`
(210 rows across all 30 experiences), not by `supabase/seed.sql`. Multi-day
trips carry one row per day with a null `start_time`; day trips carry
time-stamped rows on day 1.

`australian-camp-overnight` and `panauti-community-homestay` each have two
itinerary days against a 24-hour `duration_hours`. That is intentional — both
are overnight trips that start one afternoon and end the next morning.
