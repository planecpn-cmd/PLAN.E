-- Public review cards need review content, not internal booking/user IDs.

drop policy if exists "Reviews are readable by everyone" on public.reviews;
drop policy if exists "Users can read their own reviews" on public.reviews;

create policy "Users can read their own reviews"
  on public.reviews for select to authenticated
  using (auth.uid() = user_id);

revoke select on table public.reviews from anon, authenticated;
grant select on table public.reviews to authenticated;

create or replace function public.get_public_experience_reviews(
  p_experience_id uuid
)
returns table (
  id uuid,
  experience_id uuid,
  rating integer,
  title text,
  body text,
  photos text[],
  created_at timestamptz,
  updated_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    r.id,
    r.experience_id,
    r.rating,
    r.title,
    r.body,
    r.photos,
    r.created_at,
    r.updated_at
  from public.reviews r
  join public.experiences e on e.id = r.experience_id
  where r.experience_id = p_experience_id
    and e.status = 'published'::public.experience_status
  order by r.created_at desc;
$$;

revoke all on function public.get_public_experience_reviews(uuid)
  from public, anon, authenticated;
grant execute on function public.get_public_experience_reviews(uuid)
  to anon, authenticated;
