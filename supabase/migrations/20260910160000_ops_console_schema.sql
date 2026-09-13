-- P3: ops console + cancellation/refund path + N5 user management.
--
-- Engine before the screen. Every mutation is a NAMED service-role function
-- (C3): the admin routes call these via withAdmin(<scope>) which writes the
-- admin_audit_log row. No client write policy anywhere here; no free-form edit.
--
-- Refund HALT: this migration builds the refunds table + state machine only.
-- No gateway call. A feature flag refund_gateway_live (default OFF) gates the
-- eventual Khalti/eSewa refund API call, which is NOT built here.

-- ── 10th scope: users:manage (suspend/reactivate any user account) ──────────
-- Founder question 7 (does "block" differ from "suspend"?) is unanswered and
-- not decidable from code -> one action, flagged in ADMIN_SCOPES.md.
alter table public.staff_members
  drop constraint staff_members_scopes_known;

alter table public.staff_members
  add constraint staff_members_scopes_known check (
    scopes <@ array[
      'hosts:review', 'hosts:decide',
      'bookings:read', 'payments:read', 'payments:act', 'finance:read',
      'content:manage', 'content:decide',
      'users:manage',
      'staff:manage'
    ]::text[]
  );

-- ── user (traveller) account suspension ────────────────────────────────────
alter table public.profiles
  add column suspended_at timestamptz,
  add column suspended_reason text;

-- ── cancellations ─────────────────────────────────────────────────────────
create table public.booking_cancellations (
  id           uuid primary key default gen_random_uuid(),
  booking_id   uuid not null references public.bookings(id) on delete restrict,
  actor_id     uuid references public.profiles(id),
  actor_kind   text not null check (actor_kind in ('staff', 'traveler', 'system')),
  reason       text not null check (btrim(reason) <> ''),
  refund_id    uuid,   -- FK added after refunds
  from_status  public.booking_status,
  created_at   timestamptz not null default now()
);
create index idx_booking_cancellations_booking on public.booking_cancellations (booking_id);

alter table public.booking_cancellations enable row level security;
revoke all on table public.booking_cancellations from anon, authenticated;
grant select on table public.booking_cancellations to authenticated;
create policy "Booking readers see cancellations"
  on public.booking_cancellations for select to authenticated
  using (public.has_scope('bookings:read'));

-- ── refunds ───────────────────────────────────────────────────────────────
create type public.refund_status as enum
  ('pending', 'processing', 'succeeded', 'failed', 'cancelled');

create table public.refunds (
  id                  uuid primary key default gen_random_uuid(),
  payment_id          uuid not null references public.payments(id) on delete restrict,
  booking_id          uuid not null references public.bookings(id) on delete restrict,
  amount_paisa        bigint not null check (amount_paisa > 0),
  status              public.refund_status not null default 'pending',
  reason              text not null check (btrim(reason) <> ''),
  requested_by        uuid references public.profiles(id),
  provider            public.payment_provider,
  provider_refund_ref text,
  gateway_response    jsonb,
  failure_reason      text,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);
create index idx_refunds_payment on public.refunds (payment_id);
create index idx_refunds_status on public.refunds (status) where status in ('pending', 'processing');

create trigger set_refunds_updated_at
  before update on public.refunds
  for each row execute function public.set_updated_at();

alter table public.refunds enable row level security;
revoke all on table public.refunds from anon, authenticated;
grant select on table public.refunds to authenticated;
create policy "Payment readers see refunds"
  on public.refunds for select to authenticated
  using (public.has_scope('payments:read'));

alter table public.booking_cancellations
  add constraint booking_cancellations_refund_fk
  foreign key (refund_id) references public.refunds(id) on delete set null;

-- ── refund gateway kill switch (default OFF — no live refund call) ─────────
insert into public.feature_flags (key, enabled, rollout_percent, platforms, description)
values (
  'refund_gateway_live', false, 100, array['ios', 'android', 'windows', 'web'],
  'When OFF, admin_settle_refund cannot move a refund past ''pending'' via a live gateway call. P3 ships OFF; the founder tests refunds in sandbox first.'
)
on conflict (key) do nothing;

