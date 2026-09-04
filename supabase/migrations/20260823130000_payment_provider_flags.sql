-- Payment availability is a server-owned decision, not a Flutter-only flag.

insert into public.feature_flags (
  key,
  enabled,
  rollout_percent,
  platforms,
  description
)
values
  (
    'payment_khalti',
    true,
    100,
    array['ios', 'android', 'windows', 'web'],
    'Server-authoritative Khalti payment availability.'
  ),
  (
    'payment_esewa',
    true,
    100,
    array['ios', 'android', 'windows', 'web'],
    'Server-authoritative eSewa payment availability.'
  )
on conflict (key) do nothing;
