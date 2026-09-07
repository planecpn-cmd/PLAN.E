-- PostgreSQL requires a newly-added enum value to be committed before use.
alter type public.host_app_status add value if not exists 'action_required';
