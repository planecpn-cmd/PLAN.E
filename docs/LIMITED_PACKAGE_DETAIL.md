# Limited Package Detail implementation

## Scope and files

The existing `/experience/:id` route now selects the appropriate presentation automatically. Full Detail content and the existing `/booking/:id` flow remain in place. No production schema, dependencies, seed experiences, or unrelated screens were changed.

- `lib/features/experience/experience_detail_screen.dart`: resolves taxonomy before rendering; dispatches Limited mode; reuses the existing optimistic favourite handler and booking navigation. Full Detail builders remain intact.
- `lib/features/experience/limited_package_data.dart`: presentation mapping, narrow display projection, reviewed-content provider contract, itinerary stages, package option definitions, and next-departure selection.
- `lib/features/experience/limited_package_detail.dart`: Limited screen, gallery, availability, basic-info grid, expandable itinerary, checklist, things to know, unavailable download, package cards, customization controls/summary, customer rating summaries, and sticky CTA.
- `lib/models/experience.dart`: absent best-season data now remains empty instead of inventing the usual trekking months. Existing database values are preserved.
- `test/limited_package_detail_test.dart`: mapping, missing-data, departure, privacy, routing, layout and package-control regression tests.
- `docs/LIMITED_PACKAGE_DETAIL.md`: this implementation and integration report.

Shared building blocks include `PlanEPhoto`, `AppCard`, `AppButton`, `RatingStars`, formatters, theme tokens, existing detail/departure/review providers, and the existing favourite mutation. Limited widgets receive a narrow data object rather than the raw Experience, Profile or ItineraryItem models.

## Automatic selection

The exact relationship is `experiences.category_id` → `categories.id`, with `categories.slug` used for the mapping and `categories.name_en` used in the app bar.

| Presentation | Existing category slugs |
| --- | --- |
| Limited | `trekking`, `climbing`, `multi-day-tour`, `travel-package` |
| Full | `hiking`, `camping`, `culture`, `wildlife`, `homestay`, `wellness`, `community`, `volunteering`, `day-trip`, `guided-tour`, `food-experience`, `village-stay`, `farm-experience`, `craft-workshop`, `yoga`, `meditation`, `wellness-retreat`, `creative-workshop`, `meetup`, `group-activity`, `community-event`, `volunteer-project`, `conservation-project`, `skill-sharing` |

All other **resolved** category slugs use Full Detail. Missing/unresolved categories use Limited as a conservative fallback. While taxonomy is loading, neither detail screen appears; taxonomy failures have a retry state. This prevents a temporary flash of host data.

`climbing` is an existing category containing peak-climbing expeditions; no invented `peak_climbing` ID was added. Rafting/paragliding were examples in the request, not category slugs found in this repository. They have not been invented or seeded.

The repository also has `experience_families`, `tags`, and `experience_tags`. Tags are not loaded into the Experience model and existing category slugs suffice for this mapping. If packages later share categories with ordinary activities, a curated tag or explicit presentation override will be needed. Newly introduced categories need mapping review before publishing sensitive packages.

## Existing data and missing support

| Information | Current source / behavior |
| --- | --- |
| Title and photos | `experiences.title`, `cover_image_url`, `gallery`; existing public catalogue media |
| General region | `experiences.region_id` → `regions.name_en`; never falls back to exact `location_name` or `meeting_point` |
| Season | `best_season`; only valid month numbers shown; absent values have an unavailable state |
| Altitude | `max_altitude_m`; only positive values shown |
| Duration, difficulty, group size, age | `duration_hours`, `difficulty`, `group_size_min/max`, `min_age` |
| Standard price | `price_paisa`, `currency`; clearly per person, with departure-dependent final pricing |
| Availability | `experience_departures.start_date`, `status`, `spots_left`; earliest open, nonpast departure with remaining spots; loading/error/empty states are distinct |
| Reviews | Existing public review provider; real rating/date summaries plus experience aggregate rating/count |
| Checklist, inclusions, notes, permits | Existing unrestricted `bring_list`, `included`, `things_to_know`, `permits_required`; require reviewed public copies before using them in Limited mode |
| Itinerary | Existing `itinerary_items` has day number, start time, unrestricted title/description, and sort order; no structured public route, distance, altitude, walking time or highlights |
| Starting point | No safe general starting-point field; exact `meeting_point` is deliberately excluded |
| Total distance | No current dedicated field |
| Customization | No package-specific supported-options catalogue, required-service rules, quote logic or request endpoint found |
| Download | No existing itinerary export/download implementation found |

