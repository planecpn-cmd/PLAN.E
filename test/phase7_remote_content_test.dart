import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_e/features/onboarding/onboarding_slide_screen.dart';
import 'package:plan_e/models/promo_banner.dart';

const _defaults = [
  OnboardingSlideData(
    screenId: 'PL-02',
    title: 'Default Title 1',
    description: 'Default description 1.',
    icon: Icons.explore_outlined,
  ),
  OnboardingSlideData(
    screenId: 'PL-03',
    title: 'Default Title 2',
    description: 'Default description 2.',
    icon: Icons.payments_outlined,
  ),
  OnboardingSlideData(
    screenId: 'PL-04',
    title: 'Default Title 3',
    description: 'Default description 3.',
    icon: Icons.volunteer_activism_outlined,
  ),
];

void main() {
  group('resolveOnboardingSlides', () {
    test('no remote content → local defaults unchanged', () {
      final result = resolveOnboardingSlides(_defaults, null);
      expect(result[0].title, 'Default Title 1');
      expect(result.length, 3);
    });

    test('remote content is not a List → falls back to defaults', () {
      final result = resolveOnboardingSlides(_defaults, {'not': 'a list'});
      expect(result, same(_defaults));
    });

    test('full override replaces title and description, keeps icon', () {
      final remote = [
        {'title': 'Remote Title 1', 'description': 'Remote description 1.'},
      ];
      final result = resolveOnboardingSlides(_defaults, remote);
      expect(result[0].title, 'Remote Title 1');
      expect(result[0].description, 'Remote description 1.');
      expect(result[0].icon, Icons.explore_outlined);
      // Slides beyond the remote array keep their local defaults.
      expect(result[1].title, 'Default Title 2');
      expect(result[2].title, 'Default Title 3');
    });

    test('partial entry (title only) keeps the other field local', () {
      final remote = [
        {'title': 'Remote Title Only'},
      ];
      final result = resolveOnboardingSlides(_defaults, remote);
      expect(result[0].title, 'Remote Title Only');
      expect(result[0].description, 'Default description 1.');
    });

    test('empty string field falls back to local, not blank', () {
      final remote = [
        {'title': '', 'description': ''},
      ];
      final result = resolveOnboardingSlides(_defaults, remote);
      expect(result[0].title, 'Default Title 1');
      expect(result[0].description, 'Default description 1.');
    });

    test('non-Map entry in the array is skipped for that index', () {
      final remote = ['not a map'];
      final result = resolveOnboardingSlides(_defaults, remote);
      expect(result[0].title, 'Default Title 1');
    });

    test('slide count always matches defaults, even with a longer remote array', () {
      final remote = List.generate(10, (i) => {'title': 'Extra $i'});
      final result = resolveOnboardingSlides(_defaults, remote);
      expect(result.length, 3);
    });
  });

  group('PromoBannerContent.tryParse', () {
    test('null payload → null (no banner)', () {
      expect(PromoBannerContent.tryParse(null), isNull);
    });

    test('non-Map payload → null', () {
      expect(PromoBannerContent.tryParse('a string'), isNull);
      expect(PromoBannerContent.tryParse([1, 2, 3]), isNull);
    });

    test('missing headline → null', () {
      expect(PromoBannerContent.tryParse({'subtitle': 'x'}), isNull);
    });

    test('empty headline → null', () {
      expect(PromoBannerContent.tryParse({'headline': ''}), isNull);
    });

    test('headline only → parses, optional fields null', () {
      final content = PromoBannerContent.tryParse({'headline': 'Autumn treks now open'});
      expect(content, isNotNull);
      expect(content!.headline, 'Autumn treks now open');
      expect(content.subtitle, isNull);
      expect(content.ctaLabel, isNull);
      expect(content.ctaRoute, isNull);
    });

    test('cta_label without cta_route → both drop, not a dead button', () {
      final content = PromoBannerContent.tryParse({
        'headline': 'Sale',
        'cta_label': 'Book Now',
      });
      expect(content!.ctaLabel, isNull);
      expect(content.ctaRoute, isNull);
    });

    test('cta_route without cta_label → both drop', () {
      final content = PromoBannerContent.tryParse({
        'headline': 'Sale',
        'cta_route': '/explore',
      });
      expect(content!.ctaLabel, isNull);
      expect(content.ctaRoute, isNull);
    });

    test('full payload parses every field', () {
      final content = PromoBannerContent.tryParse({
        'headline': 'Autumn treks now open',
        'subtitle': 'Book before the season fills up',
        'cta_label': 'Explore',
        'cta_route': '/explore',
      });
      expect(content!.headline, 'Autumn treks now open');
      expect(content.subtitle, 'Book before the season fills up');
      expect(content.ctaLabel, 'Explore');
      expect(content.ctaRoute, '/explore');
    });
  });
}
