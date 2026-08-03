# PLAN E — Backend Schema Document

Version 1.0 · Postgres 15 / Supabase · currency NPR stored as integer paisa · all timestamps `timestamptz` UTC

No database exists yet. This document **is** the database. Migrations live in
`supabase/migrations/` and must be created in the numbered order below.

---

## 1. Conventions

- Every table has `id uuid primary key default gen_random_uuid()`, `created_at`, `updated_at`.
- `updated_at` maintained by a shared trigger `set_updated_at()`.
- Money: `*_paisa bigint` (Rs. 1 = 100 paisa). Never `float`, never `numeric` for storage.
- Soft delete only where the App Flow needs history (`bookings`, `reviews`); everything else
  hard-deletes via `on delete cascade`.
- RLS is **enabled on every table**. Default deny. Policies listed per table.
- `auth.users` is Supabase-managed; `profiles` is our 1:1 extension.

---

## 2. Enums

```sql
create type user_role        as enum ('traveler','host_applicant','host','admin');
create type difficulty_level as enum ('easy','moderate','challenging','strenuous');
create type experience_status as enum ('draft','pending_review','published','paused','archived');
create type booking_status   as enum ('pending','confirmed','cancellation_requested','cancelled','completed','expired');
create type payment_status   as enum ('initiated','paid','failed','refunded');
create type payment_provider as enum ('khalti','esewa');
create type host_app_status  as enum ('draft','submitted','under_review','verification','approved','rejected');
create type trip_role        as enum ('traveler','host');
create type notif_type       as enum ('booking','chat','host_application','system','promo');
```

---

## 3. Tables

### 3.1 profiles
Extends `auth.users`. Created by trigger on user insert.

| column | type | notes |
|---|---|---|
| id | uuid PK | = `auth.users.id`, FK cascade |
| full_name | text | |
| phone | text unique | `+9779XXXXXXXX` |
| avatar_url | text | |
| location | text | e.g. "Kathmandu, Nepal" |
| bio | text | |
| role | user_role not null default 'traveler' | mirrored into JWT |
| language | text default 'en' | 'en' \| 'ne' |
| points | int not null default 0 | Home app-bar points chip |
| onboarding_complete | bool default false | |
| created_at / updated_at | timestamptz | |

RLS: select own row + public subset (full_name, avatar_url, location, bio) of anyone;
update own row only; role column update blocked to non-admins by column trigger.

### 3.2 interests / user_interests
`interests`: `id, slug unique, name_en, name_ne, icon, sort_order` — seed data
(trekking, hiking, camping, climbing, culture, wildlife, homestay, wellness, community, volunteering).

`user_interests`: `user_id FK profiles, interest_id FK interests`, PK `(user_id, interest_id)`.
RLS: user reads/writes only own rows. Minimum-3 rule enforced in the app (PL-05), not the DB.

### 3.3 regions
`id, slug unique, name_en, name_ne, cover_image_url, description, sort_order`.
Seed: Everest, Annapurna, Langtang, Mustang, Chitwan, Pokhara, Kathmandu Valley, Rara/Far West,
Manaslu, Kanchenjunga.

### 3.4 categories
`id, slug unique, name_en, name_ne, icon, cover_image_url, sort_order`.
Seed matches Explore chips: Trekking, Hiking, Camping, Climbing, Homestay, Culture, Wildlife,
Wellness, Volunteering.

### 3.5 experiences
The core content table (PL-06/07/08/09).

| column | type | notes |
|---|---|---|
| id | uuid PK | |
| host_id | uuid FK profiles | null for PLAN E-operated seed content |
| category_id | uuid FK categories | |
| region_id | uuid FK regions | |
| title | text not null | |
| slug | text unique | deep links |
| summary | text | card subtitle |
| description | text | trip overview |
| cover_image_url | text not null | |
| gallery | text[] | |
| location_name | text | "Shivapuri National Park" |
| meeting_point | text | |
| lat / lng | double precision | |
| duration_hours | int | render as days when ≥24 |
| difficulty | difficulty_level | |
| max_altitude_m | int | |
| group_size_min / group_size_max | int | |
| min_age | int | |
| price_paisa | bigint not null | base per adult |
| child_price_paisa | bigint | null = same as adult |
| currency | text default 'NPR' not null check (currency='NPR') | |
| included | text[] | "What's included" |
| bring_list | text[] | packing list |
| things_to_know | text[] | |
| permits_required | text[] | TIMS/ACAP/etc |
| best_season | int[] | month numbers 1–12 |
| rating_avg | numeric(2,1) default 0 | maintained by trigger |
| rating_count | int default 0 | maintained by trigger |
| status | experience_status default 'draft' | |
| search_tsv | tsvector generated | title+summary+location+region |
| created_at / updated_at | | |

