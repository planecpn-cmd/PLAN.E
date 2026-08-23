insert into public.remote_content (slot, schema_version, payload)
values (
  'onboarding_slides',
  1,
  jsonb_build_array(
    jsonb_build_object(
      'title', 'Explore Nepal Differently',
      'description', 'Discover trips, food, culture, adventure, and experiences across Nepal.'
    ),
    jsonb_build_object(
      'title', 'Find Your Kind of Experience',
      'description', 'Adventure, relax, learn something new, meet people, or live like a local.'
    ),
    jsonb_build_object(
      'title', 'Make Your Time Meaningful',
      'description', 'Join local hosts, communities, and experiences you will actually remember.'
    )
  )
)
on conflict (slot) do update
set schema_version = excluded.schema_version,
    payload = excluded.payload,
    updated_at = now();
