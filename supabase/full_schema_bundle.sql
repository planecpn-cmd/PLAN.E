-- PLAN E: full schema bundle for local Docker Supabase
-- Generated 2026-08-06T17:11:01Z. Concatenation of supabase/migrations/0001-0017 in order.
-- Run once against a fresh local Supabase (docker) instance:
--   supabase db reset   (applies migrations automatically), OR
--   psql "$DATABASE_URL" -f supabase/full_schema_bundle.sql

-- ===== 0001_extensions.sql =====
-- Migration 0001: Extensions and common triggers
create extension if not exists "pgcrypto";
create extension if not exists "pg_trgm";
create extension if not exists "unaccent";

create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- ===== 0002_enums.sql =====
-- Migration 0002: Enums
create type user_role         as enum ('traveler','host_applicant','host','admin');
create type difficulty_level  as enum ('easy','moderate','challenging','strenuous');
create type experience_status as enum ('draft','pending_review','published','paused','archived');
create type booking_status    as enum ('pending','confirmed','cancellation_requested','cancelled','completed','expired');
create type payment_status    as enum ('initiated','paid','failed','refunded');
create type payment_provider  as enum ('khalti','esewa');
create type host_app_status   as enum ('draft','submitted','under_review','verification','approved','rejected');
create type trip_role         as enum ('traveler','host');
create type notif_type        as enum ('booking','chat','host_application','system','promo');

-- ===== 0003_profiles_trigger.sql =====
-- Migration 0003: Profiles table & new user trigger
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text unique,
  avatar_url text,
  location text,
  bio text,
  role user_role not null default 'traveler',
  language text default 'en' check (language in ('en','ne')),
  points int not null default 0,
  onboarding_complete boolean default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger set_profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- Trigger to create profile row automatically when new user signs up in auth.users
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', 'Traveler'),
    new.raw_user_meta_data->>'avatar_url'
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Trigger to prevent client role from changing user role unless admin
create or replace function public.prevent_profile_role_escalation()
returns trigger as $$
begin
  if old.role <> new.role and (current_setting('request.jwt.claims', true)::jsonb->>'role') <> 'service_role' then
    raise exception 'Permission denied: cannot alter profile role directly';
  end if;
  return new;
end;
$$ language plpgsql;

create trigger check_profile_role_update
  before update on public.profiles
  for each row execute function public.prevent_profile_role_escalation();

-- ===== 0004_taxonomy.sql =====
-- Migration 0004: Taxonomy (Interests, Regions, Categories)
create table public.interests (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  name_en text not null,
  name_ne text not null,
  icon text,
  sort_order int default 0,
  created_at timestamptz not null default now()
);

create table public.user_interests (
  user_id uuid references public.profiles(id) on delete cascade,
  interest_id uuid references public.interests(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, interest_id)
);

create table public.regions (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  name_en text not null,
  name_ne text not null,
  cover_image_url text,
  description text,
  sort_order int default 0,
  created_at timestamptz not null default now()
);

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  name_en text not null,
  name_ne text not null,
  icon text,
  cover_image_url text,
  sort_order int default 0,
  created_at timestamptz not null default now()
);

-- Seed Taxonomy Data
insert into public.interests (slug, name_en, name_ne, icon, sort_order) values
('trekking', 'Trekking', 'ट्रेकिङ', '🥾', 1),
('hiking', 'Day Hiking', 'हायकिङ', '🌲', 2),
('camping', 'Camping', 'क्याम्पिङ', '⛺', 3),
('climbing', 'Peak Climbing', 'पर्वतारोहण', '🏔️', 4),
('culture', 'Culture & Heritage', 'संस्कृति र सम्पदा', '🏛️', 5),
('wildlife', 'Wildlife & Safari', 'वन्यजन्तु सफारी', '🐘', 6),
('homestay', 'Homestay Experience', 'होमस्टे', '🏡', 7),
('wellness', 'Yoga & Wellness', 'योग तथा वेलनेस', '🧘', 8),
('community', 'Community Tours', 'सामुदायिक भ्रमण', '👥', 9),
('volunteering', 'Volunteering', 'स्वयंसेवा', '🤝', 10);

