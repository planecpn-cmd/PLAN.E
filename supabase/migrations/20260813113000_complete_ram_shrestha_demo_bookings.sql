-- DEVELOPMENT / DEMONSTRATION DATA ONLY.
--
-- Completes the deterministic Host Mode seed with booking/message records.
-- The original seed deliberately avoided inventing an auth identity; this
-- migration reuses one existing non-host test profile from the linked project.

do $$
declare
  v_host_id constant uuid := '25ffe805-82b2-4a43-9fc1-203b080e197b';
  v_traveler_id uuid;
begin
  perform set_config(
    'request.jwt.claims',
    '{"role":"service_role"}',
    true
  );

  select p.id into v_traveler_id
  from public.profiles p
  where p.id <> v_host_id
  order by
    case when p.role = 'traveler'::public.user_role then 0 else 1 end,
    p.created_at
  limit 1;

  -- This linked project currently has a single profile. Keep the foreign key
  -- tied to a real authenticated identity instead of inventing an auth user;
  -- the contact/participant rows remain clearly named demo travelers.
  v_traveler_id := coalesce(v_traveler_id, v_host_id);

  insert into public.bookings (
    id, booking_ref, user_id, experience_id, departure_id, adults, children,
    contact_name, contact_phone, subtotal_paisa, addons_paisa, fees_paisa,
    total_paisa, status, is_draft, created_at
  ) values
  (
    'b1000000-0000-4000-8000-000000000001', 'DEMO-RAM-REQUEST',
    v_traveler_id, 'e1000000-0000-4000-8000-000000000001',
    'd1000000-0000-4000-8000-000000000001', 2, 0,
    'Aarav Gurung', '9800000001', 2500000, 0, 0, 2500000,
    'pending'::public.booking_status, false, now() - interval '2 hours'
  ),
  (
    'b1000000-0000-4000-8000-000000000002', 'DEMO-RAM-CONFIRMED',
    v_traveler_id, 'e1000000-0000-4000-8000-000000000001',
    'd1000000-0000-4000-8000-000000000001', 4, 0,
    'Sita Rai', '9800000002', 5000000, 0, 0, 5000000,
    'confirmed'::public.booking_status, false, now() - interval '3 days'
  )
  on conflict (id) do update set
    user_id = excluded.user_id,
    experience_id = excluded.experience_id,
    departure_id = excluded.departure_id,
    adults = excluded.adults,
    children = excluded.children,
    contact_name = excluded.contact_name,
    contact_phone = excluded.contact_phone,
    subtotal_paisa = excluded.subtotal_paisa,
    total_paisa = excluded.total_paisa,
    status = excluded.status,
    is_draft = false,
    updated_at = now();

  insert into public.booking_participants (
    id, booking_id, full_name, age, is_lead
  ) values
    ('c1000000-0000-4000-8000-000000000001', 'b1000000-0000-4000-8000-000000000001', 'Aarav Gurung', 29, true),
    ('c1000000-0000-4000-8000-000000000002', 'b1000000-0000-4000-8000-000000000001', 'Maya Gurung', 27, false),
    ('c1000000-0000-4000-8000-000000000003', 'b1000000-0000-4000-8000-000000000002', 'Sita Rai', 32, true),
    ('c1000000-0000-4000-8000-000000000004', 'b1000000-0000-4000-8000-000000000002', 'Nima Rai', 34, false),
    ('c1000000-0000-4000-8000-000000000005', 'b1000000-0000-4000-8000-000000000002', 'Pema Rai', 30, false),
    ('c1000000-0000-4000-8000-000000000006', 'b1000000-0000-4000-8000-000000000002', 'Dawa Rai', 36, false)
  on conflict (id) do update set
    full_name = excluded.full_name,
    age = excluded.age,
    is_lead = excluded.is_lead;

  insert into public.trip_messages (
    id, booking_id, sender_id, body, created_at
  ) values
    ('a2000000-0000-4000-8000-000000000001', 'b1000000-0000-4000-8000-000000000001', v_traveler_id, 'Namaste! Is a sleeping bag included?', now() - interval '90 minutes'),
    ('a2000000-0000-4000-8000-000000000002', 'b1000000-0000-4000-8000-000000000001', v_host_id, 'Namaste! Yes, it is included in this demo departure.', now() - interval '75 minutes'),
    ('a2000000-0000-4000-8000-000000000003', 'b1000000-0000-4000-8000-000000000002', v_host_id, 'Welcome to the Mardi Himal departure group!', now() - interval '4 days')
  on conflict (id) do update set
    body = excluded.body,
    created_at = excluded.created_at;
end;
$$;
