-- P1 Step 1 — indexes an admin panel filters/sorts on (context doc §9.5).
-- Additive, IF NOT EXISTS, safe to re-run. Verified against the live schema:
-- none of these are already covered under another name (bookings has only
-- (user_id,status) and a partial (status,quote_expires_at) WHERE pending;
-- legal_acceptances has only (user_id) and a partial (booking_id)).

-- host_applications: the review queue filters by status and sorts by submitted date
create index if not exists idx_host_applications_status
  on public.host_applications (status);
create index if not exists idx_host_applications_status_submitted_at
  on public.host_applications (status, submitted_at desc);
create index if not exists idx_host_applications_created_at
  on public.host_applications (created_at desc);

-- payments: reconciliation + stuck-payment queue
create index if not exists idx_payments_status
  on public.payments (status);
create index if not exists idx_payments_created_at
  on public.payments (created_at desc);
create index if not exists idx_payments_paid_at
  on public.payments (paid_at desc);
create index if not exists idx_payments_provider_status
  on public.payments (provider, status);

-- bookings: ops console list filters
create index if not exists idx_bookings_status
  on public.bookings (status);
create index if not exists idx_bookings_created_at
  on public.bookings (created_at desc);
create index if not exists idx_bookings_experience_id
  on public.bookings (experience_id);
create index if not exists idx_bookings_completed_at
  on public.bookings (completed_at desc);

-- profiles: list staff / hosts / applicants by role
create index if not exists idx_profiles_role
  on public.profiles (role);

-- reviews: per-experience listing, recency
create index if not exists idx_reviews_experience_id
  on public.reviews (experience_id);
create index if not exists idx_reviews_created_at
  on public.reviews (created_at desc);

-- experiences: "by host" views (the host_id FK had no index)
create index if not exists idx_experiences_host_id
  on public.experiences (host_id);

-- host_accounts: active / suspended filters
create index if not exists idx_host_accounts_is_active
  on public.host_accounts (is_active);
create index if not exists idx_host_accounts_suspended_at
  on public.host_accounts (suspended_at);

-- config_audit_log: "what changed on this table" / "what did this actor do"
create index if not exists idx_config_audit_log_table_changed_at
  on public.config_audit_log (table_name, changed_at desc);
create index if not exists idx_config_audit_log_changed_by
  on public.config_audit_log (changed_by);

-- legal_acceptances: "who accepted this document version", recency
create index if not exists idx_legal_acceptances_document_id
  on public.legal_acceptances (document_id);
create index if not exists idx_legal_acceptances_accepted_at
  on public.legal_acceptances (accepted_at desc);