Indexes: `(status, region_id)`, `(status, category_id)`, `(status, price_paisa)`,
`(status, difficulty)`, GIN on `search_tsv`, `(rating_avg desc)`, `(lat,lng)` if PostGIS later.

RLS: anyone (incl. anon) selects `status='published'`; host selects/updates own rows in
`draft/pending_review`; only admin/Edge Function may set `published`.

### 3.6 experience_departures
Availability is per date — Experience Details shows "spots left".

`id, experience_id FK, start_date date, end_date date, total_spots int, spots_left int check (spots_left >= 0), price_override_paisa bigint null, status text default 'open'`.
Unique `(experience_id, start_date)`. Index `(experience_id, start_date)` where status='open'.

RLS: public select for published parents; **no client write ever** — `spots_left` is moved only by
the booking trigger/Edge Function (service role).

### 3.7 saved_experiences
`user_id FK profiles, experience_id FK experiences, created_at`. PK `(user_id, experience_id)`.
RLS: full CRUD on own rows only. Backs PL-12 and the Profile "Saved" counter.

### 3.8 bookings
| column | type | notes |
|---|---|---|
| id | uuid PK | |
| booking_ref | text unique not null | human ID shown on PL-11, e.g. `PE-2A7K9M` |
| user_id | uuid FK profiles | |
| experience_id | uuid FK experiences | |
| departure_id | uuid FK experience_departures | |
| adults / children | int not null | |
| addons | jsonb default '[]' | `[{code:'porter',label,price_paisa}]` |
| contact_name / contact_phone | text not null | |
| subtotal_paisa / addons_paisa / fees_paisa / total_paisa | bigint not null | server-computed |
| status | booking_status default 'pending' | |
| quote_expires_at | timestamptz | pending quotes expire in 15 min |
| is_draft | bool default false | PL-14 Drafts tab |
| cancelled_at, completed_at | timestamptz | |
| created_at / updated_at | | |

Indexes: `(user_id, status)`, `(departure_id)`, `(status, quote_expires_at)` for the expiry job.

RLS: user selects own; user inserts own only with `status='pending'` and `is_draft=true`;
**status transitions are service-role only** (enforced by a `before update` trigger that rejects
any client-originated status change).

Derived views the app reads:
- `my_plans_upcoming` — confirmed bookings with `departure.start_date >= today`
- `my_trips_completed` — status `completed`
- `my_trips_cancelled` — status `cancelled`

### 3.9 booking_participants
`id, booking_id FK, full_name, age int, is_lead bool`. Used by the "Participants" section on PL-09
and by the host. RLS: booking owner + experience host.

### 3.10 payments
`id, booking_id FK unique, provider payment_provider, provider_ref text, idempotency_key text unique not null, amount_paisa bigint, status payment_status default 'initiated', raw_response jsonb, paid_at timestamptz, created_at/updated_at`.

RLS: **no client access at all** (service role only). App learns payment state via `bookings.status`.

### 3.11 trip_messages (RM-11)
`id, booking_id FK, sender_id FK profiles, body text, attachment_url text, created_at`.
Index `(booking_id, created_at desc)`. Realtime publication enabled.
RLS: sender/reader must be the booking owner or the experience host — checked via an
`is_trip_member(booking_id)` security-definer function.

### 3.12 itinerary_items (RM-10)
`id, experience_id FK, day_number int, start_time time, title, description, sort_order`.
Public read for published experiences. Authored by host/admin.

### 3.13 gear_checklist_items (RM-12)
`id, booking_id FK, label text, is_checked bool default false, is_custom bool default false, sort_order`.
Seeded from `experiences.bring_list` on booking confirmation. RLS: booking owner only.

### 3.14 budget_entries (RM-13)
`id, booking_id FK, label text, amount_paisa bigint, category text, spent_on date, created_at`.
RLS: booking owner only. Total is computed client-side, no stored aggregate.

### 3.15 reviews (RM-14/15)
`id, booking_id FK unique, experience_id FK, user_id FK, rating int check (1..5), title, body, photos text[], created_at/updated_at`.

