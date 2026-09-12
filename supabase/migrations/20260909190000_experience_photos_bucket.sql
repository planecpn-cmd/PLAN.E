-- H1 photo slice (D2): private bucket for host-uploaded experience imagery.
--
-- Path convention: <host_id>/<experience_key>/<file>. Storage RLS keys on the
-- FIRST path segment = the uploader's uid, so an approved active host writes and
-- reads only under their own prefix. Admin review reads all via
-- has_scope('content:manage') -- never a bare is_admin() (P1 hole).
--
-- Server-enforced limits live on the bucket row: 5 MiB per object,
-- image/jpeg | image/png | image/webp only. Supabase Storage rejects anything
-- outside that before RLS is even consulted, so the client picker limits are
-- advisory only.
--
-- On approval the admin decision RPC (N1) copies the approved objects into the
-- public catalog-images bucket and rewrites experiences.cover_image_url /
-- gallery to the public URLs. Until then those columns hold the private path
-- here, resolved by the owning host and the reviewer via signed URL.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'experience-photos',
  'experience-photos',
  false,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- Upload: only an approved active host, only under their own uid prefix.
create policy "Hosts upload experience photos under their own prefix"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'experience-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
    and private.is_approved_active_host(auth.uid())
  );

-- Read: the owning host.
create policy "Hosts read their own experience photos"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'experience-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Read: admin reviewers with content:manage (scope model, not is_admin()).
create policy "Content managers read all experience photos"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'experience-photos'
    and public.has_scope('content:manage')
  );

-- Replace / remove: the owning host (wizard edit + delete).
create policy "Hosts replace their own experience photos"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'experience-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'experience-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Hosts delete their own experience photos"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'experience-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
