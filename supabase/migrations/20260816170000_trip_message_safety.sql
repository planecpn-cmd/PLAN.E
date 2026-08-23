-- Phase 6D: reporting, participant blocking, and admin moderation.

create table public.trip_message_reports (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.trip_messages(id) on delete cascade,
  conversation_id uuid not null references public.bookings(id) on delete cascade,
  reporter_id uuid not null references auth.users(id),
  reported_user_id uuid not null references auth.users(id),
  reason text not null check (
    reason in ('harassment', 'spam', 'scam', 'unsafe', 'hate', 'other')
  ),
  details text,
  status text not null default 'open'
    check (status in ('open', 'reviewing', 'resolved', 'dismissed')),
  reviewed_by uuid references auth.users(id),
  reviewed_at timestamptz,
  resolution_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (message_id, reporter_id)
);

create index idx_trip_message_reports_moderation
  on public.trip_message_reports(status, created_at);

create table public.trip_user_blocks (
  blocker_id uuid not null references auth.users(id) on delete cascade,
  blocked_id uuid not null references auth.users(id) on delete cascade,
  conversation_id uuid not null references public.bookings(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);

create index idx_trip_user_blocks_blocked
  on public.trip_user_blocks(blocked_id, blocker_id);

alter table public.trip_message_reports enable row level security;
alter table public.trip_user_blocks enable row level security;

create policy "Reporters can read their own message reports"
  on public.trip_message_reports for select to authenticated
  using (reporter_id = auth.uid());

create policy "Admins can read all message reports"
  on public.trip_message_reports for select to authenticated
  using (public.is_admin());

create policy "Blockers can read their own block list"
  on public.trip_user_blocks for select to authenticated
  using (blocker_id = auth.uid());

revoke all on table public.trip_message_reports from public, anon, authenticated;
revoke all on table public.trip_user_blocks from public, anon, authenticated;
grant select on table public.trip_message_reports to authenticated;
grant select on table public.trip_user_blocks to authenticated;

create or replace function private.is_trip_member_user(
  candidate_booking_id uuid,
  candidate_user_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select candidate_user_id is not null and (
    exists (
      select 1
      from public.bookings booking
      left join public.experiences experience
        on experience.id = booking.experience_id
      where booking.id = candidate_booking_id
        and candidate_user_id in (booking.user_id, experience.host_id)
    )
    or exists (
      select 1
      from public.trip_conversations conversation
      join public.trip_conversation_members membership
        on membership.conversation_id = conversation.id
      where conversation.booking_id = candidate_booking_id
        and membership.user_id = candidate_user_id
    )
  );
$$;

create or replace function private.trip_messaging_is_blocked(
  candidate_booking_id uuid,
  candidate_user_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.trip_user_blocks block
    where block.conversation_id = candidate_booking_id
      and (
        block.blocker_id = candidate_user_id
        or block.blocked_id = candidate_user_id
      )
  );
$$;

revoke all on function private.is_trip_member_user(uuid, uuid)
  from public, anon;
revoke all on function private.trip_messaging_is_blocked(uuid, uuid)
  from public, anon;
grant execute on function private.is_trip_member_user(uuid, uuid)
  to authenticated;
grant execute on function private.trip_messaging_is_blocked(uuid, uuid)
  to authenticated;

create or replace function public.report_trip_message(
  p_message_id uuid,
  p_reason text,
  p_details text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_message public.trip_messages%rowtype;
  v_report_id uuid;
  v_reason text := lower(btrim(p_reason));
  v_details text := nullif(btrim(p_details), '');
begin
  if v_user_id is null then raise exception 'Authentication required'; end if;
  if v_reason not in ('harassment', 'spam', 'scam', 'unsafe', 'hate', 'other') then
    raise exception 'Invalid report reason';
  end if;
  if length(coalesce(v_details, '')) > 1000 then
    raise exception 'Report details are too long';
  end if;

  select * into v_message
  from public.trip_messages message
  where message.id = p_message_id;
  if not found or not private.is_trip_member_user(
    v_message.booking_id, v_user_id
  ) or v_message.sender_id = v_user_id then
    raise exception 'Only another conversation participant can report this message';
  end if;

  insert into public.trip_message_reports (
    message_id, conversation_id, reporter_id, reported_user_id, reason, details
  ) values (
    p_message_id, v_message.booking_id, v_user_id, v_message.sender_id,
    v_reason, v_details
  )
  on conflict (message_id, reporter_id) do update
  set reason = excluded.reason,
      details = excluded.details,
      status = 'open',
      reviewed_by = null,
      reviewed_at = null,
      resolution_notes = null,
      updated_at = now()
  returning id into v_report_id;
  return v_report_id;
end;
$$;

create or replace function public.block_trip_participant(
  p_conversation_id uuid,
  p_blocked_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null or v_user_id = p_blocked_user_id or
      not private.is_trip_member_user(p_conversation_id, v_user_id) or
      not private.is_trip_member_user(p_conversation_id, p_blocked_user_id) then
    raise exception 'Block target must be another conversation participant';
  end if;
  insert into public.trip_user_blocks (
    blocker_id, blocked_id, conversation_id
  ) values (
    v_user_id, p_blocked_user_id, p_conversation_id
  )
  on conflict (blocker_id, blocked_id) do update
  set conversation_id = excluded.conversation_id,
      created_at = now();
end;
$$;

create or replace function public.unblock_trip_participant(
  p_blocked_user_id uuid
)
returns void
language sql
security definer
set search_path = ''
as $$
  delete from public.trip_user_blocks
  where blocker_id = auth.uid()
    and blocked_id = p_blocked_user_id;
$$;

create or replace function public.get_trip_conversation_safety(
  p_conversation_id uuid
)
returns table (
  blocked_by_me boolean,
  blocked_me boolean,
  can_message boolean
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null or
      not private.is_trip_member_user(p_conversation_id, v_user_id) then
    raise exception 'Trip conversation access denied';
  end if;
  return query
  select
    exists (
      select 1 from public.trip_user_blocks block
      where block.conversation_id = p_conversation_id
        and block.blocker_id = v_user_id
    ),
    exists (
      select 1 from public.trip_user_blocks block
      where block.conversation_id = p_conversation_id
        and block.blocked_id = v_user_id
    ),
    not private.trip_messaging_is_blocked(p_conversation_id, v_user_id);
end;
$$;

revoke all on function public.report_trip_message(uuid, text, text) from public;
revoke all on function public.block_trip_participant(uuid, uuid) from public;
revoke all on function public.unblock_trip_participant(uuid) from public;
revoke all on function public.get_trip_conversation_safety(uuid) from public;
grant execute on function public.report_trip_message(uuid, text, text)
  to authenticated;
grant execute on function public.block_trip_participant(uuid, uuid)
  to authenticated;
grant execute on function public.unblock_trip_participant(uuid)
  to authenticated;
grant execute on function public.get_trip_conversation_safety(uuid)
  to authenticated;

-- Existing retry/idempotency semantics remain, with one additional pairwise
-- block check before RLS-authorized insertion.
create or replace function public.send_trip_message(
  p_booking_id uuid,
  p_client_message_id uuid,
  p_body text,
  p_attachment_url text default null
)
returns setof public.trip_messages
language plpgsql
security invoker
set search_path = public
as $$
begin
  if length(btrim(p_body)) < 1 or length(btrim(p_body)) > 2000 then
    raise exception 'Message must contain 1 to 2000 characters';
  end if;
  if private.trip_messaging_is_blocked(p_booking_id, auth.uid()) then
    raise exception 'Messaging is unavailable for this conversation';
  end if;

  return query
  insert into public.trip_messages (
    id, booking_id, sender_id, body, attachment_url, client_message_id
  ) values (
    p_client_message_id, p_booking_id, auth.uid(), btrim(p_body),
    p_attachment_url, p_client_message_id
  )
  on conflict (client_message_id) do nothing
  returning *;

  if not found then
    return query
    select message.*
    from public.trip_messages message
    where message.client_message_id = p_client_message_id
      and message.booking_id = p_booking_id
      and message.sender_id = auth.uid();
  end if;
end;
$$;

revoke all on function public.send_trip_message(uuid, uuid, text, text)
  from public;
grant execute on function public.send_trip_message(uuid, uuid, text, text)
  to authenticated;

-- Admins can inspect immutable evidence and resolve reports. Ordinary users
-- still have no grants on either audit table.
create policy "Admins can read message edit audit"
  on public.trip_message_edits for select to authenticated
  using (public.is_admin());
create policy "Admins can read message deletion audit"
  on public.trip_message_deletions for select to authenticated
  using (public.is_admin());
grant select on table public.trip_message_edits to authenticated;
grant select on table public.trip_message_deletions to authenticated;

create or replace function public.get_trip_moderation_queue()
returns table (
  report_id uuid,
  report_status text,
  reason text,
  details text,
  created_at timestamptz,
  message_id uuid,
  conversation_id uuid,
  reporter_id uuid,
  reported_user_id uuid,
  original_body text,
  effective_body text,
  deleted_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.is_admin() then raise exception 'Admin access required'; end if;
  return query
  select
    report.id,
    report.status,
    report.reason,
    report.details,
    report.created_at,
    report.message_id,
    report.conversation_id,
    report.reporter_id,
    report.reported_user_id,
    message.body,
    coalesce(mutation.effective_body, message.body),
    mutation.deleted_at
  from public.trip_message_reports report
  join public.trip_messages message on message.id = report.message_id
  left join public.trip_message_mutations mutation
    on mutation.message_id = report.message_id
  order by
    case report.status when 'open' then 0 when 'reviewing' then 1 else 2 end,
    report.created_at;
end;
$$;

create or replace function public.review_trip_message_report(
  p_report_id uuid,
  p_status text,
  p_resolution_notes text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_admin() then raise exception 'Admin access required'; end if;
  if p_status not in ('reviewing', 'resolved', 'dismissed') then
    raise exception 'Invalid moderation status';
  end if;
  if length(coalesce(p_resolution_notes, '')) > 2000 then
    raise exception 'Resolution notes are too long';
  end if;
  update public.trip_message_reports
  set status = p_status,
      reviewed_by = auth.uid(),
      reviewed_at = now(),
      resolution_notes = nullif(btrim(p_resolution_notes), ''),
      updated_at = now()
  where id = p_report_id;
  if not found then raise exception 'Report not found'; end if;
end;
$$;

revoke all on function public.get_trip_moderation_queue() from public;
revoke all on function public.review_trip_message_report(uuid, text, text)
  from public;
grant execute on function public.get_trip_moderation_queue() to authenticated;
grant execute on function public.review_trip_message_report(uuid, text, text)
  to authenticated;