`unique(booking_id)` is what makes "Leave a Review" flip to "Reviewed" and prevents duplicates.
Insert allowed only when the booking is `completed` and owned by the user (policy uses a
subquery, not client trust). Trigger recomputes `experiences.rating_avg/rating_count`.
Public read.

### 3.16 host_applications
`id, user_id FK profiles unique, status host_app_status default 'draft', current_step int default 1,
category_id, title, description, location, photos text[], verification_doc_path text,
submitted_at, reviewed_at, reviewer_note text, created_at/updated_at`.

Step 2 fields (PL-19) are the confirmed ones; steps 1/3/4 add columns once their content is
confirmed — leave the table extensible, do not invent fields.

RLS: user reads/updates own row while `status='draft'`; after `submitted` it is read-only to the
user; only admin/Edge Function moves the status forward. `verification_doc_path` points into a
**private** bucket, admin-only signed URLs.

### 3.17 notifications
`id, user_id FK, type notif_type, title, body, entity_id uuid, is_read bool default false, created_at`.
RLS: own rows, update limited to `is_read`.

### 3.18 device_tokens
`id, user_id FK, expo_push_token text unique, platform text, last_seen_at`. Own rows only.

---

## 4. Relationship map

```
auth.users 1─1 profiles
profiles 1─n user_interests n─1 interests
profiles 1─n saved_experiences n─1 experiences
profiles 1─n bookings n─1 experiences n─1 categories / regions
profiles 1─1 host_applications
experiences 1─n experience_departures 1─n bookings
experiences 1─n itinerary_items
bookings 1─1 payments
bookings 1─n booking_participants
bookings 1─n trip_messages / gear_checklist_items / budget_entries
bookings 1─1 reviews n─1 experiences
```

---

## 5. Ownership rules (the short version)

| Data | Owner | Reader |
|---|---|---|
| profile | user | public subset |
| interests, saved | user | user |
| experience | host (or PLAN E) | public when published |
| departure spots | system | public |
| booking, participants, gear, budget | booking user | user (+ host reads booking basics) |
| payment | system | nobody client-side |
| trip messages | trip members | trip members |
| review | author | public |
| host application + ID document | applicant (pre-submit) | admin |

---

## 6. Storage buckets

| Bucket | Public | Contents |
|---|---|---|
| `experience-media` | yes | covers, galleries |
| `avatars` | yes | profile pictures |
| `review-photos` | yes | review images |
| `host-documents` | **no** | ID/licence scans, admin signed URLs only |
| `chat-attachments` | no | signed URL to trip members |

---

## 7. Migration order

```
0001_extensions.sql          -- pgcrypto, pg_trgm, unaccent
0002_enums.sql
0003_profiles_trigger.sql    -- profiles + handle_new_user() + set_updated_at()
0004_taxonomy.sql            -- interests, categories, regions (+ seeds)
0005_experiences.sql         -- experiences, departures, itinerary_items, search_tsv
0006_saved.sql
0007_bookings.sql            -- bookings, participants, status-guard trigger
0008_payments.sql
0009_trip_tools.sql          -- trip_messages, gear_checklist_items, budget_entries
0010_reviews.sql             -- + rating aggregate trigger
0011_host_applications.sql
0012_notifications.sql       -- notifications, device_tokens
0013_rls_policies.sql        -- every policy, in one reviewable file
0014_views.sql               -- my_plans_upcoming, my_trips_*
0015_seed_dev.sql            -- ~30 Nepal experiences, dev only
```

Seed content should be real Nepal experiences (Everest Base Camp, Annapurna Base Camp, Poon Hill,
Langtang Valley, Mardi Himal, Shivapuri day hike, Chitwan safari, Rara Lake, Ghandruk homestay,
Bandipur culture walk, Pokhara paragliding, Lumbini pilgrimage, Manaslu circuit, Nagarkot sunrise,
Bhaktapur pottery workshop) so the UI is never demoed with lorem ipsum.

---

## 8. Deliberate simplifications

- No PostGIS in v1 — `lat/lng` + bounding-box filter is enough for a map with hundreds of pins.
  Add PostGIS when radius search or clustering is actually needed.
- Availability is per departure date, not per-seat inventory. Fine below ~1000 bookings/day.
- Search is Postgres `tsvector`. Move to a dedicated search service only if relevance complaints
  appear.
- No refund automation. Manual until volume justifies it.
