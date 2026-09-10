-- Let hosts save an experience draft before photos are attached.
--
-- saveDraft fires from the wizard app bar at any step, so requiring
-- cover_image_url at insert time would enforce a published-row invariant against
-- drafts. Instead: the column becomes nullable, and a CHECK requires a cover
-- only once the listing reaches pending_review or published — a reviewer cannot
-- assess a photoless listing and the public catalog must never show one.
--
-- Additive: cover_image_url was NOT NULL until now, so no existing row can
-- violate the new CHECK. status is nullable; a NULL status is treated as
-- not-yet-submitted (NULL NOT IN (...) is NULL, so the CHECK passes).

alter table public.experiences
  alter column cover_image_url drop not null;

alter table public.experiences
  add constraint experiences_cover_image_required
  check (
    status not in ('published', 'pending_review')
    or cover_image_url is not null
  );
