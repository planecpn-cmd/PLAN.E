-- Approved hosts may read payment facts only for bookings belonging to their
-- own experiences. Raw gateway responses and idempotency keys stay private.
create or replace function public.host_booking_payment_transactions()
returns table (
  payment_id uuid,
  booking_id uuid,
  provider text,
  provider_ref text,
  amount_paisa bigint,
  payment_status text,
  paid_at timestamptz,
  created_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    payment.id,
    payment.booking_id,
    payment.provider::text,
    payment.provider_ref,
    payment.amount_paisa,
    payment.status::text,
    payment.paid_at,
    payment.created_at
  from public.payments payment
  join public.bookings booking on booking.id = payment.booking_id
  join public.experiences experience on experience.id = booking.experience_id
  where experience.host_id = auth.uid()
    and private.is_approved_active_host(auth.uid())
  order by payment.created_at desc;
$$;

revoke all on function public.host_booking_payment_transactions()
  from public, anon;
grant execute on function public.host_booking_payment_transactions()
  to authenticated;