insert into public.regions (slug, name_en, name_ne, description, sort_order) values
('everest', 'Everest Region', 'सगरमाथा क्षेत्र', 'Home to the world tallest peaks and Sherpa culture', 1),
('annapurna', 'Annapurna Region', 'अन्नपूर्ण क्षेत्र', 'Diverse landscapes from sub-tropical forests to alpine passes', 2),
('langtang', 'Langtang Valley', 'लाङटाङ उपत्यका', 'Valley of glaciers close to Kathmandu', 3),
('mustang', 'Upper Mustang', 'अपर मुस्ताङ', 'Forbidden kingdom with ancient caves and Tibetan culture', 4),
('chitwan', 'Chitwan', 'चितवन', 'Dense tropical jungles teeming with rhinos and tigers', 5),
('pokhara', 'Pokhara Valley', 'पोखरा', 'Lakeside city surrounded by the Annapurna range', 6),
('kathmandu', 'Kathmandu Valley', 'काठमाडौँ उपत्यका', 'UNESCO World Heritage cities rich in medieval art', 7),
('rara', 'Rara & Far West', 'रारा तथा सुदूरपश्चिम', 'Pristine mountain lakes and untamed wilderness', 8),
('manaslu', 'Manaslu Circuit', 'मनास्लु क्षेत्र', 'Remote trek around the world eighth highest peak', 9),
('kanchenjunga', 'Kanchenjunga', 'कञ्चनजङ्घा', 'Wild eastern wilderness at Nepal border', 10);

insert into public.categories (slug, name_en, name_ne, icon, sort_order) values
('trekking', 'Trekking', 'ट्रेकिङ', '🥾', 1),
('hiking', 'Day Hiking', 'हायकिङ', '🌲', 2),
('camping', 'Camping', 'क्याम्पिङ', '⛺', 3),
('climbing', 'Climbing', 'पर्वतारोहण', '🏔️', 4),
('homestay', 'Homestay', 'होमस्टे', '🏡', 5),
('culture', 'Culture', 'संस्कृति', '🏛️', 6),
('wildlife', 'Wildlife', 'वन्यजन्तु', '🐘', 7),
('wellness', 'Wellness', 'वेलनेस', '🧘', 8),
('volunteering', 'Volunteering', 'स्वयंसेवा', '🤝', 9);

