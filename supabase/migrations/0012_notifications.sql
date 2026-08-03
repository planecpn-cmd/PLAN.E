-- Migration 0012: Notifications & Device Tokens
create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  type notif_type not null default 'system',
  title text not null,
  body text not null,
  entity_id uuid,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index idx_notifications_user on public.notifications(user_id, is_read, created_at desc);

create table public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  expo_push_token text unique not null,
  platform text,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index idx_device_tokens_user on public.device_tokens(user_id);
