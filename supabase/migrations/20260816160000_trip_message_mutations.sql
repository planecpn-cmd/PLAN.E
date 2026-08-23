-- Phase 6C: append-only edit/deletion audit plus participant-safe projection.
-- Original trip_messages rows remain immutable and authoritative for audit.

create table public.trip_message_edits (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.trip_messages(id) on delete cascade,
  conversation_id uuid not null references public.bookings(id) on delete cascade,
  editor_id uuid not null references auth.users(id),
  previous_body text not null,
  new_body text not null,
  edited_at timestamptz not null default now()
);

create index idx_trip_message_edits_message_time
  on public.trip_message_edits(message_id, edited_at desc);

create table public.trip_message_deletions (
  message_id uuid primary key references public.trip_messages(id) on delete cascade,
  conversation_id uuid not null references public.bookings(id) on delete cascade,
  deleted_by uuid not null references auth.users(id),
  reason text not null default 'sender_deleted',
  deleted_at timestamptz not null default now()
);

create table public.trip_message_mutations (
  message_id uuid primary key references public.trip_messages(id) on delete cascade,
  conversation_id uuid not null references public.bookings(id) on delete cascade,
  effective_body text,
  edited_at timestamptz,
  deleted_at timestamptz,
  updated_at timestamptz not null default now(),
  check (
    (deleted_at is null and effective_body is not null)
    or (deleted_at is not null and effective_body is null)
  )
);

create index idx_trip_message_mutations_conversation
  on public.trip_message_mutations(conversation_id, updated_at desc);

alter table public.trip_message_edits enable row level security;
alter table public.trip_message_deletions enable row level security;
alter table public.trip_message_mutations enable row level security;

-- Audit tables are service/moderator-only. Conversation members receive only
-- the current projection, never revision history or actor identifiers.
revoke all on table public.trip_message_edits from public, anon, authenticated;
revoke all on table public.trip_message_deletions from public, anon, authenticated;
revoke all on table public.trip_message_mutations from public, anon, authenticated;

create policy "Trip members can read current message mutations"
  on public.trip_message_mutations for select to authenticated
  using (public.is_trip_member(conversation_id));

grant select on table public.trip_message_mutations to authenticated;

create or replace function public.edit_trip_message(
  p_message_id uuid,
  p_new_body text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_message public.trip_messages%rowtype;
  v_previous_body text;
  v_new_body text := btrim(p_new_body);
begin
  if v_user_id is null then raise exception 'Authentication required'; end if;
  if length(v_new_body) < 1 or length(v_new_body) > 2000 then
    raise exception 'Message must contain 1 to 2000 characters';
  end if;

  select * into v_message
  from public.trip_messages message
  where message.id = p_message_id
  for update;

  if not found or v_message.sender_id <> v_user_id or
      not public.is_trip_member(v_message.booking_id) then
    raise exception 'Only the sender can edit this message';
  end if;
  if exists (
    select 1 from public.trip_message_deletions deletion
    where deletion.message_id = p_message_id
  ) then
    raise exception 'Deleted messages cannot be edited';
  end if;

  select coalesce(mutation.effective_body, v_message.body)
    into v_previous_body
  from (select 1) seed
  left join public.trip_message_mutations mutation
    on mutation.message_id = p_message_id;

  if v_previous_body = v_new_body then return; end if;

  insert into public.trip_message_edits (
    message_id, conversation_id, editor_id, previous_body, new_body
  ) values (
    p_message_id, v_message.booking_id, v_user_id, v_previous_body, v_new_body
  );

  insert into public.trip_message_mutations (
    message_id, conversation_id, effective_body, edited_at, updated_at
  ) values (
    p_message_id, v_message.booking_id, v_new_body, now(), now()
  )
  on conflict (message_id) do update
  set effective_body = excluded.effective_body,
      edited_at = excluded.edited_at,
      updated_at = excluded.updated_at;
end;
$$;

create or replace function public.delete_trip_message(
  p_message_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_message public.trip_messages%rowtype;
begin
  if v_user_id is null then raise exception 'Authentication required'; end if;

  select * into v_message
  from public.trip_messages message
  where message.id = p_message_id
  for update;

  if not found or v_message.sender_id <> v_user_id or
      not public.is_trip_member(v_message.booking_id) then
    raise exception 'Only the sender can delete this message';
  end if;

  insert into public.trip_message_deletions (
    message_id, conversation_id, deleted_by
  ) values (
    p_message_id, v_message.booking_id, v_user_id
  ) on conflict (message_id) do nothing;

  insert into public.trip_message_mutations (
    message_id, conversation_id, effective_body, deleted_at, updated_at
  ) values (
    p_message_id, v_message.booking_id, null, now(), now()
  )
  on conflict (message_id) do update
  set effective_body = null,
      deleted_at = coalesce(
        public.trip_message_mutations.deleted_at,
        excluded.deleted_at
      ),
      updated_at = excluded.updated_at;
end;
$$;

revoke all on function public.edit_trip_message(uuid, text) from public;
revoke all on function public.delete_trip_message(uuid) from public;
grant execute on function public.edit_trip_message(uuid, text) to authenticated;
grant execute on function public.delete_trip_message(uuid) to authenticated;

do $$
begin
  alter publication supabase_realtime
    add table public.trip_message_mutations;
exception
  when duplicate_object then null;
end $$;
