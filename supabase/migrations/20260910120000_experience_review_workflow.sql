-- N1: admin experience-review workflow. Mirrors the P2 host-application review
-- shape (20260909120000): an append-only decision-history table, a reviewer_id
-- column, has_scope() SELECT RLS, and NO client write policy -- decisions go
-- through the service-role admin backend only.
--
-- Scope split (kept, not collapsed): content review is two-tier, matching P2's
-- hosts:review / hosts:decide.
--   content:manage  -- triage the queue, normalise taxonomy, RECOMMEND. Also
--                      the existing scope for config / feature flags / catalog.
--   content:decide  -- NEW. Commit a publish/reject decision on a listing.
-- A pure content:manage moderator can triage and recommend but cannot flip a
-- listing live. Founders hold both.

alter table public.staff_members
  drop constraint staff_members_scopes_known;

alter table public.staff_members
  add constraint staff_members_scopes_known check (
    scopes <@ array[
      'hosts:review',
      'hosts:decide',
      'bookings:read',
      'payments:read',
      'payments:act',
      'finance:read',
      'content:manage',
      'content:decide',
      'staff:manage'
    ]::text[]
  );

create type public.experience_review_decision as enum (
  'recommend_approve', 'recommend_reject', 'recommend_changes',
  'under_review', 'approve', 'reject', 'request_changes'
);

create table public.experience_reviews (
  id            uuid primary key default gen_random_uuid(),
  experience_id uuid not null references public.experiences(id) on delete cascade,
  reviewer_id   uuid not null references public.profiles(id),
  from_status   public.experience_status,
  to_status     public.experience_status,
  decision      public.experience_review_decision not null,
  checklist     jsonb not null default '{}'::jsonb,
  note          text,
  reason_code   text,
  created_at    timestamptz not null default now()
);

create index idx_experience_reviews_exp
  on public.experience_reviews (experience_id, created_at desc);

alter table public.experiences
  add column reviewer_id uuid references public.profiles(id);

alter table public.experience_reviews enable row level security;
revoke all on table public.experience_reviews from anon, authenticated;
grant select on table public.experience_reviews to authenticated;

create policy "Content managers read experience review history"
  on public.experience_reviews for select to authenticated
  using (public.has_scope('content:manage'));

-- The review detail screen reads with the anon session client, so a
-- content:manage reviewer needs to see a pending_review listing's departure
-- (itinerary_items and experiences already have suitable read policies).
create policy "Content managers read all departures"
  on public.experience_departures for select to authenticated
  using (public.has_scope('content:manage'));

-- No client write policy on experience_reviews: review rows and every
-- experiences.status transition are written by the admin backend with the
-- service-role client, gated by withAdmin('content:manage' | 'content:decide').

-- Public home for APPROVED experience imagery (D2 copy-on-approve target).
-- catalog-images is webp-only "licensed stock photography"; approved host photos
-- get their own public bucket so that constraint and that intent stay separate.
-- Objects in a public bucket are world-readable via getPublicUrl; there is NO
-- client write policy, so only the service-role admin backend copies into it
-- when a listing is approved. The private originals stay in experience-photos.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'experience-photos-public',
  'experience-photos-public',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = true,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;
