-- P3 ops console: named actions (cancel / refund state machine / suspend /
-- reactivate / expire) and the RLS on booking_cancellations + refunds.
--
-- Every mutation function is service_role only; a direct-JWT caller is refused.
-- Reads are scope-gated: bookings:read sees cancellations, payments:read sees
-- refunds, other scopes see nothing.

begin;

create or replace function pg_temp.read_as(p_user uuid, p_sql text)
returns bigint language plpgsql as $$
declare v bigint;
begin
  set local role authenticated;
  perform set_config('request.jwt.claims',
    json_build_object('sub', p_user::text, 'role', 'authenticated')::text, true);
  begin execute p_sql into v; exception when others then v := 0; end;
  reset role;
  return coalesce(v, 0);
end $$;

do $$
declare
  v_reader uuid := 'e1000000-0000-4000-8000-000000000001';  -- bookings:read + payments:read
  v_hrev   uuid := 'e1000000-0000-4000-8000-000000000002';  -- hosts:review only
  v_actor  uuid := 'e1000000-0000-4000-8000-000000000003';  -- the staff actor (payments:act)
  v_buyer  uuid := '11111111-1111-4111-8111-000000000001';  -- seed traveler
  v_book   uuid := 'e1b00000-0000-4000-8000-000000000001';
  v_pay    uuid := 'e1c00000-0000-4000-8000-000000000001';
  v_cat uuid; v_region uuid; v_exp uuid; v_dep uuid;
  v_refund uuid;
  v_status text;
  v_raised boolean;
  v_cnt int;
