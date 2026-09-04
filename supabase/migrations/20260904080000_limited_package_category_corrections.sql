-- These verified multi-day treks were stored under hiking/culture, causing
-- category-driven detail presentation to select Full rather than Limited.
-- Match the known records and their previous state; do not classify by keywords
-- or reclassify unrelated/edited offerings.
update public.experiences as e
set category_id = trekking.id
from public.categories as trekking,
     public.categories as previous,
     (values
       ('60e62149-337e-48da-8c5c-b68086f87514'::uuid,
        'mardi-himal-trek', 'Mardi Himal High Ridge Trek', 120, 'hiking'),
       ('e20f0b5d-2031-4dd7-a524-fe183ca84158'::uuid,
        'upper-mustang-trek', 'Upper Mustang Forbidden Kingdom Trek', 288, 'culture')
     ) as correction(id, slug, title, duration_hours, previous_category)
where trekking.slug = 'trekking'
  and previous.slug = correction.previous_category
  and e.id = correction.id
  and e.slug = correction.slug
  and e.title = correction.title
  and e.duration_hours = correction.duration_hours
  and e.category_id = previous.id;
