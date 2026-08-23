-- Phase 1: introduce a stable family -> category(type) -> tag taxonomy.
-- This migration is additive so existing experiences and category deep links
-- continue to work while the client moves away from trekking-first discovery.

create table public.experience_families (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  name_en text not null,
  name_ne text not null,
  description text,
  icon text,
  cover_image_url text,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

insert into public.experience_families
  (slug, name_en, name_ne, description, icon, sort_order)
values
  ('trips-tours', 'Trips & Tours', 'यात्रा तथा भ्रमण', 'Day trips, guided tours, packages, and sightseeing.', 'route', 1),
  ('adventure-together', 'Adventure Together', 'सँगै साहसिक यात्रा', 'Outdoor adventures made for sharing.', 'groups', 2),
  ('live-like-a-local', 'Live Like a Local', 'स्थानीय जस्तै बाँच्नुहोस्', 'Food, homes, villages, culture, and crafts.', 'home', 3),
  ('mind-soul', 'Mind & Soul', 'मन र आत्मा', 'Wellness, reflection, healing, and creativity.', 'self_improvement', 4),
  ('meet-people', 'Meet People', 'मानिसहरू भेट्नुहोस्', 'Meetups, activities, events, and communities.', 'diversity_3', 5),
  ('give-back', 'Give Back', 'योगदान दिनुहोस्', 'Community, conservation, and meaningful impact.', 'volunteer_activism', 6)
on conflict (slug) do update set
  name_en = excluded.name_en,
  name_ne = excluded.name_ne,
  description = excluded.description,
  icon = excluded.icon,
  sort_order = excluded.sort_order;

alter table public.categories
  add column family_id uuid references public.experience_families(id) on delete restrict;

update public.categories c
set family_id = f.id
from public.experience_families f
where f.slug = case
  when c.slug in ('trekking', 'hiking', 'camping', 'climbing', 'wildlife') then 'adventure-together'
  when c.slug in ('homestay', 'culture') then 'live-like-a-local'
  when c.slug = 'wellness' then 'mind-soul'
  when c.slug = 'volunteering' then 'give-back'
end;

insert into public.categories (slug, name_en, name_ne, icon, family_id, sort_order)
select seed.slug, seed.name_en, seed.name_ne, seed.icon, family.id, seed.sort_order
from (values
  ('day-trip', 'Day Trip', 'दैनिक यात्रा', 'route', 'trips-tours', 10),
  ('guided-tour', 'Guided Tour', 'निर्देशित भ्रमण', 'tour', 'trips-tours', 11),
  ('multi-day-tour', 'Multi-day Tour', 'बहुदिने भ्रमण', 'luggage', 'trips-tours', 12),
  ('travel-package', 'Travel Package', 'यात्रा प्याकेज', 'package', 'trips-tours', 13),
  ('food-experience', 'Food Experience', 'खाना अनुभव', 'restaurant', 'live-like-a-local', 20),
  ('village-stay', 'Village Stay', 'गाउँ बसाइ', 'cottage', 'live-like-a-local', 21),
  ('farm-experience', 'Farm Experience', 'कृषि अनुभव', 'agriculture', 'live-like-a-local', 22),
  ('craft-workshop', 'Craft Workshop', 'हस्तकला कार्यशाला', 'palette', 'live-like-a-local', 23),
  ('yoga', 'Yoga', 'योग', 'self_improvement', 'mind-soul', 30),
  ('meditation', 'Meditation', 'ध्यान', 'spa', 'mind-soul', 31),
  ('wellness-retreat', 'Wellness Retreat', 'वेलनेस रिट्रिट', 'eco', 'mind-soul', 32),
  ('creative-workshop', 'Creative Workshop', 'सृजनात्मक कार्यशाला', 'brush', 'mind-soul', 33),
  ('meetup', 'Meetup', 'भेटघाट', 'diversity_3', 'meet-people', 40),
  ('group-activity', 'Group Activity', 'समूह गतिविधि', 'groups', 'meet-people', 41),
  ('community-event', 'Community Event', 'सामुदायिक कार्यक्रम', 'event', 'meet-people', 42),
  ('volunteer-project', 'Volunteer Project', 'स्वयंसेवी परियोजना', 'volunteer_activism', 'give-back', 50),
  ('conservation-project', 'Conservation Project', 'संरक्षण परियोजना', 'nature', 'give-back', 51),
  ('skill-sharing', 'Skill Sharing', 'सीप आदानप्रदान', 'school', 'give-back', 52)
) as seed(slug, name_en, name_ne, icon, family_slug, sort_order)
join public.experience_families family on family.slug = seed.family_slug
on conflict (slug) do update set
  name_en = excluded.name_en,
  name_ne = excluded.name_ne,
  icon = excluded.icon,
  family_id = excluded.family_id,
  sort_order = excluded.sort_order;

create table public.tags (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  name_en text not null,
  name_ne text not null,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

create table public.experience_tags (
  experience_id uuid not null references public.experiences(id) on delete cascade,
  tag_id uuid not null references public.tags(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (experience_id, tag_id)
);

insert into public.tags (slug, name_en, name_ne, sort_order) values
  ('solo-friendly', 'Solo Friendly', 'एकलमैत्री', 1),
  ('couples', 'Couples', 'जोडी', 2),
  ('family-friendly', 'Family Friendly', 'परिवारमैत्री', 3),
  ('group', 'Group', 'समूह', 4),
  ('beginner-friendly', 'Beginner Friendly', 'शुरुआतीमैत्री', 5),
  ('indoor', 'Indoor', 'भित्री', 6),
  ('outdoor', 'Outdoor', 'बाहिरी', 7),
  ('half-day', 'Half Day', 'आधा दिन', 8),
  ('full-day', 'Full Day', 'पूरा दिन', 9),
  ('weekend', 'Weekend', 'सप्ताहन्त', 10),
  ('cultural', 'Cultural', 'सांस्कृतिक', 11),
  ('food', 'Food', 'खाना', 12),
  ('nature', 'Nature', 'प्रकृति', 13),
  ('social', 'Social', 'सामाजिक', 14),
  ('educational', 'Educational', 'शैक्षिक', 15),
  ('make-an-impact', 'Make an Impact', 'प्रभाव पार्नुहोस्', 16)
on conflict (slug) do update set
  name_en = excluded.name_en,
  name_ne = excluded.name_ne,
  sort_order = excluded.sort_order;

alter table public.experience_families enable row level security;
alter table public.tags enable row level security;
alter table public.experience_tags enable row level security;

create policy "Experience families are readable by everyone"
  on public.experience_families for select using (true);

create policy "Tags are readable by everyone"
  on public.tags for select using (true);

create policy "Published experience tags are readable by everyone"
  on public.experience_tags for select using (
    exists (
      select 1 from public.experiences e
      where e.id = experience_id and (e.status = 'published' or e.host_id = auth.uid())
    )
  );

grant select on public.experience_families, public.tags, public.experience_tags to anon;
grant select on public.experience_families, public.tags, public.experience_tags to authenticated;
grant select, insert, update, delete on public.experience_families, public.tags, public.experience_tags to service_role;

