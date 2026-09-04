-- Keep server-owned prices and payment totals bounded and internally consistent.

alter table public.experiences
  add constraint experiences_price_paisa_max
    check (price_paisa <= 10000000000),
  add constraint experiences_child_price_paisa_max
    check (child_price_paisa is null or child_price_paisa <= 10000000000);

alter table public.experience_departures
  add constraint experience_departures_price_override_paisa_max
    check (price_override_paisa is null or price_override_paisa <= 10000000000);

alter table public.bookings
  add constraint bookings_subtotal_paisa_max
    check (subtotal_paisa <= 210000000000),
  add constraint bookings_addons_paisa_max
    check (addons_paisa <= 210000000000),
  add constraint bookings_fees_paisa_max
    check (fees_paisa <= 210000000000),
  add constraint bookings_total_paisa_max
    check (total_paisa <= 210000000000),
  add constraint bookings_total_paisa_consistent
    check (total_paisa = subtotal_paisa + addons_paisa + fees_paisa);

alter table public.payments
  add constraint payments_amount_paisa_max
    check (amount_paisa <= 210000000000);
