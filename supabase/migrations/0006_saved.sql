-- Migration 0006: Saved experiences
create table public.saved_experiences (
  user_id uuid references public.profiles(id) on delete cascade,
  experience_id uuid references public.experiences(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, experience_id)
);
