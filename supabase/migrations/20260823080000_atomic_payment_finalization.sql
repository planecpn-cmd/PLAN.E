-- Finalize a verified payment and every dependent booking mutation in one
-- transaction. The payment row lock makes retries idempotent.
create unique index if not exists idx_payments_provider_ref_unique
  on public.payments (provider, provider_ref)
  where provider_ref is not null;

create or replace function public.finalize_verified_payment(
  p_booking_id uuid,
  p_payment_id uuid,
  p_provider public.payment_provider,
  p_provider_ref text,
  p_gateway_response jsonb default '{}'::jsonb
)
returns table (
  result_booking_id uuid,
  result_booking_ref text,
  result_booking_status public.booking_status,
  result_payment_status public.payment_status,
  already_processed boolean
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_payment public.payments%rowtype;
  v_booking public.bookings%rowtype;
  v_gear_list text[];
  v_updated integer;
begin
  if p_provider_ref is null or btrim(p_provider_ref) = '' then
    raise exception 'invalid payment reference';
  end if;

  select * into v_payment
  from public.payments
  where id = p_payment_id and booking_id = p_booking_id
  for update;

  select * into v_booking
  from public.bookings
  where id = p_booking_id
  for update;

  if v_payment.id is null or v_booking.id is null then
    raise exception 'booking or payment not found';
  end if;
  if v_payment.provider <> p_provider or v_payment.amount_paisa <> v_booking.total_paisa then
    raise exception 'payment binding mismatch';
  end if;

  if v_payment.status = 'paid' then
    if v_booking.status <> 'confirmed' or v_payment.provider_ref is distinct from p_provider_ref then
      raise exception 'inconsistent finalized payment';
    end if;

    return query select
      v_booking.id,
      v_booking.booking_ref,
      v_booking.status,
      v_payment.status,
      true;
    return;
  end if;

  if v_payment.status not in ('initiated', 'failed') or v_booking.status <> 'pending' then
    raise exception 'payment cannot be finalized';
  end if;
  if v_booking.quote_expires_at is null or v_booking.quote_expires_at <= now() then
    raise exception 'booking quote expired';
  end if;

  update public.experience_departures
  set spots_left = spots_left - (v_booking.adults + v_booking.children)
  where id = v_booking.departure_id
    and spots_left >= (v_booking.adults + v_booking.children);
  get diagnostics v_updated = row_count;
  if v_updated <> 1 then
    raise exception 'not enough departure capacity';
  end if;

  update public.payments
  set status = 'paid',
      provider_ref = p_provider_ref,
      raw_response = coalesce(raw_response, '{}'::jsonb) || coalesce(p_gateway_response, '{}'::jsonb),
      paid_at = now(),
      updated_at = now()
  where id = v_payment.id;

  update public.bookings
  set status = 'confirmed', updated_at = now()
  where id = v_booking.id;

  insert into public.booking_participants (booking_id, full_name, is_lead)
  select v_booking.id, v_booking.contact_name, true
  where not exists (
    select 1 from public.booking_participants
    where booking_id = v_booking.id and is_lead
  );

  select coalesce(bring_list, '{}'::text[])
  into v_gear_list
  from public.experiences
  where id = v_booking.experience_id;

  if cardinality(v_gear_list) = 0 then
    v_gear_list := array[
      'Comfortable footwear',
      'Water bottle',
      'Weather-appropriate clothing',
      'Personal medication'
    ];
  end if;

  insert into public.gear_checklist_items (
    booking_id, label, is_checked, is_custom, sort_order
  )
  select v_booking.id, item.label, false, false, (item.position - 1)::integer
  from unnest(v_gear_list) with ordinality as item(label, position)
  where not exists (
    select 1 from public.gear_checklist_items where booking_id = v_booking.id
  );

  return query select
    v_booking.id,
    v_booking.booking_ref,
    'confirmed'::public.booking_status,
    'paid'::public.payment_status,
    false;
end;
$$;

revoke all on function public.finalize_verified_payment(
  uuid, uuid, public.payment_provider, text, jsonb
) from public, anon, authenticated;
grant execute on function public.finalize_verified_payment(
  uuid, uuid, public.payment_provider, text, jsonb
) to service_role;
