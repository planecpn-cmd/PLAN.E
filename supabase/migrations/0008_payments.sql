-- Migration 0008: Payments
create table public.payments (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid unique not null references public.bookings(id) on delete cascade,
  provider payment_provider not null,
  provider_ref text,
  idempotency_key text unique not null,
  amount_paisa bigint not null check (amount_paisa > 0),
  status payment_status not null default 'initiated',
  raw_response jsonb default '{}'::jsonb,
  paid_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger set_payments_updated_at
  before update on public.payments
  for each row execute function public.set_updated_at();

-- Trigger preventing client role from mutating payments
create or replace function public.prevent_client_payment_mutation()
returns trigger as $$
begin
  if (current_setting('request.jwt.claims', true)::jsonb->>'role') <> 'service_role' then
    raise exception 'Permission denied: payments table is service role only';
  end if;
  return new;
end;
$$ language plpgsql;

create trigger check_payment_mutation
  before insert or update or delete on public.payments
  for each row execute function public.prevent_client_payment_mutation();
