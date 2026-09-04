-- Replace legacy schema-wide client grants with the operations the app uses.
-- RLS remains mandatory; grants are the first, coarse authorization layer.

revoke all privileges on all tables in schema public from anon, authenticated;
revoke all privileges on all sequences in schema public from anon, authenticated;

alter default privileges for role postgres in schema public
  revoke all privileges on tables from anon, authenticated;
alter default privileges for role postgres in schema public
  revoke all privileges on sequences from anon, authenticated;
alter default privileges for role postgres in schema public
  revoke execute on functions from public, anon, authenticated;

grant usage on schema public to anon, authenticated;

-- Public discovery and pre-auth configuration.
grant select on table
  public.app_config,
  public.app_versions,
  public.categories,
  public.experience_departures,
  public.experience_families,
  public.experience_tags,
  public.experiences,
  public.feature_flags,
  public.interests,
  public.itinerary_items,
  public.regions,
  public.remote_content,
  public.reviews,
  public.tags
to anon, authenticated;

-- Public profile identity is deliberately column-limited.
grant select (id, full_name, avatar_url)
  on table public.profiles to anon, authenticated;
grant update (
  full_name,
  phone,
  avatar_url,
  location,
  bio,
  language,
  onboarding_complete,
  updated_at
) on table public.profiles to authenticated;

-- Traveler-owned data.
grant select, insert, delete on table public.saved_experiences to authenticated;
grant select, insert, update, delete on table public.user_interests to authenticated;
grant select, insert on table public.bookings to authenticated;
grant select, insert on table public.booking_participants to authenticated;
grant select, insert, update, delete on table public.gear_checklist_items to authenticated;
grant select, insert, delete on table public.budget_entries to authenticated;
grant select, update on table public.notifications to authenticated;
grant insert on table public.reviews to authenticated;

-- Host access. RLS limits these operations to the owner/approved host.
grant select on table public.host_accounts to authenticated;
grant select, insert, update on table public.host_applications to authenticated;
grant insert, update, delete on table public.experiences to authenticated;

-- Trip chat reads and cursors. Message mutations and delivery writes use RPCs.
grant select on table
  public.trip_conversation_members,
  public.trip_conversations,
  public.trip_message_attachments,
  public.trip_message_deletions,
  public.trip_message_edits,
  public.trip_message_mutations,
  public.trip_message_receipts,
  public.trip_message_reports,
  public.trip_messages,
  public.trip_user_blocks
to authenticated;
grant select, insert, update on table public.trip_message_reads to authenticated;

-- Admin configuration writes. Admin-only RLS policies remain authoritative.
grant insert, update, delete on table
  public.app_config,
  public.app_versions,
  public.feature_flags,
  public.remote_content
to authenticated;
grant select on table public.config_audit_log to authenticated;

-- Intentionally no anon/authenticated grants:
-- ai_rate_limits, device_tokens, payments, payment_redirect_tokens,
-- trip_push_deliveries, and trip_push_device_tokens.
