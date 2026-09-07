-- Map the broad host-questionnaire choices to the closest canonical category.
-- This also repairs applications submitted while the Edge Function queried the
-- removed/nonexistent `categories.name` column and silently stored NULL.
update public.host_applications app
set category_id = category.id,
    updated_at = now()
from public.categories category
where app.category_id is null
  and app.application_data ? 'hosting_type'
  and category.slug = case app.application_data->>'hosting_type'
    when 'adventure' then 'trekking'
    when 'experience' then 'culture'
    when 'stay' then 'homestay'
    when 'tour_package' then 'travel-package'
    when 'community_activity' then 'community-event'
    when 'other' then 'group-activity'
  end;
