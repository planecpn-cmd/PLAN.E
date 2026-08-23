import 'package:flutter_test/flutter_test.dart';
import 'package:plan_e/core/experience_presentation.dart';
import 'package:plan_e/models/category.dart';
import 'package:plan_e/models/experience.dart';
import 'package:plan_e/models/experience_family.dart';

void main() {
  final now = DateTime.utc(2026, 8, 21);

  Experience experience(String categoryId) => Experience(
    id: 'experience-$categoryId',
    categoryId: categoryId,
    title: 'Test experience',
    slug: 'test-$categoryId',
    coverImageUrl: '',
    durationHours: 5,
    difficulty: DifficultyLevel.moderate,
    pricePaisa: 100000,
    createdAt: now,
    updatedAt: now,
  );

  test('legacy category slugs resolve to their new family', () {
    final taxonomy = ExperienceTaxonomy(
      categories: [
        Category(
          id: 'trekking-id',
          slug: 'trekking',
          nameEn: 'Trekking',
          nameNe: 'ट्रेकिङ',
          createdAt: now,
        ),
      ],
      families: defaultExperienceFamilies,
    );

    expect(taxonomy.familyFor('trekking-id')?.slug, 'adventure-together');
  });

  test('difficulty appears for adventure presentation', () {
    final taxonomy = ExperienceTaxonomy(
      categories: [
        Category(
          id: 'trekking-id',
          slug: 'trekking',
          nameEn: 'Trekking',
          nameNe: 'ट्रेकिङ',
          createdAt: now,
        ),
      ],
      families: defaultExperienceFamilies,
    );

    final presentation = ExperiencePresentation.from(
      experience('trekking-id'),
      taxonomy,
    );

    expect(presentation.familyLabel, 'Adventure Together');
    expect(presentation.familySlug, 'adventure-together');
    expect(presentation.typeLabel, 'Trekking');
    expect(presentation.detailText, contains('Moderate'));
  });

  test('difficulty is omitted from non-adventure presentation', () {
    final taxonomy = ExperienceTaxonomy(
      categories: [
        Category(
          id: 'workshop-id',
          slug: 'craft-workshop',
          nameEn: 'Craft Workshop',
          nameNe: 'हस्तकला कार्यशाला',
          createdAt: now,
        ),
      ],
      families: defaultExperienceFamilies,
    );

    final presentation = ExperiencePresentation.from(
      experience('workshop-id'),
      taxonomy,
    );

    expect(presentation.familyLabel, 'Live Like a Local');
    expect(presentation.familySlug, 'live-like-a-local');
    expect(presentation.typeLabel, 'Craft Workshop');
    expect(presentation.detailText, isNot(contains('Moderate')));
  });
}
