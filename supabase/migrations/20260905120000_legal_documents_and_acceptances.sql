-- Legal document delivery + acceptance evidence.
--
-- One delivery mechanism for all 13 legal documents (Terms, Privacy, Booking
-- Terms, Cancellation, Refund, Payment, Grievance, Account Deletion, Community
-- Guidelines, Safety & Risk, Risk Acknowledgment, Emergency, Cookie). Both the
-- Flutter app and the Next.js web client read the SAME rows here. Never hardcode
-- legal text in a client. See docs/AGENT_BUILD_PROMPT (plan-e-legal) §2.
--
-- Acceptance always references a document VERSION (legal_documents.id), never a
-- slug. "Accepted Terms v1.2 at 14:03 from the flutter client" is evidence;
-- "accepted the Terms" is not.

create table public.legal_documents (
  id                  uuid primary key default gen_random_uuid(),
  slug                text not null,
  version             text not null,               -- '1.0', '1.1'
  locale              text not null default 'en',   -- 'en', 'ne'
  title               text not null,
  body_md             text not null,
  effective_at        timestamptz not null,
  requires_acceptance boolean not null default false,
  is_current          boolean not null default false,
  created_at          timestamptz not null default now(),
  unique (slug, version, locale)
);

-- Only one version per slug+locale may be current. Enforced, not conventional.
create unique index legal_documents_one_current_per_slug_locale
  on public.legal_documents (slug, locale)
  where is_current;

create index legal_documents_slug_current
  on public.legal_documents (slug, locale)
  where is_current;

create table public.legal_acceptances (
  id           uuid primary key default gen_random_uuid(),
  -- restrict, NOT cascade: an acceptance is evidence and must survive account
  -- deletion. Deletion anonymises the linked auth user, it does not remove this.
  user_id      uuid not null references auth.users (id) on delete restrict,
  document_id  uuid not null references public.legal_documents (id),
  booking_id   uuid references public.bookings (id),  -- risk acknowledgment only
  accepted_at  timestamptz not null default now(),
  client       text not null check (client in ('flutter', 'web')),
  app_version  text,
  ip_address   inet,
  -- nulls not distinct so the sign-up / checkout acceptances (booking_id null)
  -- still dedupe to one row per user+document. The spec wrote this as a plain
  -- UNIQUE; under default Postgres NULL semantics that would let duplicates
  -- through, which is not the intent.
  unique nulls not distinct (user_id, document_id, booking_id)
);

create index legal_acceptances_user on public.legal_acceptances (user_id);
create index legal_acceptances_booking on public.legal_acceptances (booking_id)
  where booking_id is not null;

comment on table public.legal_documents is
  'Versioned legal document bodies. Read by both clients; anon-readable when current.';
comment on table public.legal_acceptances is
  'Immutable record that a user accepted a specific document version. Evidence.';

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------

alter table public.legal_documents enable row level security;
alter table public.legal_acceptances enable row level security;

revoke all privileges on table public.legal_documents from anon, authenticated;
revoke all privileges on table public.legal_acceptances from anon, authenticated;

-- Current documents are public: readable before sign-up and indexable by search
-- engines / app store reviewers.
grant select on table public.legal_documents to anon, authenticated;
create policy "Current legal documents are public"
  on public.legal_documents for select to anon, authenticated
  using (is_current);

-- A superseded version stays readable to anyone who accepted it, so a user can
-- always retrieve the exact text they agreed to.
create policy "Superseded versions readable by those who accepted them"
  on public.legal_documents for select to authenticated
  using (
    not is_current
    and exists (
      select 1 from public.legal_acceptances a
      where a.document_id = legal_documents.id
        and a.user_id = auth.uid()
    )
  );

-- A user may record and read their own acceptances. Nothing else: no UPDATE,
-- no DELETE for anon/authenticated. An acceptance record is not editable.
grant select, insert on table public.legal_acceptances to authenticated;

create policy "Users insert their own acceptances"
  on public.legal_acceptances for insert to authenticated
  with check (
    user_id = auth.uid()
    and client in ('flutter', 'web')
  );

create policy "Users read their own acceptances"
  on public.legal_acceptances for select to authenticated
  using (user_id = auth.uid());