-- ===== 0005_experiences.sql =====
-- Migration 0005: Experiences, Departures & Itinerary
create table public.experiences (
  id uuid primary key default gen_random_uuid(),
  host_id uuid references public.profiles(id) on delete set null,
  category_id uuid references public.categories(id) on delete restrict,
  region_id uuid references public.regions(id) on delete restrict,
  title text not null,
  slug text unique not null,
  summary text,
  description text,
  cover_image_url text not null,
  gallery text[] default '{}',
  location_name text,
  meeting_point text,
  lat double precision,
  lng double precision,
  duration_hours int not null default 24,
  difficulty difficulty_level not null default 'moderate',
  max_altitude_m int,
  group_size_min int default 1,
  group_size_max int default 12,
  min_age int default 10,
  price_paisa bigint not null check (price_paisa >= 0),
  child_price_paisa bigint check (child_price_paisa is null or child_price_paisa >= 0),
  currency text not null default 'NPR' check (currency = 'NPR'),
  included text[] default '{}',
  bring_list text[] default '{}',
  things_to_know text[] default '{}',
  permits_required text[] default '{}',
  best_season int[] default '{3,4,5,9,10,11}',
  rating_avg numeric(2,1) default 0.0 check (rating_avg >= 0 and rating_avg <= 5.0),
  rating_count int default 0 check (rating_count >= 0),
  status experience_status default 'draft',
  search_tsv tsvector,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger set_experiences_updated_at
  before update on public.experiences
  for each row execute function public.set_updated_at();

-- TSVector auto-update trigger for search
create or replace function public.experiences_update_search_tsv()
returns trigger as $$
begin
  new.search_tsv := setweight(to_tsvector('english', coalesce(new.title, '')), 'A') ||
                    setweight(to_tsvector('english', coalesce(new.summary, '')), 'B') ||
                    setweight(to_tsvector('english', coalesce(new.location_name, '')), 'C');
  return new;
end;
$$ language plpgsql;

create trigger experiences_search_tsv_trigger
  before insert or update on public.experiences
  for each row execute function public.experiences_update_search_tsv();

create index idx_experiences_status_region on public.experiences(status, region_id);
create index idx_experiences_status_category on public.experiences(status, category_id);
create index idx_experiences_status_price on public.experiences(status, price_paisa);
create index idx_experiences_status_difficulty on public.experiences(status, difficulty);
create index idx_experiences_search_tsv on public.experiences using gin(search_tsv);
create index idx_experiences_rating on public.experiences(rating_avg desc);

-- Departures table
create table public.experience_departures (
  id uuid primary key default gen_random_uuid(),
  experience_id uuid not null references public.experiences(id) on delete cascade,
  start_date date not null,
  end_date date not null,
  total_spots int not null check (total_spots > 0),
  spots_left int not null check (spots_left >= 0),
  price_override_paisa bigint check (price_override_paisa is null or price_override_paisa >= 0),
  status text default 'open',
  created_at timestamptz not null default now(),
  constraint unique_experience_start_date unique (experience_id, start_date)
);

create index idx_departures_exp_date on public.experience_departures(experience_id, start_date) where status = 'open';

-- Itinerary items
create table public.itinerary_items (
  id uuid primary key default gen_random_uuid(),
  experience_id uuid not null references public.experiences(id) on delete cascade,
  day_number int not null check (day_number > 0),
  start_time time,
  title text not null,
  description text,
  sort_order int default 0,
  created_at timestamptz not null default now()
);

create index idx_itinerary_exp_day on public.itinerary_items(experience_id, day_number);

-- ===== 0006_saved.sql =====
-- Migration 0006: Saved experiences
create table public.saved_experiences (
  user_id uuid references public.profiles(id) on delete cascade,
  experience_id uuid references public.experiences(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, experience_id)
);

-- ===== 0007_bookings.sql =====
-- Migration 0007: Bookings & Participants
create table public.bookings (
  id uuid primary key default gen_random_uuid(),
  booking_ref text unique not null,
  user_id uuid not null references public.profiles(id) on delete cascade,
  experience_id uuid not null references public.experiences(id) on delete restrict,
  departure_id uuid not null references public.experience_departures(id) on delete restrict,
  adults int not null check (adults >= 1),
  children int not null default 0 check (children >= 0),
  addons jsonb default '[]'::jsonb,
  contact_name text not null,
  contact_phone text not null,
  subtotal_paisa bigint not null check (subtotal_paisa >= 0),
  addons_paisa bigint not null default 0 check (addons_paisa >= 0),
  fees_paisa bigint not null default 0 check (fees_paisa >= 0),
  total_paisa bigint not null check (total_paisa >= 0),
  status booking_status not null default 'pending',
  quote_expires_at timestamptz,
  is_draft boolean default false,
  cancelled_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger set_bookings_updated_at
  before update on public.bookings
  for each row execute function public.set_updated_at();

-- Trigger preventing client role from mutating booking.status directly
create or replace function public.prevent_client_booking_status_change()
returns trigger as $$
begin
  if old.status <> new.status and (current_setting('request.jwt.claims', true)::jsonb->>'role') <> 'service_role' then
    raise exception 'Permission denied: booking status updates are restricted to service role';
  end if;
  return new;
end;
$$ language plpgsql;

create trigger check_booking_status_update
  before update on public.bookings
  for each row execute function public.prevent_client_booking_status_change();

create index idx_bookings_user_status on public.bookings(user_id, status);
create index idx_bookings_departure on public.bookings(departure_id);
create index idx_bookings_quote_expiry on public.bookings(status, quote_expires_at) where status = 'pending';

-- Booking participants
create table public.booking_participants (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  full_name text not null,
  age int,
  is_lead boolean default false,
  created_at timestamptz not null default now()
);

create index idx_participants_booking on public.booking_participants(booking_id);

-- ===== 0008_payments.sql =====
-- Migration 0008: Payments
create table public.payments (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid unique not null references public.bookings(id) on delete cascade,
  provider payment_provider not null,
  provider_ref text,
  idempotency_key text unique not null,
  amount_paisa bigint not null check (amount_paisa > 0),
  status payment_status not null default 'initiated',
  raw_response jsonb default '{}'::jsonb,
  paid_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger set_payments_updated_at
  before update on public.payments
  for each row execute function public.set_updated_at();

-- Trigger preventing client role from mutating payments
create or replace function public.prevent_client_payment_mutation()
returns trigger as $$
begin
  if (current_setting('request.jwt.claims', true)::jsonb->>'role') <> 'service_role' then
    raise exception 'Permission denied: payments table is service role only';
  end if;
  return new;
end;
$$ language plpgsql;

create trigger check_payment_mutation
  before insert or update or delete on public.payments
  for each row execute function public.prevent_client_payment_mutation();

-- ===== 0009_trip_tools.sql =====
-- Migration 0009: Trip Tools (Chat, Gear, Budget)

-- Helper security definer function to check trip membership
create or replace function public.is_trip_member(p_booking_id uuid)
returns boolean as $$
declare
  v_user_id uuid;
  v_is_owner boolean;
  v_is_host boolean;
begin
  v_user_id := auth.uid();
  if v_user_id is null then return false; end if;

  select exists (
    select 1 from public.bookings b where b.id = p_booking_id and b.user_id = v_user_id
  ) into v_is_owner;

  if v_is_owner then return true; end if;

  select exists (
    select 1 from public.bookings b
    join public.experiences e on e.id = b.experience_id
    where b.id = p_booking_id and e.host_id = v_user_id
  ) into v_is_host;

  return v_is_host;
end;
$$ language plpgsql security definer;

-- Trip messages (RM-11)
create table public.trip_messages (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  body text not null,
  attachment_url text,
  created_at timestamptz not null default now()
);

create index idx_trip_messages_booking on public.trip_messages(booking_id, created_at desc);

-- Gear checklist items (RM-12)
create table public.gear_checklist_items (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  label text not null,
  is_checked boolean not null default false,
  is_custom boolean not null default false,
  sort_order int default 0,
  created_at timestamptz not null default now()
);

create index idx_gear_items_booking on public.gear_checklist_items(booking_id);

-- Budget entries (RM-13)
create table public.budget_entries (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  label text not null,
  amount_paisa bigint not null check (amount_paisa >= 0),
  category text,
  spent_on date default current_date,
  created_at timestamptz not null default now()
);

create index idx_budget_entries_booking on public.budget_entries(booking_id);

-- ===== 0010_reviews.sql =====
-- Migration 0010: Reviews & Rating Aggregation Trigger
create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid unique not null references public.bookings(id) on delete cascade,
  experience_id uuid not null references public.experiences(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  rating int not null check (rating >= 1 and rating <= 5),
  title text,
  body text,
  photos text[] default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger set_reviews_updated_at
  before update on public.reviews
  for each row execute function public.set_updated_at();

-- Trigger to automatically update experiences.rating_avg and rating_count
create or replace function public.update_experience_rating_stats()
returns trigger as $$
declare
  v_exp_id uuid;
begin
  if (TG_OP = 'DELETE') then
    v_exp_id := old.experience_id;
  else
    v_exp_id := new.experience_id;
  end if;

  update public.experiences
  set
    rating_avg = coalesce((select round(avg(rating)::numeric, 1) from public.reviews where experience_id = v_exp_id), 0.0),
    rating_count = (select count(*) from public.reviews where experience_id = v_exp_id)
  where id = v_exp_id;

  return null;
end;
$$ language plpgsql security definer;

create trigger on_review_change
  after insert or update or delete on public.reviews
  for each row execute function public.update_experience_rating_stats();

-- ===== 0011_host_applications.sql =====
-- Migration 0011: Host Applications
create table public.host_applications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique not null references public.profiles(id) on delete cascade,
  status host_app_status not null default 'draft',
  current_step int not null default 1 check (current_step >= 1 and current_step <= 4),
  category_id uuid references public.categories(id) on delete set null,
  title text,
  description text,
  location text,
  photos text[] default '{}',
  verification_doc_path text,
  submitted_at timestamptz,
  reviewed_at timestamptz,
  reviewer_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger set_host_apps_updated_at
  before update on public.host_applications
  for each row execute function public.set_updated_at();

-- Trigger preventing client role from mutating host_applications.status directly
create or replace function public.prevent_client_host_app_status_change()
returns trigger as $$
begin
  if old.status <> new.status and (current_setting('request.jwt.claims', true)::jsonb->>'role') <> 'service_role' then
    raise exception 'Permission denied: host application status updates are restricted to service role';
  end if;
  return new;
end;
$$ language plpgsql;

create trigger check_host_app_status_update
  before update on public.host_applications
  for each row execute function public.prevent_client_host_app_status_change();

-- ===== 0012_notifications.sql =====
-- Migration 0012: Notifications & Device Tokens
create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  type notif_type not null default 'system',
  title text not null,
  body text not null,
  entity_id uuid,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index idx_notifications_user on public.notifications(user_id, is_read, created_at desc);

create table public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  expo_push_token text unique not null,
  platform text,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index idx_device_tokens_user on public.device_tokens(user_id);

-- ===== 0013_rls_policies.sql =====
-- Migration 0013: RLS Policies for All Tables (Default Deny)

-- Enable RLS on every table
alter table public.profiles enable row level security;
alter table public.interests enable row level security;
alter table public.user_interests enable row level security;
alter table public.regions enable row level security;
alter table public.categories enable row level security;
alter table public.experiences enable row level security;
alter table public.experience_departures enable row level security;
alter table public.itinerary_items enable row level security;
alter table public.saved_experiences enable row level security;
alter table public.bookings enable row level security;
alter table public.booking_participants enable row level security;
alter table public.payments enable row level security;
alter table public.trip_messages enable row level security;
alter table public.gear_checklist_items enable row level security;
alter table public.budget_entries enable row level security;
alter table public.reviews enable row level security;
alter table public.host_applications enable row level security;
alter table public.notifications enable row level security;
alter table public.device_tokens enable row level security;

-------------------------------------------------------
-- 1. Profiles Policies
-------------------------------------------------------
create policy "Public profiles are readable by everyone"
  on public.profiles for select
  using (true);

create policy "Users can update their own profile"
  on public.profiles for update
  using (auth.uid() = id);

-------------------------------------------------------
-- 2. Interests Policies
-------------------------------------------------------
create policy "Interests are readable by everyone"
  on public.interests for select
  using (true);

-------------------------------------------------------
-- 3. User Interests Policies
-------------------------------------------------------
create policy "Users can read their own interests"
  on public.user_interests for select
  using (auth.uid() = user_id);

create policy "Users can manage their own interests"
  on public.user_interests for all
  using (auth.uid() = user_id);

-------------------------------------------------------
-- 4. Regions & Categories Policies
-------------------------------------------------------
create policy "Regions are readable by everyone"
  on public.regions for select
  using (true);

create policy "Categories are readable by everyone"
  on public.categories for select
  using (true);

-------------------------------------------------------
-- 5. Experiences & Departures Policies
-------------------------------------------------------
create policy "Published experiences are readable by anyone"
  on public.experiences for select
  using (status = 'published' or auth.uid() = host_id);

create policy "Hosts can manage draft or pending experiences"
  on public.experiences for all
  using (auth.uid() = host_id and status in ('draft','pending_review'));

create policy "Departures readable for published experiences"
  on public.experience_departures for select
  using (
    exists (
      select 1 from public.experiences e
      where e.id = experience_id and (e.status = 'published' or e.host_id = auth.uid())
    )
  );

create policy "Itinerary items readable by anyone"
  on public.itinerary_items for select
  using (
    exists (
      select 1 from public.experiences e
      where e.id = experience_id and (e.status = 'published' or e.host_id = auth.uid())
    )
  );

-------------------------------------------------------
-- 6. Saved Experiences Policies
-------------------------------------------------------
create policy "Users can manage saved experiences"
  on public.saved_experiences for all
  using (auth.uid() = user_id);

-------------------------------------------------------
-- 7. Bookings & Participants Policies
-------------------------------------------------------
create policy "Users can view their own bookings"
  on public.bookings for select
  using (
    auth.uid() = user_id or
    exists (
      select 1 from public.experiences e
      where e.id = experience_id and e.host_id = auth.uid()
    )
  );

create policy "Users can insert pending bookings"
  on public.bookings for insert
  with check (
    auth.uid() = user_id and status = 'pending'
  );

create policy "Participants readable by booking owner or host"
  on public.booking_participants for select
  using (
    exists (
      select 1 from public.bookings b
      where b.id = booking_id and (b.user_id = auth.uid() or exists (
        select 1 from public.experiences e where e.id = b.experience_id and e.host_id = auth.uid()
      ))
    )
  );

create policy "Booking lead user can insert participants"
  on public.booking_participants for insert
  with check (
    exists (
      select 1 from public.bookings b
      where b.id = booking_id and b.user_id = auth.uid()
    )
  );

-------------------------------------------------------
-- 8. Payments Policies (No Client Access)
-------------------------------------------------------
-- Intentionally no client policies created on payments! Service role only.

-------------------------------------------------------
-- 9. Trip Tools Policies
-------------------------------------------------------
create policy "Trip members can read trip messages"
  on public.trip_messages for select
  using (public.is_trip_member(booking_id));

create policy "Trip members can insert trip messages"
  on public.trip_messages for insert
  with check (public.is_trip_member(booking_id) and auth.uid() = sender_id);

create policy "Booking owners can manage gear checklist"
  on public.gear_checklist_items for all
  using (
    exists (select 1 from public.bookings b where b.id = booking_id and b.user_id = auth.uid())
  );

create policy "Booking owners can manage budget entries"
  on public.budget_entries for all
  using (
    exists (select 1 from public.bookings b where b.id = booking_id and b.user_id = auth.uid())
  );

-------------------------------------------------------
-- 10. Reviews Policies
-------------------------------------------------------
create policy "Reviews are readable by everyone"
  on public.reviews for select
  using (true);

create policy "Users can insert review for completed booking"
  on public.reviews for insert
  with check (
    auth.uid() = user_id and
    exists (
      select 1 from public.bookings b
      where b.id = booking_id and b.user_id = auth.uid() and b.status = 'completed'
    )
  );

-------------------------------------------------------
-- 11. Host Applications Policies
-------------------------------------------------------
create policy "Users can view their own host application"
  on public.host_applications for select
  using (auth.uid() = user_id);

create policy "Users can create and edit draft host applications"
  on public.host_applications for all
  using (auth.uid() = user_id and status = 'draft');

-------------------------------------------------------
-- 12. Notifications & Device Tokens
-------------------------------------------------------
create policy "Users can view their own notifications"
  on public.notifications for select
  using (auth.uid() = user_id);

create policy "Users can mark notifications as read"
  on public.notifications for update
  using (auth.uid() = user_id);

create policy "Users can manage their device tokens"
  on public.device_tokens for all
  using (auth.uid() = user_id);

-- ===== 0014_views.sql =====
-- Migration 0014: Views for My Plans and My Trips
create or replace view public.my_plans_upcoming as
select
  b.id as booking_id,
  b.booking_ref,
  b.user_id,
  b.status,
  b.total_paisa,
  b.adults,
  b.children,
  e.id as experience_id,
  e.title as experience_title,
  e.cover_image_url,
  e.location_name,
  d.start_date,
  d.end_date
from public.bookings b
join public.experiences e on e.id = b.experience_id
join public.experience_departures d on d.id = b.departure_id
where b.status = 'confirmed' and d.start_date >= current_date;

create or replace view public.my_trips_completed as
select
  b.id as booking_id,
  b.booking_ref,
  b.user_id,
  b.total_paisa,
  b.completed_at,
  e.id as experience_id,
  e.title as experience_title,
  e.cover_image_url,
  e.location_name,
  r.id as review_id
from public.bookings b
join public.experiences e on e.id = b.experience_id
left join public.reviews r on r.booking_id = b.id
where b.status = 'completed';

create or replace view public.my_trips_cancelled as
select
  b.id as booking_id,
  b.booking_ref,
  b.user_id,
  b.total_paisa,
  b.cancelled_at,
  e.id as experience_id,
  e.title as experience_title,
  e.cover_image_url,
  e.location_name
from public.bookings b
join public.experiences e on e.id = b.experience_id
where b.status = 'cancelled';

-- ===== 0015_seed_dev.sql =====
-- Migration 0015: Seed placeholder (seed data moved to supabase/seed.sql per G1)

-- ===== 0016_grants.sql =====
-- Migration 0016: Explicit Table and Sequence Grants for anon and authenticated roles

grant usage on schema public to anon, authenticated;

-- Grant table permissions (RLS policies will control actual row access)
grant select on all tables in schema public to anon, authenticated;
grant insert, update, delete on all tables in schema public to authenticated;

-- Grant sequence permissions for auto-increment / serial columns
grant usage, select on all sequences in schema public to anon, authenticated;

-- Ensure future tables inherit default grants
alter default privileges in schema public grant select on tables to anon, authenticated;
alter default privileges in schema public grant insert, update, delete on tables to authenticated;
alter default privileges in schema public grant usage, select on sequences to anon, authenticated;

-- ===== 0017_profile_avatars.sql =====
-- Public profile avatar bucket. Writes remain scoped to each authenticated user.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'avatars',
  'avatars',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy "Avatar images are publicly readable"
  on storage.objects for select
  using (bucket_id = 'avatars');

create policy "Users can upload their own avatar"
  on storage.objects for insert
  with check (
    bucket_id = 'avatars' and
    auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Users can update their own avatar"
  on storage.objects for update
  using (
    bucket_id = 'avatars' and
    auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Users can delete their own avatar"
  on storage.objects for delete
  using (
    bucket_id = 'avatars' and
    auth.uid()::text = (storage.foldername(name))[1]
  );