-- ════════════════════════════════════════════════════════════════════════════
-- Named ops actions. All SECURITY DEFINER, service_role only. The admin route
-- (withAdmin(<scope>, {mutating})) is the only caller and writes the audit row.
-- ════════════════════════════════════════════════════════════════════════════

-- Re-verify is an edge function (needs the gateway lookup); it calls the
-- existing finalize_verified_payment. Not defined here.

-- ── cancel a booking ──────────────────────────────────────────────────────
create or replace function public.admin_cancel_booking(
  p_booking_id uuid,
  p_actor uuid,
  p_reason text,
  p_refund_id uuid default null
)
returns public.booking_status
language plpgsql security definer set search_path = ''
as $$
declare
  v_status public.booking_status;
begin
  if coalesce(btrim(p_reason), '') = '' then
    raise exception 'a cancellation reason is required' using errcode = '22023';
  end if;

  select status into v_status from public.bookings where id = p_booking_id for update;
  if not found then
    raise exception 'booking not found' using errcode = '42704';
  end if;
  if v_status not in ('pending'::public.booking_status,
                      'confirmed'::public.booking_status,
                      'cancellation_requested'::public.booking_status) then
    raise exception 'a % booking cannot be cancelled', v_status using errcode = '22023';
  end if;

  update public.bookings
    set status = 'cancelled'::public.booking_status,
        cancelled_at = now(), updated_at = now()
  where id = p_booking_id;

  insert into public.booking_cancellations
    (booking_id, actor_id, actor_kind, reason, refund_id, from_status)
  values (p_booking_id, p_actor, 'staff', btrim(p_reason), p_refund_id, v_status);

  return 'cancelled'::public.booking_status;
end;
$$;
revoke execute on function public.admin_cancel_booking(uuid, uuid, text, uuid)
  from public, anon, authenticated;

-- ── create a refund request (pending; no gateway call) ────────────────────
create or replace function public.admin_create_refund(
  p_payment_id uuid,
  p_actor uuid,
  p_amount_paisa bigint,
  p_reason text
)
returns uuid
language plpgsql security definer set search_path = ''
as $$
declare
  v_pay public.payments%rowtype;
  v_already bigint;
  v_id uuid;
begin
  if coalesce(btrim(p_reason), '') = '' then
    raise exception 'a refund reason is required' using errcode = '22023';
  end if;
  if p_amount_paisa is null or p_amount_paisa <= 0 then
    raise exception 'refund amount must be positive' using errcode = '22023';
  end if;

  select * into v_pay from public.payments where id = p_payment_id for update;
  if not found then
    raise exception 'payment not found' using errcode = '42704';
  end if;
  if v_pay.status <> 'paid'::public.payment_status then
    raise exception 'only a paid payment can be refunded (status is %)', v_pay.status
      using errcode = '22023';
  end if;

  select coalesce(sum(amount_paisa), 0) into v_already
  from public.refunds
  where payment_id = p_payment_id
    and status in ('pending'::public.refund_status,
                   'processing'::public.refund_status,
                   'succeeded'::public.refund_status);

  if v_already + p_amount_paisa > v_pay.amount_paisa then
    raise exception 'refund of % exceeds the % refundable on this payment',
      p_amount_paisa, v_pay.amount_paisa - v_already using errcode = '22023';
  end if;

  insert into public.refunds
    (payment_id, booking_id, amount_paisa, reason, requested_by, provider, status)
  values (p_payment_id, v_pay.booking_id, p_amount_paisa, btrim(p_reason),
          p_actor, v_pay.provider, 'pending'::public.refund_status)
  returning id into v_id;

  return v_id;
end;
$$;
revoke execute on function public.admin_create_refund(uuid, uuid, bigint, text)
  from public, anon, authenticated;

-- ── advance a refund through its state machine ───────────────────────────
--   pending    -> processing | cancelled
--   processing -> succeeded | failed
-- On the first fully-refunding 'succeeded', the payment flips to 'refunded'.
create or replace function public.admin_settle_refund(
  p_refund_id uuid,
  p_actor uuid,
  p_to_status public.refund_status,
  p_provider_ref text default null,
  p_gateway_response jsonb default null,
  p_failure_reason text default null
)
returns public.refund_status
language plpgsql security definer set search_path = ''
as $$
declare
  v_ref public.refunds%rowtype;
  v_total_succeeded bigint;
  v_pay_amount bigint;
