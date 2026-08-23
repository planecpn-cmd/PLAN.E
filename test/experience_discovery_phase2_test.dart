import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_e/core/experience_presentation.dart';
import 'package:plan_e/features/search/filter_sheet.dart';
import 'package:plan_e/l10n/app_localizations.dart';
import 'package:plan_e/models/experience_family.dart';
import 'package:plan_e/providers/app_providers.dart';
import 'package:plan_e/widgets/experience_mood_grid.dart';
import 'package:plan_e/widgets/experience_card.dart';

void main() {
  test('difficulty is scoped to Adventure Together', () {
    expect(familySupportsDifficulty('adventure-together'), isTrue);
    expect(familySupportsDifficulty('mind-soul'), isFalse);
    expect(familySupportsDifficulty(null), isFalse);
  });

  test('every mood routes to a known experience family', () {
    final knownFamilies = defaultExperienceFamilies
        .map((family) => family.slug)
        .toSet();

    expect(experienceMoods, hasLength(6));
    expect(
      experienceMoods.every((mood) => knownFamilies.contains(mood.familySlug)),
      isTrue,
    );
  });

  testWidgets('mood grid reflows without overflow at large text size', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(375, 812),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ExperienceMoodGrid(onSelected: (_) {}),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Relax'), findsOneWidget);
    expect(find.text('Help'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('difficulty appears only after selecting Adventure Together', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final taxonomy = ExperienceTaxonomy(
      categories: const [],
      families: defaultExperienceFamilies,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoriesProvider.overrideWith((ref) async => const []),
          regionsProvider.overrideWith((ref) async => const []),
          experienceFamiliesProvider.overrideWith(
            (ref) async => defaultExperienceFamilies,
          ),
          experienceTaxonomyProvider.overrideWith((ref) async => taxonomy),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: FilterSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Difficulty Level'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Adventure Together'));
    await tester.pumpAndSettle();
    expect(find.text('Difficulty Level'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('full-width experience cards use a finite image request width', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ExperienceCard(
            width: double.infinity,
            title: 'Pottery workshop',
            location: 'Bhaktapur',
            rating: 4.9,
            priceText: 'NPR 1,500',
            imageUrl: 'https://example.com/pottery.jpg',
          ),
        ),
      ),
    );

    expect(find.text('Pottery workshop'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home poster card fits its rail height without overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 324,
            child: ExperienceCard(
              width: 148,
              variant: ExperienceCardVariant.poster,
              title: 'Community pottery workshop',
              location: 'Bhaktapur',
              rating: 4.9,
              reviewCount: 42,
              priceText: 'NPR 1,500',
              familyLabel: 'Live Like a Local',
              typeLabel: 'Craft Workshop',
              detailText: '3 hours',
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('experience-card bookmark invokes its save action', (
    tester,
  ) async {
    var bookmarkTapped = false;
    var cardTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 324,
            child: ExperienceCard(
              width: 148,
              variant: ExperienceCardVariant.poster,
              title: 'Pottery workshop',
              location: 'Bhaktapur',
              rating: 4.9,
              priceText: 'NPR 1,500',
              onTap: () => cardTapped = true,
              onBookmarkTap: () => bookmarkTapped = true,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.bookmark_border));
    expect(bookmarkTapped, isTrue);
    expect(cardTapped, isFalse);
  });
}
