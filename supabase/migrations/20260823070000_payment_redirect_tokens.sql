-- One-time capability tokens for public payment-provider browser redirects.
-- Raw tokens never enter the database; only their SHA-256 hashes are stored.
create table public.payment_redirect_tokens (
  token_hash text primary key,
  payment_id uuid not null unique references public.payments(id) on delete cascade,
  booking_id uuid not null references public.bookings(id) on delete cascade,
  expires_at timestamptz not null,
  consumed_at timestamptz,
  created_at timestamptz not null default now(),
  constraint payment_redirect_tokens_hash_length check (length(token_hash) = 64),
  constraint payment_redirect_tokens_expiry check (expires_at > created_at)
);

alter table public.payment_redirect_tokens enable row level security;

-- Default deny for API clients. Edge Functions use the service role only after
-- authenticating the user or validating the one-time capability token.
revoke all on table public.payment_redirect_tokens from public, anon, authenticated;
grant all on table public.payment_redirect_tokens to service_role;

create or replace function public.consume_payment_redirect_token(p_token_hash text)
returns table (booking_id uuid, payment_id uuid)
language sql
security definer
set search_path = ''
as $$
  update public.payment_redirect_tokens as token
  set consumed_at = now()
  where token.token_hash = p_token_hash
    and token.consumed_at is null
    and token.expires_at > now()
  returning token.booking_id, token.payment_id;
$$;

revoke all on function public.consume_payment_redirect_token(text) from public, anon, authenticated;
grant execute on function public.consume_payment_redirect_token(text) to service_role;