begin
  select * into v_ref from public.refunds where id = p_refund_id for update;
  if not found then
    raise exception 'refund not found' using errcode = '42704';
  end if;

  if not (
    (v_ref.status = 'pending'    and p_to_status in ('processing', 'cancelled')) or
    (v_ref.status = 'processing' and p_to_status in ('succeeded', 'failed'))
  ) then
    raise exception 'illegal refund transition % -> %', v_ref.status, p_to_status
      using errcode = '22023';
  end if;

  if p_to_status = 'failed' and coalesce(btrim(p_failure_reason), '') = '' then
    raise exception 'a failure reason is required to fail a refund' using errcode = '22023';
  end if;

  update public.refunds set
    status = p_to_status,
    provider_refund_ref = coalesce(p_provider_ref, provider_refund_ref),
    gateway_response = coalesce(p_gateway_response, gateway_response),
    failure_reason = case when p_to_status = 'failed' then btrim(p_failure_reason) else failure_reason end,
    updated_at = now()
  where id = p_refund_id;

  if p_to_status = 'succeeded' then
    select coalesce(sum(amount_paisa), 0) into v_total_succeeded
    from public.refunds
    where payment_id = v_ref.payment_id and status = 'succeeded'::public.refund_status;
    select amount_paisa into v_pay_amount from public.payments where id = v_ref.payment_id;
    if v_total_succeeded >= v_pay_amount then
      update public.payments
        set status = 'refunded'::public.payment_status, updated_at = now()
      where id = v_ref.payment_id;
    end if;
  end if;

  return p_to_status;
end;
$$;
revoke execute on function
  public.admin_settle_refund(uuid, uuid, public.refund_status, text, jsonb, text)
  from public, anon, authenticated;

-- ── suspend / reactivate a user account (N5) ─────────────────────────────
create or replace function public.admin_suspend_user(
  p_user_id uuid,
  p_actor uuid,
  p_reason text
)
returns void
language plpgsql security definer set search_path = ''
as $$
begin
  if coalesce(btrim(p_reason), '') = '' then
    raise exception 'a suspension reason is required' using errcode = '22023';
  end if;
  if p_user_id = p_actor then
    raise exception 'you cannot suspend your own account' using errcode = '22023';
  end if;
  update public.profiles
    set suspended_at = coalesce(suspended_at, now()),
        suspended_reason = btrim(p_reason),
        updated_at = now()
  where id = p_user_id;
  if not found then
    raise exception 'user not found' using errcode = '42704';
  end if;
end;
$$;
revoke execute on function public.admin_suspend_user(uuid, uuid, text)
  from public, anon, authenticated;

create or replace function public.admin_reactivate_user(
  p_user_id uuid,
  p_actor uuid
)
returns void
language plpgsql security definer set search_path = ''
as $$
begin
  update public.profiles
    set suspended_at = null, suspended_reason = null, updated_at = now()
  where id = p_user_id;
  if not found then
    raise exception 'user not found' using errcode = '42704';
  end if;
end;
$$;
revoke execute on function public.admin_reactivate_user(uuid, uuid)
  from public, anon, authenticated;

-- ── pending-booking expiry (the dead 'expired' enum value) ───────────────
-- Called by a cron edge function (mirrors complete-trips-cron). Service-role.
create or replace function public.expire_stale_pending_bookings()
returns integer
language plpgsql security definer set search_path = ''
as $$
declare
  v_count integer;
begin
  with expired as (
    update public.bookings
      set status = 'expired'::public.booking_status, updated_at = now()
    where status = 'pending'::public.booking_status
      and quote_expires_at is not null
      and quote_expires_at < now()
    returning 1
  )
  select count(*) into v_count from expired;
  return v_count;
end;
$$;
revoke execute on function public.expire_stale_pending_bookings()
  from public, anon, authenticated;
