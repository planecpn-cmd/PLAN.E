-- Emergency server-side switch for the paid Gemini itinerary endpoint.

insert into public.feature_flags (
  key,
  enabled,
  rollout_percent,
  platforms,
  description
)
values (
  'ai_itinerary',
  true,
  100,
  array['ios', 'android', 'windows', 'web'],
  'Server-authoritative AI itinerary availability.'
)
on conflict (key) do nothing;
