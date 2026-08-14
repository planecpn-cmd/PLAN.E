-- Keep public catalog reads independent from the private Host Mode helper.
-- PostgreSQL is free to reorder boolean expressions, so combining the public
-- predicate and the authenticated helper in one policy can cause anon users
-- to attempt function execution even when an experience is published.

drop policy if exists "Published experiences and approved host records are readable"
  on public.experiences;

create policy "Published experiences are readable by everyone"
  on public.experiences for select
  to anon, authenticated
  using (status = 'published'::public.experience_status);

create policy "Approved active hosts can view their own experiences"
  on public.experiences for select
  to authenticated
  using (
    auth.uid() = host_id and
    private.is_approved_active_host(auth.uid())
  );
