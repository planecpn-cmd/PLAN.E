-- Phase 4 messaging hardening: private Storage attachments and DB metadata.

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
) values (
  'trip-attachments',
  'trip-attachments',
  false,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
)
on conflict (id) do update set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create table public.trip_message_attachments (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.trip_messages(id) on delete cascade,
  storage_path text not null unique,
  mime_type text not null check (
    mime_type in ('image/jpeg', 'image/png', 'image/webp', 'application/pdf')
  ),
  size_bytes bigint not null check (size_bytes > 0 and size_bytes <= 10485760),
  created_at timestamptz not null default now()
);

create index idx_trip_message_attachments_message
  on public.trip_message_attachments(message_id);

alter table public.trip_message_attachments enable row level security;

create or replace function private.is_trip_member_by_booking(
  candidate_booking_id uuid,
  candidate_user_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select candidate_user_id is not null and exists (
    select 1
    from public.trip_conversations conversation
    join public.trip_conversation_members membership
      on membership.conversation_id = conversation.id
    where conversation.booking_id = candidate_booking_id
      and membership.user_id = candidate_user_id
  );
$$;

revoke all on function private.is_trip_member_by_booking(uuid, uuid)
  from public, anon;
grant execute on function private.is_trip_member_by_booking(uuid, uuid)
  to authenticated;

create policy "Trip members can read attachment metadata"
  on public.trip_message_attachments for select to authenticated
  using (
    exists (
      select 1
      from public.trip_messages message
      where message.id = message_id
        and private.is_trip_member_by_booking(message.booking_id, auth.uid())
    )
  );

revoke all on table public.trip_message_attachments from anon, authenticated;
grant select on table public.trip_message_attachments to authenticated;

create policy "Trip members can read private trip attachments"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'trip-attachments'
    and private.is_trip_member_by_booking(
      ((storage.foldername(name))[1])::uuid,
      auth.uid()
    )
  );

create policy "Trip members can upload private trip attachments"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'trip-attachments'
    and (storage.foldername(name))[2] = auth.uid()::text
    and private.is_trip_member_by_booking(
      ((storage.foldername(name))[1])::uuid,
      auth.uid()
    )
  );

create policy "Uploaders can remove their private trip attachments"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'trip-attachments'
    and (storage.foldername(name))[2] = auth.uid()::text
    and private.is_trip_member_by_booking(
      ((storage.foldername(name))[1])::uuid,
      auth.uid()
    )
  );

-- Metadata registration is server-validated and idempotent. Direct client
-- inserts remain default-denied even though the table has RLS enabled.
create or replace function public.register_trip_message_attachment(
  p_message_id uuid,
  p_storage_path text,
  p_mime_type text,
  p_size_bytes bigint
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_booking_id uuid;
  v_sender_id uuid;
begin
  select message.booking_id, message.sender_id
    into v_booking_id, v_sender_id
  from public.trip_messages message
  where message.id = p_message_id;

  if v_booking_id is null
      or v_sender_id <> auth.uid()
      or not private.is_trip_member_by_booking(v_booking_id, auth.uid()) then
    raise exception 'Trip attachment access denied';
  end if;
  if p_storage_path not like
      v_booking_id::text || '/' || auth.uid()::text || '/%' then
    raise exception 'Invalid trip attachment path';
  end if;
  if p_mime_type not in (
      'image/jpeg', 'image/png', 'image/webp', 'application/pdf'
    ) or p_size_bytes < 1 or p_size_bytes > 10485760 then
    raise exception 'Invalid trip attachment type or size';
  end if;
  if not exists (
    select 1
    from storage.objects object
    where object.bucket_id = 'trip-attachments'
      and object.name = p_storage_path
  ) then
    raise exception 'Trip attachment object does not exist';
  end if;

  insert into public.trip_message_attachments (
    message_id,
    storage_path,
    mime_type,
    size_bytes
  ) values (
    p_message_id,
    p_storage_path,
    p_mime_type,
    p_size_bytes
  )
  on conflict (storage_path) do nothing;
end;
$$;

revoke all on function public.register_trip_message_attachment(
  uuid, text, text, bigint
) from public, anon;
grant execute on function public.register_trip_message_attachment(
  uuid, text, text, bigint
) to authenticated;
