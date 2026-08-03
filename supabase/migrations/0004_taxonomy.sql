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
