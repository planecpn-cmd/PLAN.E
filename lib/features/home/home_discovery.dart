import '../../models/experience.dart';
import '../../models/experience_family.dart';

class HomeFilter {
  final String label;
  final List<String> categories;
  final List<String> terms;
  const HomeFilter(this.label, this.categories, [this.terms = const []]);

  bool matches(Experience experience, ExperienceTaxonomy? taxonomy) {
    final category = taxonomy?.categoryFor(experience.categoryId)?.slug;
    // Titles and summaries describe the current offering; legacy slugs can
    // still name a trek after an experience has become a community event.
    final text = '${experience.title} ${experience.summary ?? ''}'
        .toLowerCase();
    return categories.contains(category) || terms.any(text.contains);
  }
}

class HomeSectionSpec {
  final String slug;
  final String title;
  final String description;
  final List<HomeFilter> filters;
  const HomeSectionSpec(this.slug, this.title, this.description, this.filters);
}

const homeSections = [
  HomeSectionSpec(
    'adventure-together',
    'Adventure Together',
    'Group trips, shared adventures, new connections',
    [
      HomeFilter('Trek', ['trekking', 'hiking'], ['trek', 'hike', 'hiking']),
      HomeFilter('Climb', ['climbing'], ['climbing']),
      HomeFilter('Water', [], ['rafting', 'canyoning', 'kayaking']),
      HomeFilter(
        'Wild Escape',
        ['wildlife'],
        [
          'safari',
          'jungle',
          'wildlife tour',
          'wildlife and culture tour',
          'nature escape',
        ],
      ),
      HomeFilter('Sky', [], [
        'paragliding',
        'skydiving',
        'helicopter',
        'scenic flight',
      ]),
    ],
  ),
  HomeSectionSpec(
    'mind-soul',
    'Soul & Mind',
    'Wellness, reflection, healing and creativity',
    [
      HomeFilter('Yoga', ['yoga'], ['yoga']),
      HomeFilter('Meditation', ['meditation'], ['meditation', 'mindfulness']),
      HomeFilter('Sound & Healing', [], [
        'sound healing',
        'sound bath',
        'singing-bowl',
        'singing bowl',
      ]),
      HomeFilter(
        'Creative Workshops',
        ['creative-workshop', 'craft-workshop'],
        ['pottery', 'art workshop', 'craft workshop'],
      ),
    ],
  ),
  HomeSectionSpec(
    'meet-people',
    'Meet People',
    'Connect, socialize, make new friends',
    [
      HomeFilter(
        'Social',
        ['meetup'],
        ['social', 'meetup', 'community evening'],
      ),
      HomeFilter(
        'Communities',
        ['community-event'],
        ['community night', 'community evening'],
      ),
      HomeFilter(
        'Join an Activity',
        ['group-activity', 'creative-workshop', 'craft-workshop'],
        ['social walk', 'group hike'],
      ),
      HomeFilter(
        'Local Connections',
        ['homestay', 'village-stay', 'community-event'],
        ['local hosts', 'meet residents'],
      ),
    ],
  ),
  HomeSectionSpec(
    'give-back',
    'Give Back',
    'Help communities, share and contribute',
    [
      HomeFilter(
        'Community',
        ['skill-sharing', 'volunteer-project'],
        ['community-led project', 'school support'],
      ),
      HomeFilter(
        'Nature & Environment',
        ['conservation-project'],
        ['conservation', 'clean-up', 'cleanup'],
      ),
      HomeFilter(
        'Volunteering',
        ['volunteering', 'volunteer-project'],
        ['volunteer'],
      ),
    ],
  ),
  HomeSectionSpec(
    'live-like-a-local',
    'Live Like a Local',
    'Local life, traditions and authentic experiences',
    [
      HomeFilter(
        'Learn',
        [
          'craft-workshop',
          'farm-experience',
          'food-experience',
          'skill-sharing',
        ],
        ['cooking', 'traditional skills'],
      ),
      HomeFilter(
        'Culture',
        ['culture', 'village-stay', 'homestay'],
        ['festival', 'heritage', 'ceremony'],
      ),
    ],
  ),
];

List<Experience> rankHomeExperiences(Iterable<Experience> experiences) {
  final unique = {
    for (final experience in experiences) experience.id: experience,
  };
  final order = unique.keys.toList();
  return unique.values.toList()..sort((a, b) {
    final rating = b.ratingAvg.compareTo(a.ratingAvg);
    if (rating != 0) return rating;
    final reviews = b.ratingCount.compareTo(a.ratingCount);
    return reviews != 0
        ? reviews
        : order.indexOf(a.id).compareTo(order.indexOf(b.id));
  });
}
