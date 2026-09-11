-- Published property content is written by trusted moderation only. Hosts
-- change it through listing drafts/revisions; nightly inventory stays editable.
drop policy if exists accommodation_properties_host_write on public.accommodation_properties;

drop policy if exists accommodation_units_host_write on public.accommodation_units;

revoke insert, update, delete on public.accommodation_properties from authenticated;

revoke insert, update, delete on public.accommodation_units from authenticated;