begin
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  select id into v_cat from public.categories order by created_at limit 1;
  select id into v_region from public.regions order by created_at limit 1;

  insert into auth.users (id, instance_id, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role, aud)
  select u, '00000000-0000-0000-0000-000000000000', u::text || '@ops.test', 'x', now(),
    '{"provider":"email","providers":["email"]}', '{}', now(), now(), 'authenticated', 'authenticated'
  from unnest(array[v_reader, v_hrev, v_actor]) u
  on conflict (id) do nothing;

  insert into public.profiles (id, full_name, role)
  values (v_reader,'Ops Reader','traveler'), (v_hrev,'Ops HRev','traveler'),
         (v_actor,'Ops Actor','traveler')
  on conflict (id) do update set role = excluded.role;

  insert into public.staff_members (user_id, status, scopes)
  values
    (v_reader, 'active', array['bookings:read','payments:read']),
    (v_hrev,   'active', array['hosts:review']),
    (v_actor,  'active', array['payments:act','bookings:read','users:manage'])
  on conflict (user_id) do update set scopes = excluded.scopes;

  -- a published experience + open departure + a PAID booking + payment
  insert into public.experiences (id, host_id, category_id, region_id, title, slug,
    cover_image_url, price_paisa, status)
  values (gen_random_uuid(), v_buyer, v_cat, v_region, 'Ops Exp', 'ops-exp',
    'https://e.test/c.webp', 500000, 'published')
  returning id into v_exp;
  insert into public.experience_departures (id, experience_id, start_date, end_date,
    total_spots, spots_left, status)
  values (gen_random_uuid(), v_exp, current_date + 20, current_date + 24, 8, 7, 'open')
  returning id into v_dep;
  insert into public.bookings (id, booking_ref, user_id, experience_id, departure_id,
    adults, children, contact_name, contact_phone, subtotal_paisa, addons_paisa,
    fees_paisa, total_paisa, status)
  values (v_book, 'OPS-BK-0001', v_buyer, v_exp, v_dep, 1, 0, 'Buyer', '98000000',
    500000, 0, 25000, 525000, 'confirmed');
  insert into public.payments (id, booking_id, provider, provider_ref, idempotency_key,
    amount_paisa, status, paid_at)
  values (v_pay, v_book, 'khalti', 'pidx-ops-1', 'idem-ops-1', 525000, 'paid', now());

  ----------------------------------------------------------------------------
  -- 1. mutation functions are NOT callable via a direct JWT
  set local role authenticated;
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_actor, 'role', 'authenticated')::text, true);
  v_raised := false;
  begin
    perform public.admin_cancel_booking(v_book, v_actor, 'test');
  exception when others then v_raised := true;
  end;
  reset role;
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  if not v_raised then
    raise exception 'FAIL: admin_cancel_booking callable by a direct JWT';
  end if;

  ----------------------------------------------------------------------------
  -- 2. create a refund (service_role), state machine, payment flips to refunded
  v_refund := public.admin_create_refund(v_pay, v_actor, 525000, 'guest cancelled in time');
  if (select status from public.refunds where id = v_refund) <> 'pending'::public.refund_status then
    raise exception 'FAIL: new refund is not pending';
  end if;

  -- a refund that exceeds the refundable amount is refused
  v_raised := false;
  begin perform public.admin_create_refund(v_pay, v_actor, 1, 'overshoot');
  exception when others then v_raised := true; end;
  if not v_raised then raise exception 'FAIL: over-refund accepted'; end if;

  -- illegal transition pending -> succeeded
  v_raised := false;
  begin perform public.admin_settle_refund(v_refund, v_actor, 'succeeded'::public.refund_status);
  exception when others then v_raised := true; end;
  if not v_raised then raise exception 'FAIL: pending -> succeeded was allowed'; end if;

  -- pending -> processing -> succeeded, and the payment becomes refunded
  perform public.admin_settle_refund(v_refund, v_actor, 'processing'::public.refund_status);
  perform public.admin_settle_refund(v_refund, v_actor, 'succeeded'::public.refund_status,
    'gw-refund-1', jsonb_build_object('ok', true));
  if (select status from public.refunds where id = v_refund) <> 'succeeded'::public.refund_status
     or (select status from public.payments where id = v_pay) <> 'refunded'::public.payment_status then
    raise exception 'FAIL: refund settle did not complete or payment not marked refunded';
  end if;

  ----------------------------------------------------------------------------
  -- 3. cancel the booking, link the refund; reason mandatory
  v_raised := false;
  begin perform public.admin_cancel_booking(v_book, v_actor, '   ');
  exception when others then v_raised := true; end;
  if not v_raised then raise exception 'FAIL: blank cancellation reason accepted'; end if;

  perform public.admin_cancel_booking(v_book, v_actor, 'guest could not travel', v_refund);
  if (select status from public.bookings where id = v_book) <> 'cancelled'::public.booking_status then
    raise exception 'FAIL: booking not cancelled';
  end if;
  if not exists (
    select 1 from public.booking_cancellations
    where booking_id = v_book and refund_id = v_refund and actor_kind = 'staff'
      and reason = 'guest could not travel' and from_status = 'confirmed'::public.booking_status
  ) then
    raise exception 'FAIL: booking_cancellations row not written as expected';
  end if;
  -- a cancelled booking cannot be cancelled again
  v_raised := false;
  begin perform public.admin_cancel_booking(v_book, v_actor, 'again');
  exception when others then v_raised := true; end;
  if not v_raised then raise exception 'FAIL: re-cancelled an already cancelled booking'; end if;

  ----------------------------------------------------------------------------
  -- 4. suspend / reactivate a user; reason mandatory; not self
  v_raised := false;
  begin perform public.admin_suspend_user(v_actor, v_actor, 'self');
  exception when others then v_raised := true; end;
  if not v_raised then raise exception 'FAIL: allowed suspending your own account'; end if;

  perform public.admin_suspend_user(v_buyer, v_actor, 'chargeback abuse');
  if (select suspended_at is not null and suspended_reason = 'chargeback abuse'
      from public.profiles where id = v_buyer) is not true then
    raise exception 'FAIL: user not suspended';
  end if;
  perform public.admin_reactivate_user(v_buyer, v_actor);
  if (select suspended_at from public.profiles where id = v_buyer) is not null then
    raise exception 'FAIL: user not reactivated';
  end if;

  ----------------------------------------------------------------------------
  -- 5. expire stale pending bookings
  insert into public.bookings (booking_ref, user_id, experience_id, departure_id,
    adults, contact_name, contact_phone, subtotal_paisa, addons_paisa, fees_paisa,
    total_paisa, status, quote_expires_at)
  values ('OPS-BK-STALE', v_buyer, v_exp, v_dep, 1, 'B', '98', 100000, 0, 0, 100000,
    'pending', now() - interval '1 hour');
  v_cnt := public.expire_stale_pending_bookings();
  if v_cnt < 1 or exists (
    select 1 from public.bookings where booking_ref = 'OPS-BK-STALE' and status = 'pending') then
    raise exception 'FAIL: stale pending booking not expired (n=%)', v_cnt;
  end if;

  ----------------------------------------------------------------------------
  -- 6. RLS reads
  if pg_temp.read_as(v_reader, 'select count(*) from public.booking_cancellations') < 1 then
    raise exception 'FAIL: bookings:read cannot see cancellations';
  end if;
  if pg_temp.read_as(v_reader, 'select count(*) from public.refunds') < 1 then
    raise exception 'FAIL: payments:read cannot see refunds';
  end if;
  if pg_temp.read_as(v_hrev, 'select count(*) from public.booking_cancellations') <> 0 then
    raise exception 'FAIL: hosts:review can see cancellations';
  end if;
  if pg_temp.read_as(v_hrev, 'select count(*) from public.refunds') <> 0 then
    raise exception 'FAIL: hosts:review can see refunds';
  end if;

  raise notice 'OK: P3 ops actions enforce service-role + reason + state machine; reads scope-gated';
end $$;

rollback;
