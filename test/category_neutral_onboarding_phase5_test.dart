import 'package:flutter_test/flutter_test.dart';
import 'package:plan_e/features/onboarding/interests_screen.dart';
import 'package:plan_e/models/category.dart';
import 'package:plan_e/models/experience_family.dart';

void main() {
  test('interests are grouped under their experience families', () {
    final now = DateTime.utc(2026, 8, 21);
    final taxonomy = ExperienceTaxonomy(
      categories: [
        Category(
          id: 'yoga',
          slug: 'yoga',
          nameEn: 'Yoga',
          nameNe: 'योग',
          sortOrder: 2,
          createdAt: now,
        ),
        Category(
          id: 'pottery',
          slug: 'craft-workshop',
          nameEn: 'Pottery',
          nameNe: 'माटोको काम',
          sortOrder: 1,
          createdAt: now,
        ),
      ],
      families: defaultExperienceFamilies,
    );

    final grouped = groupInterestsByFamily(taxonomy);

    expect(grouped.keys.map((family) => family.slug), [
      'live-like-a-local',
      'mind-soul',
    ]);
    expect(grouped.values.expand((categories) => categories).map((c) => c.id), [
      'pottery',
      'yoga',
    ]);
  });
}
