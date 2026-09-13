-- P1 Step 3 — the staff/scope model and the admin audit trail (plan §2.3, §2.4).
--
-- staff_members is the FINE authorization gate, enforced in the admin backend
-- by withAdmin(). profiles.role = 'admin' stays the COARSE gate that the
-- is_admin() RLS policies use. There is no client write path to either table in
-- this phase: the founder bootstrap migration seeds staff_members, and every
-- later change goes through the service-role backend under a staff:manage scope.

create type public.staff_status as enum ('active', 'suspended');

-- The full set of scopes. Mirrored by the TypeScript Scope union in the admin
-- app; adding a scope must change both. The CHECK rejects unknown scopes at the
-- database level.
create table public.staff_members (
  user_id          uuid primary key references public.profiles(id) on delete restrict,
  status           public.staff_status not null default 'active',
  scopes           text[] not null default '{}',
  created_by       uuid references public.profiles(id),
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  suspended_at     timestamptz,
  suspended_reason text,
  constraint staff_members_scopes_known check (
    scopes <@ array[
      'hosts:review',
      'hosts:decide',
      'bookings:read',
      'payments:read',
      'payments:act',
      'finance:read',
      'content:manage',
      'staff:manage'
    ]::text[]
  ),
  constraint staff_members_suspension_consistent check (
    (status = 'active' and suspended_at is null)
    or (status = 'suspended')
  )
);

create trigger set_staff_members_updated_at
  before update on public.staff_members
  for each row execute function public.set_updated_at();

create table public.admin_audit_log (
  id                   uuid primary key default gen_random_uuid(),
  actor_user_id        uuid not null,
  actor_email_snapshot text,
  scope_used           text,
  action               text not null,
  entity_type          text,
  entity_id            text,
  before               jsonb,
  after                jsonb,
  reason               text,
  ip                   inet,
  user_agent           text,
  request_id           text,
  created_at           timestamptz not null default now()
);

create index idx_admin_audit_log_created_at on public.admin_audit_log (created_at desc);
create index idx_admin_audit_log_actor on public.admin_audit_log (actor_user_id);
create index idx_admin_audit_log_entity on public.admin_audit_log (entity_type, entity_id);

alter table public.staff_members enable row level security;
alter table public.admin_audit_log enable row level security;

-- Least privilege: no anon/authenticated grants beyond the is_admin()-gated
-- read. (alter default privileges already strips new-table grants for
-- anon/authenticated, see 20260823100000 — the revokes below are belt-and-braces
-- and also cover service_role.)
revoke all privileges on table public.staff_members from anon, authenticated;
revoke all privileges on table public.admin_audit_log from anon, authenticated;

grant select on table public.staff_members to authenticated;
grant select on table public.admin_audit_log to authenticated;

create policy "Admins can read staff members"
  on public.staff_members for select to authenticated
  using (public.is_admin());

create policy "Admins can read the admin audit log"
  on public.admin_audit_log for select to authenticated
  using (public.is_admin());

-- Append-only means append-only, including for the backend. service_role keeps
-- INSERT + SELECT; it must never rewrite or delete an audit row.
revoke update, delete on table public.admin_audit_log from service_role;
