-- Migration 0016: Explicit Table and Sequence Grants for anon and authenticated roles

grant usage on schema public to anon, authenticated;

-- Grant table permissions (RLS policies will control actual row access)
grant select on all tables in schema public to anon, authenticated;
grant insert, update, delete on all tables in schema public to authenticated;

-- Grant sequence permissions for auto-increment / serial columns
grant usage, select on all sequences in schema public to anon, authenticated;

-- Ensure future tables inherit default grants
alter default privileges in schema public grant select on tables to anon, authenticated;
alter default privileges in schema public grant insert, update, delete on tables to authenticated;
alter default privileges in schema public grant usage, select on sequences to anon, authenticated;
