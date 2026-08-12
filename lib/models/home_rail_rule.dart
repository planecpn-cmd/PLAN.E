import 'experience.dart';

/// A merchandising rule for one keyword-matched home rail: an experience
/// belongs to [key]'s rail if it's in [categorySlug] (when set) OR its
/// title/summary/description/things-to-know text contains any of [terms].
class HomeRailRule {
  final String key;
  final String? categorySlug;
  final List<String> terms;

  const HomeRailRule({
    required this.key,
    this.categorySlug,
    this.terms = const [],
  });
}

/// The exact rail definitions this app shipped with before remote_content
/// existed — the fallback whenever nothing's configured remotely, or the
/// remote payload doesn't parse.
const List<HomeRailRule> defaultHomeRailRules = [
  HomeRailRule(
    key: 'community',
    terms: ['community', 'local women', 'local family', 'cooperative'],
  ),
  HomeRailRule(
    key: 'adventure-together',
    terms: [
      'family',
      'group',
      'tandem',
      'rafting',
      'camping',
      'safari',
      'day out',
      'festival',
      'homestay',
    ],
  ),
  HomeRailRule(
    key: 'mind-soul',
    categorySlug: 'wellness',
    terms: [
      'yoga',
      'meditation',
      'spiritual',
      'wellness',
      'relax',
      'healing',
      'peace',
      'quiet',
      'monastery',
      'forest',
    ],
  ),
  HomeRailRule(
    key: 'give-back',
    categorySlug: 'volunteering',
    terms: [
      'volunteer',
      'community',
      'conservation',
      'environment',
      'sustainable',
      'empower',
      'cooperative',
      'organic farm',
      'social impact',
    ],
  ),
];

/// Parses `remote_content.home_rail_rules` — a JSON array of
/// `{"key": "...", "category_slug": "..."?, "terms": ["...", ...]?}`.
/// Falls back to [defaultHomeRailRules] wholesale (not per-entry) on
/// anything malformed — a partially broken remote payload should never mix
/// intended rails with silently-dropped ones; better to run the known-good
/// defaults than a half-parsed merchandising config.
List<HomeRailRule> resolveHomeRailRules(dynamic remote) {
  if (remote is! List) return defaultHomeRailRules;

  final rules = <HomeRailRule>[];
  for (final entry in remote) {
    if (entry is! Map) return defaultHomeRailRules;
    final map = Map<String, dynamic>.from(entry);

    final key = map['key'];
    if (key is! String || key.isEmpty) return defaultHomeRailRules;

    final categorySlug = map['category_slug'];
    final termsRaw = map['terms'];
    final terms = termsRaw is List
        ? termsRaw.whereType<String>().toList()
        : const <String>[];

    rules.add(
      HomeRailRule(
        key: key,
        categorySlug: (categorySlug is String && categorySlug.isNotEmpty)
            ? categorySlug
            : null,
        terms: terms,
      ),
    );
  }
  return rules;
}

/// Buckets [experiences] into rule-defined rails, capped at [limit] each.
/// [categorySlugsById] maps `experiences.category_id` -> category slug
/// (from the `categories` table) — the same lookup ExperienceRepository
/// already builds for its category-based rails.
Map<String, List<Experience>> buildRuleBasedRails(
  List<Experience> experiences,
  Map<String, String> categorySlugsById,
  List<HomeRailRule> rules, {
  int limit = 10,
}) {
  String categoryOf(Experience experience) =>
      categorySlugsById[experience.categoryId] ?? '';

  String searchableText(Experience experience) => [
    experience.title,
    experience.summary ?? '',
    experience.description ?? '',
    ...experience.thingsToKnow,
  ].join(' ').toLowerCase();

  bool matches(Experience experience, HomeRailRule rule) {
    if (rule.categorySlug != null && categoryOf(experience) == rule.categorySlug) {
      return true;
    }
    if (rule.terms.isEmpty) return false;
    final text = searchableText(experience);
    return rule.terms.any(text.contains);
  }

  return {
    for (final rule in rules)
      rule.key: experiences
          .where((experience) => matches(experience, rule))
          .take(limit)
          .toList(growable: false),
  };
}