`limitedPackageContentProvider(experienceId)` currently returns an empty `LimitedPackageContent`. It is an explicit UI-only integration seam, not a fake backend. Its production data feed remains to be implemented. Consequently **current Limited packages show unavailable states for starting point, total distance, schedule, checklist, and inclusions**. Things to Know uses the supported minimum age and can accept reviewed notes later.

The structured content contract accepts public starting point and total distance; stages with day, route, distance, altitude, walking time and highlights; checklist; things to know; inclusions; and supported package options. Values live outside UI files. To populate it, supply editorially approved content from a public projection or dedicated public content fields. Existing safe checklist/itinerary copy can be reused after review; do not copy unrestricted logistics wholesale. No database migration was applied speculatively.

## Privacy behavior and boundary

Limited mode does not request a host profile or the separate unrestricted itinerary provider. Its widgets do not receive host IDs/profiles, guide/supplier contacts, meeting points, coordinates, descriptions, raw inclusions/notes/checklists, raw itinerary objects, review bodies/titles/photos, or external booking links. There is no organizer card, host photo/name, contact action, meeting-point map or supplier section.

Written reviews are withheld pending privacy review; rating/date summaries remain visible. Full mode continues displaying its existing written reviews. A moderated public review-body source is required to restore written review content on Limited screens safely. Simple phone/email regex replacement would not reliably remove supplier names or indirect booking instructions, so it is not treated as a privacy boundary.

This is **UI data separation, not server-side secrecy**. The existing Experience repository still fetches/caches the full experience response, and database access policies were not changed. Production enforcement requires a server-side public projection and access controls that prevent clients from reading provider-sensitive fields. Existing public titles and photo assets also require editorial review for embedded provider names, logos or contact information; this implementation does not inspect image pixels. These are remaining content/API requirements, not guarantees provided by hiding widgets.

## Packages and customization

- Default sticky action: **Choose Package**, which scrolls to package selection.
- **Standard Package / Ready to Go** shows the stored price; **Choose Standard** selects it and changes the sticky action to **Continue**.
- **Continue** opens the existing booking route. Departure selection, departure price overrides, payment and booking validation remain there.
- **Plan It Your Own Style** expands the customization panel. No unsupported options are offered for current production packages.
- The option renderer supports grouped checkboxes, mutually exclusive radio selections, locked required services, and optional dietary/support notes.
- Required options never have a deselection control. Selecting one mutually exclusive option clears its alternatives.
- **Your Plan** shows the stored base price and selected/required items. Add-on amounts and totals are not fabricated; the panel states that price will be updated after customization review.
- Custom selections and notes are local UI state only. **Request Customized Plan** and sticky **Continue With My Plan** are disabled until a real custom-request backend exists. They cannot fall through to Standard checkout or produce a confirmation.
- **Download Itinerary** is disabled with an explicit unavailable explanation. No file is generated, opened or falsely reported as downloaded. A future export must consume reviewed public content only.
- Favourite uses the existing authenticated optimistic-save flow. Share preserves the existing title-copy behavior, with truthful “Experience title copied” feedback; native sharing/deep-link generation was not added.

## Verification

