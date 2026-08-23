-- Phase 5 messaging hardening: private device registry and event-driven push.
-- The legacy public.device_tokens table is intentionally left untouched.

create table public.trip_push_device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  provider text not null check (provider in ('fcm', 'apns')),
  platform text not null check (platform in ('android', 'ios', 'web')),
  token text not null,
  is_active boolean not null default true,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (provider, token)
);

create index idx_trip_push_device_tokens_active_user
  on public.trip_push_device_tokens(user_id)
  where is_active;

create table public.trip_push_deliveries (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.trip_messages(id) on delete cascade,
  recipient_id uuid not null references auth.users(id) on delete cascade,
  recipient_role text not null check (recipient_role in ('traveler', 'host')),
  target_route text not null,
  status text not null default 'queued'
    check (status in ('queued', 'processing', 'sent', 'failed', 'skipped_no_token')),
  attempt_count integer not null default 0 check (attempt_count >= 0),
  dispatch_request_id bigint,
  error_code text,
  last_attempt_at timestamptz,
  sent_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (message_id, recipient_id)
);

create index idx_trip_push_deliveries_queued
  on public.trip_push_deliveries(created_at)
  where status in ('queued', 'failed');

alter table public.trip_push_device_tokens enable row level security;
alter table public.trip_push_deliveries enable row level security;

-- Raw device tokens and delivery internals have no client-readable policies.
-- Clients use the narrow registration RPCs below; the Edge Function uses the
-- service role, which bypasses RLS.
revoke all on table public.trip_push_device_tokens from public, anon, authenticated;
revoke all on table public.trip_push_deliveries from public, anon, authenticated;

create or replace function public.register_trip_push_device(
  p_token text,
  p_platform text,
  p_provider text default 'fcm'
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_id uuid;
  v_token text := btrim(p_token);
  v_platform text := lower(btrim(p_platform));
  v_provider text := lower(btrim(p_provider));
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;
  if length(v_token) < 20 or length(v_token) > 4096 then
    raise exception 'Invalid push token';
  end if;
  if v_platform not in ('android', 'ios', 'web') then
    raise exception 'Invalid push platform';
  end if;
  if v_provider not in ('fcm', 'apns') then
    raise exception 'Invalid push provider';
  end if;

  insert into public.trip_push_device_tokens (
    user_id, provider, platform, token, is_active, last_seen_at, updated_at
  ) values (
    v_user_id, v_provider, v_platform, v_token, true, now(), now()
  )
  on conflict (provider, token) do update
    set user_id = excluded.user_id,
        platform = excluded.platform,
        is_active = true,
        last_seen_at = now(),
        updated_at = now()
  returning id into v_id;

  return v_id;
end;
$$;

create or replace function public.unregister_trip_push_device(
  p_token text,
  p_provider text default 'fcm'
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  update public.trip_push_device_tokens
  set is_active = false,
      updated_at = now()
  where user_id = auth.uid()
    and provider = lower(btrim(p_provider))
    and token = btrim(p_token);
end;
$$;

revoke all on function public.register_trip_push_device(text, text, text)
  from public;
revoke all on function public.unregister_trip_push_device(text, text)
  from public;
grant execute on function public.register_trip_push_device(text, text, text)
  to authenticated;
grant execute on function public.unregister_trip_push_device(text, text)
  to authenticated;

-- Atomically claims delivery work so duplicate webhook invocations cannot
-- send duplicate notifications. A stale processing lease is reclaimable.
create or replace function public.claim_trip_push_deliveries(
  p_message_id uuid
)
returns table (
  id uuid,
  recipient_id uuid,
  target_route text
)
language sql
security definer
set search_path = ''
as $$
  update public.trip_push_deliveries delivery
  set status = 'processing',
      attempt_count = delivery.attempt_count + 1,
      last_attempt_at = now(),
      error_code = null,
      updated_at = now()
  where delivery.message_id = p_message_id
    and (
      delivery.status in ('queued', 'failed')
      or (
        delivery.status = 'processing'
        and delivery.last_attempt_at < now() - interval '5 minutes'
      )
    )
  returning delivery.id, delivery.recipient_id, delivery.target_route;
$$;

revoke all on function public.claim_trip_push_deliveries(uuid) from public;
grant execute on function public.claim_trip_push_deliveries(uuid) to service_role;

create or replace function private.enqueue_trip_message_push()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_push_url text;
  v_webhook_secret text;
  v_request_id bigint;
  v_recipient_count integer;
begin
  -- Membership rows unlock future group chat, while the booking-derived rows
  -- preserve the current authoritative participant model during shadow burn-in.
  insert into public.trip_push_deliveries (
    message_id,
    recipient_id,
    recipient_role,
    target_route
  )
  select distinct on (participant.user_id)
    new.id,
    participant.user_id,
    participant.role,
    case participant.role
      when 'host' then '/host/messages/' || new.booking_id::text
      else '/chat/' || new.booking_id::text
    end
  from (
    select member.user_id, member.role
    from public.trip_conversations conversation
    join public.trip_conversation_members member
      on member.conversation_id = conversation.id
    where conversation.booking_id = new.booking_id

    union

    select booking.user_id, 'traveler'::text
    from public.bookings booking
    where booking.id = new.booking_id

    union

    select experience.host_id, 'host'::text
    from public.bookings booking
    join public.experiences experience on experience.id = booking.experience_id
    where booking.id = new.booking_id
      and experience.host_id is not null
  ) participant
  where participant.user_id <> new.sender_id
  order by participant.user_id,
    case participant.role when 'host' then 0 else 1 end
  on conflict (message_id, recipient_id) do nothing;

  get diagnostics v_recipient_count = row_count;
  if v_recipient_count = 0 then
    return new;
  end if;

  -- Deployment configuration is stored encrypted in Vault, never in source:
  --   select vault.create_secret(
  --     'https://<project-ref>.supabase.co/functions/v1/trip-message-push',
  --     'trip_message_push_url'
  --   );
  --   select vault.create_secret('<random-shared-secret>',
  --     'trip_message_push_webhook_secret');
  begin
    select decrypted_secret into v_push_url
    from vault.decrypted_secrets
    where name = 'trip_message_push_url'
    order by created_at desc
    limit 1;

    select decrypted_secret into v_webhook_secret
    from vault.decrypted_secrets
    where name = 'trip_message_push_webhook_secret'
    order by created_at desc
    limit 1;

    if coalesce(v_push_url, '') = '' or coalesce(v_webhook_secret, '') = '' then
      return new;
    end if;

    select net.http_post(
      url := v_push_url,
      body := jsonb_build_object('message_id', new.id),
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'X-Trip-Push-Secret', v_webhook_secret
      ),
      timeout_milliseconds := 5000
    ) into v_request_id;

    update public.trip_push_deliveries
    set dispatch_request_id = v_request_id,
        updated_at = now()
    where message_id = new.id;
  exception when others then
    -- Push infrastructure must never make a chat insert fail. Keep the row
    -- queued so an operator can safely redrive it after configuration repair.
    update public.trip_push_deliveries
    set error_code = 'dispatch_unavailable',
        updated_at = now()
    where message_id = new.id;
  end;

  return new;
end;
$$;

revoke all on function private.enqueue_trip_message_push()
  from public, anon, authenticated;

create trigger enqueue_trip_message_push_after_insert
  after insert on public.trip_messages
  for each row execute function private.enqueue_trip_message_push();
