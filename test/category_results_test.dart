import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_e/features/search/search_results_screen.dart';
import 'package:plan_e/l10n/app_localizations.dart';
import 'package:plan_e/models/category.dart';
import 'package:plan_e/models/experience.dart';
import 'package:plan_e/models/experience_family.dart';
import 'package:plan_e/providers/app_providers.dart';
import 'package:plan_e/theme/theme.dart';
import 'package:plan_e/widgets/filter_chip_pill.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('single scroll, context switching and clear at scale $scale', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final requests = <Map<String, String?>>[];
      final categories = ['trekking', 'climbing', 'camping']
          .map(
            (slug) => Category(
              id: slug,
              slug: slug,
              nameEn: slug,
              nameNe: slug,
              createdAt: DateTime(2026),
            ),
          )
          .toList();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experienceTaxonomyProvider.overrideWith(
              (ref) async => ExperienceTaxonomy(
                categories: categories,
                families: defaultExperienceFamilies,
              ),
            ),
            categoriesProvider.overrideWith((ref) async => categories),
            experienceFamiliesProvider.overrideWith(
              (ref) async => defaultExperienceFamilies,
            ),
            regionsProvider.overrideWith((ref) async => []),
            savedExperiencesProvider.overrideWith((ref) async => []),
            recentSearchesProvider.overrideWith((ref) async => []),
            experiencesProvider.overrideWith((ref, filters) async {
              requests.add(Map.of(filters));
              return List.generate(
                6,
                (i) => Experience(
                  id: '$i',
                  slug: '$i',
                  title: 'Experience $i',
                  coverImageUrl: '',
                  pricePaisa: 10000,
                  createdAt: DateTime(2026),
                  updatedAt: DateTime(2026),
                ),
              );
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: const SearchResultsScreen(
              initialFamilySlug: 'adventure-together',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(requests.last['category_id'], isNull);
      expect(find.text('Easy'), findsNothing);
      expect(find.byType(CustomScrollView), findsOneWidget);
      await tester.tap(find.text('trekking'));
      await tester.pumpAndSettle();
      expect(requests.last['category_id'], 'trekking');
      expect(
        tester
            .widget<FilterChipPill>(
              find.widgetWithText(FilterChipPill, 'trekking'),
            )
            .isSelected,
        isTrue,
      );
      if (scale == 1.0) {
        await tester.tap(find.byTooltip('Filter'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Easy'),
          250,
          scrollable: find
              .descendant(
                of: find.byType(BottomSheet),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.tap(find.text('Easy'));
        await tester.scrollUntilVisible(
          find.text('Apply Filters'),
          350,
          scrollable: find
              .descendant(
                of: find.byType(BottomSheet),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.tap(find.text('Apply Filters'));
        await tester.pumpAndSettle();
        expect(requests.last['difficulty'], 'easy');
        expect(requests.last['category_id'], 'trekking');
      }
      await tester.enterText(find.byType(TextField), 'Everest');
      await tester.pump(const Duration(milliseconds: 400));
      expect(requests.last['search_query'], 'Everest');
      expect(requests.last['family'], 'adventure-together');
      final fetches = requests.length;
      await tester.pumpAndSettle();
      await tester.dragFrom(const Offset(160, 580), const Offset(0, -450));
      await tester.pumpAndSettle();
      expect(requests.length, fetches);
      expect(tester.getTopLeft(find.byType(TextField)).dy, closeTo(8, 1));
      expect(find.byTooltip('Filter').hitTestable(), findsOneWidget);
      expect(find.text('Adventure Together • trekking'), findsOneWidget);

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(requests.last['search_query'], isNull);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 1000));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byType(TextField)).dy, closeTo(68, 1));
      await tester.enterText(find.byType(TextField), 'pending');
      await tester.tap(find.text('Clear All'));
      await tester.pumpAndSettle();
      expect(requests.last, {'sort_by': 'relevance'});
      expect(find.text('Clear All'), findsNothing);
    });
  }
}
