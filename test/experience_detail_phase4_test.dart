import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_e/features/experience/experience_detail_providers.dart';
import 'package:plan_e/features/experience/experience_detail_screen.dart';
import 'package:plan_e/models/category.dart';
import 'package:plan_e/models/experience.dart';
import 'package:plan_e/models/experience_family.dart';
import 'package:plan_e/providers/app_providers.dart';

void main() {
  testWidgets('non-adventure details omit trekking-only facts and defaults', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final now = DateTime.utc(2026, 8, 21);
    final experience = Experience(
      id: 'pottery',
      categoryId: 'craft',
      title: 'Bhaktapur Pottery Workshop',
      slug: 'bhaktapur-pottery',
      summary: 'Shape clay with a local maker.',
      coverImageUrl: '',
      locationName: 'Bhaktapur',
      durationHours: 2,
      groupSizeMin: 1,
      groupSizeMax: 6,
      minAge: 8,
      pricePaisa: 150000,
      createdAt: now,
      updatedAt: now,
    );
    final taxonomy = ExperienceTaxonomy(
      categories: [
        Category(
          id: 'craft',
          slug: 'craft-workshop',
          nameEn: 'Craft Workshop',
          nameNe: 'हस्तकला कार्यशाला',
          createdAt: now,
        ),
      ],
      families: defaultExperienceFamilies,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          experienceDetailProvider.overrideWith((ref, id) async => experience),
          isSavedExperienceProvider.overrideWith((ref, id) async => false),
          experienceDeparturesProvider.overrideWith(
            (ref, id) async => const [],
          ),
          experienceItineraryProvider.overrideWith((ref, id) async => const []),
          experienceReviewsProvider.overrideWith((ref, id) async => const []),
          experienceTaxonomyProvider.overrideWith((ref) async => taxonomy),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(375, 812),
              textScaler: TextScaler.linear(1.5),
            ),
            child: ExperienceDetailScreen(id: 'pottery'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('LIVE LIKE A LOCAL'), findsOneWidget);
    expect(find.text('Difficulty'), findsNothing);
    expect(find.text('Altitude'), findsNothing);
    expect(find.text('What to Bring'), findsNothing);
    expect(find.text('About this experience'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
