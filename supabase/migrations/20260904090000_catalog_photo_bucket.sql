-- Public licensed stock photography only. No client upload policies are added.
insert into storage.buckets (id, name, public, allowed_mime_types)
values ('catalog-images', 'catalog-images', true, array['image/webp'])
on conflict (id) do nothing;
