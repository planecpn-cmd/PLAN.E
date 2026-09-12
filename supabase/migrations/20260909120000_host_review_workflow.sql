-- P2 — host application review workflow.
--
-- hosts:review recommends (writes recommend_* review rows, verifies documents).
-- hosts:decide decides (writes approve/reject/request_changes/under_review
-- review rows + the host_applications.status transition), always through the
-- service-role backend (withAdmin) — there is NO client write policy on either
-- new table.
--
-- Every new admin-readable table is has_scope()-gated, never bare is_admin()
-- (P1 carry-forward). Does NOT touch submit-host-application. Encrypted ID/bank
-- storage is out of scope (plan §1.4).

create type public.host_review_decision as enum (
  'recommend_approve', 'recommend_reject', 'recommend_changes',
  'under_review', 'approve', 'reject', 'request_changes'
);

-- ── append-only recommendation + decision history ──────────────────────────
create table public.host_application_reviews (
  id uuid primary key default gen_random_uuid(),
  application_id uuid not null references public.host_applications(id) on delete cascade,
  reviewer_id uuid not null references public.profiles(id),
  from_status public.host_app_status,
  to_status public.host_app_status,
  decision public.host_review_decision not null,
  checklist jsonb not null default '{}'::jsonb,
  note text,
  reason_code text,
  created_at timestamptz not null default now()
);
create index idx_host_application_reviews_app
  on public.host_application_reviews(application_id, created_at desc);

-- ── document metadata (paths otherwise live only as strings) ───────────────
create table public.host_documents (
  id uuid primary key default gen_random_uuid(),
  application_id uuid not null references public.host_applications(id) on delete cascade,
  kind text not null check (kind in (
    'identity_front', 'identity_back', 'business_document', 'safety_document',
    'host_photo', 'listing_photo', 'business_logo'
  )),
  storage_path text not null,
  mime text,
  size_bytes bigint,
  uploaded_at timestamptz not null default now(),
  verified_by uuid references public.profiles(id),
  verified_at timestamptz,
  rejection_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (application_id, storage_path)
);
create index idx_host_documents_app on public.host_documents(application_id);
create trigger set_host_documents_updated_at
  before update on public.host_documents
  for each row execute function public.set_updated_at();

alter table public.host_applications
  add column reviewer_id uuid references public.profiles(id);

-- ── RLS: hosts:review to read, no client writes ───────────────────────────
alter table public.host_application_reviews enable row level security;
alter table public.host_documents enable row level security;

revoke all privileges on table public.host_application_reviews from anon, authenticated;
revoke all privileges on table public.host_documents from anon, authenticated;
grant select on table public.host_application_reviews to authenticated;
grant select on table public.host_documents to authenticated;

create policy "Host reviewers can read review history"
  on public.host_application_reviews for select to authenticated
  using (public.has_scope('hosts:review'));

create policy "Host reviewers can read host documents"
  on public.host_documents for select to authenticated
  using (public.has_scope('hosts:review'));

-- ── derive host_documents from application_data ───────────────────────────
create or replace function private.upsert_host_document(p_app uuid, p_kind text, p_path text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_path is null or btrim(p_path) = '' then
    return;
  end if;
  insert into public.host_documents (application_id, kind, storage_path)
  values (p_app, p_kind, btrim(p_path))
  on conflict (application_id, storage_path) do nothing;
end;
$$;

create or replace function private.sync_host_documents_from_application()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_data jsonb := coalesce(new.application_data, '{}'::jsonb);
  v_path text;
begin
  perform private.upsert_host_document(new.id, 'identity_front',
    coalesce(v_data->>'identity_front_path', new.verification_doc_path));
  perform private.upsert_host_document(new.id, 'identity_back', v_data->>'identity_back_path');
  perform private.upsert_host_document(new.id, 'host_photo', v_data->>'host_photo_path');
  perform private.upsert_host_document(new.id, 'business_logo', v_data->>'business_logo_path');

  for v_path in
    select jsonb_array_elements_text(coalesce(v_data->'business_document_paths', '[]'::jsonb))
  loop
    perform private.upsert_host_document(new.id, 'business_document', v_path);
  end loop;
  for v_path in
    select jsonb_array_elements_text(coalesce(v_data->'safety_document_paths', '[]'::jsonb))
  loop
    perform private.upsert_host_document(new.id, 'safety_document', v_path);
  end loop;
  for v_path in
    select jsonb_array_elements_text(coalesce(v_data->'photo_paths', '[]'::jsonb))
  loop
    perform private.upsert_host_document(new.id, 'listing_photo', v_path);
  end loop;
  for v_path in select unnest(coalesce(new.photos, '{}'::text[]))
  loop
    perform private.upsert_host_document(new.id, 'listing_photo', v_path);
  end loop;

  return new;
end;
$$;

revoke all on function private.upsert_host_document(uuid, text, text) from public, anon, authenticated;
revoke all on function private.sync_host_documents_from_application() from public, anon, authenticated;

create trigger sync_host_documents_after_application_write
  after insert or update of application_data, verification_doc_path, photos
  on public.host_applications
  for each row execute function private.sync_host_documents_from_application();

-- backfill existing applications
insert into public.host_documents (application_id, kind, storage_path)
select app.id, d.kind, btrim(d.path)
from public.host_applications app
cross join lateral (
  select 'identity_front'::text as kind,
         coalesce(app.application_data->>'identity_front_path', app.verification_doc_path) as path
  union all select 'identity_back',   app.application_data->>'identity_back_path'
  union all select 'host_photo',       app.application_data->>'host_photo_path'
  union all select 'business_logo',    app.application_data->>'business_logo_path'
  union all select 'business_document', jsonb_array_elements_text(coalesce(app.application_data->'business_document_paths', '[]'::jsonb))
  union all select 'safety_document',  jsonb_array_elements_text(coalesce(app.application_data->'safety_document_paths', '[]'::jsonb))
  union all select 'listing_photo',    jsonb_array_elements_text(coalesce(app.application_data->'photo_paths', '[]'::jsonb))
  union all select 'listing_photo',    unnest(coalesce(app.photos, '{}'::text[]))
) d
where d.path is not null and btrim(d.path) <> ''
on conflict (application_id, storage_path) do nothing;

-- ── P1 carry-forward: collapse staff_members others-read to one condition ──
-- was `is_admin() or has_scope('staff:manage')`. Two conditions on one door is
-- how the P1 hole formed. Founders hold staff:manage (bootstrap), so nothing
-- breaks.
drop policy if exists "Staff managers and admins can read all staff rows" on public.staff_members;
create policy "Staff managers can read all staff rows"
  on public.staff_members for select to authenticated
  using (public.has_scope('staff:manage'));
