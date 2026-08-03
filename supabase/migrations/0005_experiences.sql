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
