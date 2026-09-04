# Category results redesign

## Scope and files

- `lib/features/search/search_results_screen.dart`: coordinated sliver page, collapsing header, database-backed activity chips, search clearing fixes, bookmark callbacks, Explore fallback navigation, bottom clearance.
- `lib/features/search/filter_sheet.dart`: explicit Any difficulty option in the existing shared filter sheet.
- `lib/widgets/experience_card.dart`: rating/price row wraps when narrow. This file already had unrelated working-tree edits; those were retained.
- `lib/widgets/filter_chip_pill.dart`: labels can wrap inside bounded filter sheets; horizontally scrolling discovery chips retain their natural width.
- `test/category_results_test.dart`: small-screen widget regression tests.
- This report.

Explore landing, routing, bottom navigation, backend and database schema were not changed. Existing working-tree changes were retained.

## Scrolling

One `CustomScrollView` owns vertical movement. A pinned `SliverPersistentHeader` interpolates the same search field from its full-width position below the logo into the toolbar over 60 logical pixels of scrolling. The logo fades/slides away. The header is 152 pixels expanded and 92 collapsed when context is present, excluding the system top safe area. Back, search, filter and one-line family/type context remain pinned. Activity options, recent searches and the Search Results title scroll away. Results use a lazy `SliverList`, including sliver-based loading/error/empty states. There is no separately scrolling results panel. Scrolling back to zero reverses the transition.

The existing shell bottom navigation stays fixed. The final sliver adds 84 pixels plus the inherited bottom safe-area padding, clearing its 58-pixel bar and 10-pixel margin. Existing push/pop navigation preserves Explore's route; direct-entry fallback goes to Explore.

## Actual taxonomy mapping

Options use `experienceTaxonomyProvider`, `ExperienceTaxonomy.familyFor(category.id)`, and the real category IDs. Database family assignments take precedence over the existing legacy slug fallback. Labels are the database `nameEn` values, ordered by `sortOrder`. No option is preselected for family entry; category deep links keep their specific selection and infer the family for discovery. Any additional correctly assigned categories in the live database appear automatically.

Checked-in category seeds map as follows (display label → slug):

| Family | Actual options |
|---|---|
| Adventure Together | Trekking → `trekking`; Day Hiking → `hiking`; Camping → `camping`; Climbing → `climbing`; Wildlife → `wildlife` |
| Mind & Soul (repository wording) | Wellness → `wellness`; Yoga → `yoga`; Meditation → `meditation`; Wellness Retreat → `wellness-retreat`; Creative Workshop → `creative-workshop` |
| Live Like a Local | Homestay → `homestay`; Culture → `culture`; Food Experience → `food-experience`; Village Stay → `village-stay`; Farm Experience → `farm-experience`; Craft Workshop → `craft-workshop` |
| Trips & Tours | Day Trip → `day-trip`; Guided Tour → `guided-tour`; Multi-day Tour → `multi-day-tour`; Travel Package → `travel-package` |
| Meet People | Meetup → `meetup`; Group Activity → `group-activity`; Community Event → `community-event` |
| Give Back | Volunteering → `volunteering`; Volunteer Project → `volunteer-project`; Conservation Project → `conservation-project`; Skill Sharing → `skill-sharing` |

## Requested taxonomy gaps

The exact requested option sets are **not fully implemented**, because the checked-in database does not contain distinct matching categories/tags:

- Adventure: Climbing cannot reliably distinguish Peak from Rock Climbing. Rafting, Paragliding, Canyoning and Sky Diving have no category/tag IDs. Rafting and paragliding occur in listing/itinerary content, which is not a structured category mapping. Therefore all eight requested Adventure options are not exposed by the seeded taxonomy.
- Mind & Soul: no dedicated Sound Healing, Healing, Hiking + Wellness or Experience + Stay categories. Wellness is broader than Healing. Creative Workshop covers creativity. Culture and Food Experience remain under Live Like a Local. Sound healing exists in itinerary content but is not a category/tag.
- Stays: Homestay and Village Stay exist. Nature Stays, Mountain Stays, Heritage Stays and Villas have no dedicated categories. Wellness Retreat remains under Mind & Soul.
- Trips: the four existing package/tour types are shown; Pilgrimage & Spiritual Journeys has no dedicated category. Wildlife remains under Adventure Together.
- Meet People: existing Meetup, Group Activity and Community Event cover the closest discovery intents; no separate Local Connections category. The social tag is not a category and the existing search provider has no tag filter.
- Give Back: Conservation Project is the existing environmental option; no separate Community category. Existing volunteer and skill-sharing categories remain available.

No duplicate taxonomy, broad-category relabeling as a narrower activity, fake counts or fake listings were introduced. This report audits repository seeds, not the live database contents.

## Search, filters and cards

Search remains server-side and context-scoped: the existing repository combines full-text search with selected category ID, or with the family's category IDs when no type is selected. Chip changes retain the query and secondary filters; scroll frames do not recreate the provider filter map. Clear search updates results immediately; Clear All cancels pending debounce work and resets all context and filters.

The existing Explore All filters action and results filter icon share `FilterSheet`. Supported controls remain difficulty (including Any), region, price range, maximum duration, family/type and sorting. No new unsupported fields were added.

Card design remains intact except responsive rating/price spacing. In a family context its badge uses the specific type. Detail navigation remains unchanged. Previously unwired bookmarks now call the existing saved repository, use existing deferred sign-in for guests, invalidate saved state on success and report failures.

## Validation

- Formatter: all five changed Dart files formatted.
- Full Flutter analyzer: passed with no issues.
- Focused test run: all 8 tests passed.
- Widget tests: 320 × 640, text scale 1× and 2×; family entry has no preselection; activity selection updates category ID; difficulty sheet applies within category; search remains scoped; clear and pending debounce reset; one vertical scroll; compact search/filter context retained; header expands at the top; scroll does not trigger new fetches.
- Existing recent-search repository tests included.
- Android debug APK compiled successfully. Build reported existing file_picker/package_info_plus Kotlin Gradle migration warnings.
- No physical Android/emulator visual inspection, live database search, authenticated save round-trip or exhaustive device matrix was performed. Tests use provider fixtures; no fixture data was added to the app.
