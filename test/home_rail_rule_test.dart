import 'package:flutter_test/flutter_test.dart';
import 'package:plan_e/models/experience.dart';
import 'package:plan_e/models/home_rail_rule.dart';

Experience _exp({
  required String id,
  String? categoryId,
  String title = 'Untitled',
  String? summary,
  String? description,
  List<String> thingsToKnow = const [],
  int ratingCount = 0,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Experience(
    id: id,
    categoryId: categoryId,
    title: title,
    slug: id,
    summary: summary,
    description: description,
    coverImageUrl: '',
    thingsToKnow: thingsToKnow,
    pricePaisa: 100000,
    ratingCount: ratingCount,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('resolveHomeRailRules', () {
    test('null → defaults', () {
      expect(resolveHomeRailRules(null), same(defaultHomeRailRules));
    });

    test('non-List → defaults', () {
      expect(resolveHomeRailRules({'not': 'a list'}), same(defaultHomeRailRules));
    });

    test('empty array is a valid config, not malformed → zero rules', () {
      final rules = resolveHomeRailRules(<dynamic>[]);
      expect(rules, isEmpty);
    });

    test('entry that is not a Map → whole payload falls back to defaults', () {
      final rules = resolveHomeRailRules(['not a map']);
      expect(rules, same(defaultHomeRailRules));
    });

    test('entry missing key → falls back to defaults', () {
      final rules = resolveHomeRailRules([
        {'terms': ['x']},
      ]);
      expect(rules, same(defaultHomeRailRules));
    });

    test('entry with empty key → falls back to defaults', () {
      final rules = resolveHomeRailRules([
        {'key': '', 'terms': ['x']},
      ]);
      expect(rules, same(defaultHomeRailRules));
    });

    test('valid config parses key, category_slug, and terms', () {
      final rules = resolveHomeRailRules([
        {
          'key': 'foodie',
          'category_slug': 'culture',
          'terms': ['cooking', 'cuisine', 'food'],
        },
        {'key': 'no-terms-no-category'},
      ]);
      expect(rules.length, 2);
      expect(rules[0].key, 'foodie');
      expect(rules[0].categorySlug, 'culture');
      expect(rules[0].terms, ['cooking', 'cuisine', 'food']);
      expect(rules[1].key, 'no-terms-no-category');
      expect(rules[1].categorySlug, isNull);
      expect(rules[1].terms, isEmpty);
    });

    test('empty category_slug string is treated as null', () {
      final rules = resolveHomeRailRules([
        {'key': 'x', 'category_slug': ''},
      ]);
      expect(rules[0].categorySlug, isNull);
    });

    test('non-List terms field degrades to empty list', () {
      final rules = resolveHomeRailRules([
        {'key': 'x', 'terms': 'not-a-list'},
      ]);
      expect(rules[0].terms, isEmpty);
    });

    test('non-string entries inside terms are dropped, not crash', () {
      final rules = resolveHomeRailRules([
        {'key': 'x', 'terms': ['valid', 42, null, 'also-valid']},
      ]);
      expect(rules[0].terms, ['valid', 'also-valid']);
    });
  });

  group('buildRuleBasedRails', () {
    test('term match is case-insensitive across the searchable text fields', () {
      final experiences = [
        _exp(id: '1', title: 'Yoga Retreat in Pokhara'),
        _exp(id: '2', title: 'City Tour', summary: 'A relaxing MEDITATION walk'),
        _exp(id: '3', title: 'Unrelated Trek'),
      ];
      const rules = [HomeRailRule(key: 'mind-soul', terms: ['yoga', 'meditation'])];

      final result = buildRuleBasedRails(experiences, const {}, rules);

      expect(result['mind-soul']!.map((e) => e.id), containsAll(['1', '2']));
      expect(result['mind-soul']!.map((e) => e.id), isNot(contains('3')));
    });

    test('category match works even with no terms configured', () {
      final experiences = [
        _exp(id: '1', categoryId: 'cat-wellness'),
        _exp(id: '2', categoryId: 'cat-trekking'),
      ];
      const rules = [
        HomeRailRule(key: 'mind-soul', categorySlug: 'wellness', terms: []),
      ];
      final categorySlugs = {'cat-wellness': 'wellness', 'cat-trekking': 'trekking'};

      final result = buildRuleBasedRails(experiences, categorySlugs, rules);

      expect(result['mind-soul']!.map((e) => e.id), ['1']);
    });

    test('category OR terms — either is enough to match', () {
      final experiences = [
        _exp(id: 'by-category', categoryId: 'cat-wellness'),
        _exp(id: 'by-term', categoryId: 'cat-trekking', description: 'a yoga session'),
        _exp(id: 'neither', categoryId: 'cat-trekking'),
      ];
      const rules = [
        HomeRailRule(key: 'mind-soul', categorySlug: 'wellness', terms: ['yoga']),
      ];
      final categorySlugs = {'cat-wellness': 'wellness', 'cat-trekking': 'trekking'};

      final result = buildRuleBasedRails(experiences, categorySlugs, rules);

      expect(result['mind-soul']!.map((e) => e.id), containsAll(['by-category', 'by-term']));
      expect(result['mind-soul']!.map((e) => e.id), isNot(contains('neither')));
    });

    test('thingsToKnow is part of the searched text', () {
      final experiences = [
        _exp(id: '1', thingsToKnow: ['run by a local cooperative']),
      ];
      const rules = [HomeRailRule(key: 'community', terms: ['cooperative'])];

      final result = buildRuleBasedRails(experiences, const {}, rules);

      expect(result['community']!.map((e) => e.id), ['1']);
    });

    test('respects the limit and preserves incoming order (highest rated first)', () {
      final experiences = List.generate(
        15,
        (i) => _exp(id: '$i', title: 'Yoga trip $i'),
      );
      const rules = [HomeRailRule(key: 'mind-soul', terms: ['yoga'])];

      final result = buildRuleBasedRails(experiences, const {}, rules, limit: 10);

      expect(result['mind-soul']!.length, 10);
      expect(result['mind-soul']!.first.id, '0');
    });

    test('no matches → empty list for that rail key, not a missing key', () {
      final experiences = [_exp(id: '1', title: 'Trek')];
      const rules = [HomeRailRule(key: 'mind-soul', terms: ['yoga'])];

      final result = buildRuleBasedRails(experiences, const {}, rules);

      expect(result.containsKey('mind-soul'), isTrue);
      expect(result['mind-soul'], isEmpty);
    });

    test('every rule produces its own key, independent of the others', () {
      final experiences = [
        _exp(id: '1', title: 'Yoga and volunteering trip'),
      ];
      const rules = [
        HomeRailRule(key: 'mind-soul', terms: ['yoga']),
        HomeRailRule(key: 'give-back', terms: ['volunteering']),
        HomeRailRule(key: 'unrelated', terms: ['skydiving']),
      ];

      final result = buildRuleBasedRails(experiences, const {}, rules);

      expect(result.keys, containsAll(['mind-soul', 'give-back', 'unrelated']));
      expect(result['mind-soul'], hasLength(1));
      expect(result['give-back'], hasLength(1));
      expect(result['unrelated'], isEmpty);
    });
  });
}