- Dart formatter: passed for changed Dart files.
- `flutter analyze --no-pub`: **no issues found**.
- Targeted tests: **24 passed** across `limited_package_detail_test`, `experience_detail_phase4_test`, `booking_payment_test`, `trips_and_reviews_test`, and `phase4_detail_cache_test`.
- Tests cover real category mapping, taxonomy loading without host requests, absence of sensitive fixture text, missing seasons, departure filtering/sorting, Standard route handoff, accordion expansion, mandatory-service locking, mutually exclusive upgrades, note input, disabled download/custom submission, save/share callback wiring, and small-screen layouts.
- Layout tests run at 320×740 and 812×375 with 1.5× text and reduced motion. The footer occupies Scaffold layout space, and content scrolls independently above it; long labels wrap. No layout exceptions were reported.
- Additional temporary preview tests rendered portrait/landscape screens using the Plan E theme and local font substitutions. These are synthetic fixtures, not production content or seeded experiences.
- `flutter build apk --debug --no-pub`: **succeeded**, producing `build/app/outputs/flutter-apk/app-debug.apk`. Existing Flutter warnings concern plugin Kotlin Gradle migration (`file_picker`, `package_info_plus`).
- Not claimed: a live backend/device walkthrough, native keyboard/OS accessibility validation, photo-content audit, production custom requests, written-review moderation, or downloadable itinerary generation.

## Live catalogue correction — 2026-09-04

After the user reported identical detail screens, the live catalogue audit found two multi-day treks assigned to Full-mode categories: Mardi Himal High Ridge Trek (`hiking`, 120 hours) and Upper Mustang Forbidden Kingdom Trek (`culture`, 288 hours). Migration `20260904080000_limited_package_category_corrections.sql` corrects only those verified records to the existing `trekking` category. It matches IDs, titles, slugs, durations and previous category before changing anything. The dry run listed only this migration; it was applied to the linked hosted project and both updated assignments were verified by a read-only query.

On-device verification on the installed Android build confirmed Everest Base Camp Trek opens Limited Detail with the category app bar and Choose Package CTA, while Pokhara Tandem Paragliding retains Full Detail with its schedule, inclusions, meeting point and Join Experience CTA. No app routing changes or new category IDs were needed for this correction. The broader Home Trek grouping includes hiking and keyword matches; it is not itself the authoritative detail presentation category.

## Visual refinement — 2026-09-04

This presentation-only pass changes `lib/features/experience/limited_package_detail.dart`, updates `test/limited_package_detail_test.dart`, and records the results here. Full Detail and the category mapping, data projection, database and booking/customization backends are unchanged by this pass.

The large app bar is removed. The hero now occupies about 38% of the viewport (bounded to 265–380 logical pixels), with circular back/share/save controls and a compact category label inside its safe area. Gallery paging remains available, with controls over the photo so the sage availability strip sits immediately below the hero. A category indicator, 26px serif title, location icon and review summary lead into a two-column bordered metric grid. Section cards now use the reference's 18px corners, 14px padding, heading icons, subtle borders and 20px gaps. Selected package cards use a light sage tint. Download uses the existing secondary outlined button. The sticky footer uses the reference's rounded white surface/shadow and price-left/button-right layout: CHOOSE PACKAGE by default, CONTINUE after selection (still disabled for unsupported custom requests).

Reused shared components: `PlanEBackground`, `PlanEPhoto`, `AppCard`, `AppButton.secondary`, `RatingStars`, existing theme tokens and formatters. New private layout helpers are the floating circular control, summary metric grid and section-icon mapping; no global widget or additional dependency was introduced.

Validation: formatter passed; analyzer reported no issues; all 9 targeted Limited/Full Detail tests passed, including 320×740, 375×812 and 812×375 at 1.5× text, privacy/routing regressions and right-aligned footer CTA checks. Android debug build succeeded with the existing plugin Kotlin migration warnings; the build was installed without clearing app data. On-device inspection confirmed the updated metric cards, compact Basic Info grid, decorative background and horizontal footer.

## Package selector and back navigation follow-up

The Limited screen back callback now pops when navigation history exists and otherwise goes to `/home`, fixing directly opened detail pages. The hero category label increased from 13px to 20px. Choose Your Package is now one rounded card containing a single radio group with two selectable rows separated by a divider. Standard selections reveal inclusions; custom selections reveal the existing customization controls. Separate green choice buttons and the unavailable custom-request button were removed; the sticky footer remains the primary action. No backend or category changes were made.

Updated the detail dispatcher, Limited layout and regression tests. Analyzer clean, all 9 detail tests passed (including direct-entry back navigation), Android debug build succeeded and was installed while retaining app data.
