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
