# Database-owned plan photographs

Corrected the discovery-only image overrides on 2026-09-04.

- All plan screens now use `experiences.cover_image_url`: Home, Explore results, Search, Collections, Saved, full/limited Details, bookings/Trips and Itinerary. No title/slug image selection remains in Dart.
- Explore categories use `experience_families.cover_image_url`.
- 46 reviewed WebP files were uploaded to the public `catalog-images/plane-catalog-upload/` Storage prefix. Only licensed catalog photography is stored there; no client upload policies were added.
- Updated 30 live plan covers and 6 live family covers. All 36 references match existing Storage objects. Four separate demo-host records retain their database covers consistently; they were outside the reviewed 30-plan mapping.
- The original and revised catalog titles are matched only during the one-time SQL update, guarded by their previous cover values. The database is authoritative thereafter, including host edits.
- The two page heroes remain distinct local photographs because they are page decoration, not plan covers.
- Existing licensed source files and source credits remain available in IMAGE_SOURCES.json, now including canonical `storage_url` values. The small shared crop helper chooses alignment only; it never substitutes an image.
- Migrations 20260904090000 and 20260904091000 were applied directly to the linked project; unrelated pending migrations were not pushed. The seed includes the same guarded data update. A guarded rollback for this live catalog is in CATALOG_PHOTO_ROLLBACK.sql.
- Old values were snapshotted before updating. A before/after comparison confirmed that the selected record IDs, slugs, titles and galleries were preserved.

Validation: all 25 targeted Home/Explore/detail/image regression tests pass; full-project analysis has no issues; diff whitespace check passes. Android debug build and installation succeeded and the corrected app was relaunched on SM S911B against the same Supabase project to refresh in-memory catalog state. Existing offline fallback data can remain stale until a successful online fetch.
