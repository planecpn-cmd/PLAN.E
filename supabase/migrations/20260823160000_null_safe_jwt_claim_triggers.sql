-- Direct/background database sessions can expose request.jwt.claims as ''.

create or replace function public.prevent_profile_role_escalation()
returns trigger as $$
begin
  if old.role <> new.role and
      (coalesce(nullif(current_setting('request.jwt.claims', true), ''), '{}')::jsonb->>'role') <> 'service_role' then
    raise exception 'Permission denied: cannot alter profile role directly';
  end if;
  return new;
end;
$$ language plpgsql;

create or replace function public.prevent_client_booking_status_change()
returns trigger as $$
begin
  if old.status <> new.status and
      (coalesce(nullif(current_setting('request.jwt.claims', true), ''), '{}')::jsonb->>'role') <> 'service_role' then
    raise exception 'Permission denied: booking status updates are restricted to service role';
  end if;
  return new;
end;
$$ language plpgsql;

create or replace function public.prevent_client_payment_mutation()
returns trigger as $$
begin
  if (coalesce(nullif(current_setting('request.jwt.claims', true), ''), '{}')::jsonb->>'role') <> 'service_role' then
    raise exception 'Permission denied: payments table is service role only';
  end if;
  return new;
end;
$$ language plpgsql;

create or replace function public.prevent_client_host_app_status_change()
returns trigger as $$
begin
  if old.status <> new.status and
      (coalesce(nullif(current_setting('request.jwt.claims', true), ''), '{}')::jsonb->>'role') <> 'service_role' then
    raise exception 'Permission denied: host application status updates are restricted to service role';
  end if;
  return new;
end;
$$ language plpgsql;
