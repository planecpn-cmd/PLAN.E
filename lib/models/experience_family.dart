import 'category.dart';

class ExperienceFamily {
  final String id;
  final String slug;
  final String nameEn;
  final String nameNe;
  final String description;
  final String? icon;
  final String? coverImageUrl;
  final int sortOrder;
  final DateTime createdAt;

  const ExperienceFamily({
    required this.id,
    required this.slug,
    required this.nameEn,
    required this.nameNe,
    required this.description,
    this.icon,
    this.coverImageUrl,
    this.sortOrder = 0,
    required this.createdAt,
  });

  factory ExperienceFamily.fromJson(Map<String, dynamic> json) {
    return ExperienceFamily(
      id: json['id'] as String,
      slug: json['slug'] as String,
      nameEn: json['name_en'] as String,
      nameNe: json['name_ne'] as String,
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'slug': slug,
    'name_en': nameEn,
    'name_ne': nameNe,
    'description': description,
    'icon': icon,
    'cover_image_url': coverImageUrl,
    'sort_order': sortOrder,
    'created_at': createdAt.toIso8601String(),
  };
}

final DateTime _fallbackCreatedAt = DateTime.utc(2026, 8, 21);

final List<ExperienceFamily> defaultExperienceFamilies = [
  ExperienceFamily(
    id: 'trips-tours',
    slug: 'trips-tours',
    nameEn: 'Trips & Tours',
    nameNe: 'यात्रा तथा भ्रमण',
    description: 'Day trips, guided tours, packages, and sightseeing.',
    icon: 'route',
    sortOrder: 1,
    createdAt: _fallbackCreatedAt,
  ),
  ExperienceFamily(
    id: 'adventure-together',
    slug: 'adventure-together',
    nameEn: 'Adventure Together',
    nameNe: 'सँगै साहसिक यात्रा',
    description: 'Outdoor adventures made for sharing.',
    icon: 'groups',
    sortOrder: 2,
    createdAt: _fallbackCreatedAt,
  ),
  ExperienceFamily(
    id: 'live-like-a-local',
    slug: 'live-like-a-local',
    nameEn: 'Live Like a Local',
    nameNe: 'स्थानीय जस्तै बाँच्नुहोस्',
    description: 'Food, homes, villages, culture, and crafts.',
    icon: 'home',
    sortOrder: 3,
    createdAt: _fallbackCreatedAt,
  ),
  ExperienceFamily(
    id: 'mind-soul',
    slug: 'mind-soul',
    nameEn: 'Mind & Soul',
    nameNe: 'मन र आत्मा',
    description: 'Wellness, reflection, healing, and creativity.',
    icon: 'self_improvement',
    sortOrder: 4,
    createdAt: _fallbackCreatedAt,
  ),
  ExperienceFamily(
    id: 'meet-people',
    slug: 'meet-people',
    nameEn: 'Meet People',
    nameNe: 'मानिसहरू भेट्नुहोस्',
    description: 'Meetups, activities, events, and communities.',
    icon: 'diversity_3',
    sortOrder: 5,
    createdAt: _fallbackCreatedAt,
  ),
  ExperienceFamily(
    id: 'give-back',
    slug: 'give-back',
    nameEn: 'Give Back',
    nameNe: 'योगदान दिनुहोस्',
    description: 'Community, conservation, and meaningful impact.',
    icon: 'volunteer_activism',
    sortOrder: 6,
    createdAt: _fallbackCreatedAt,
  ),
];

const Map<String, String> fallbackFamilySlugByCategorySlug = {
  'day-trip': 'trips-tours',
  'guided-tour': 'trips-tours',
  'multi-day-tour': 'trips-tours',
  'travel-package': 'trips-tours',
  'trekking': 'adventure-together',
  'hiking': 'adventure-together',
  'camping': 'adventure-together',
  'climbing': 'adventure-together',
  'wildlife': 'adventure-together',
  'homestay': 'live-like-a-local',
  'culture': 'live-like-a-local',
  'food-experience': 'live-like-a-local',
  'village-stay': 'live-like-a-local',
  'farm-experience': 'live-like-a-local',
  'craft-workshop': 'live-like-a-local',
  'wellness': 'mind-soul',
  'yoga': 'mind-soul',
  'meditation': 'mind-soul',
  'wellness-retreat': 'mind-soul',
  'creative-workshop': 'mind-soul',
  'meetup': 'meet-people',
  'group-activity': 'meet-people',
  'community-event': 'meet-people',
  'volunteering': 'give-back',
  'volunteer-project': 'give-back',
  'conservation-project': 'give-back',
  'skill-sharing': 'give-back',
};

class ExperienceTaxonomy {
  final Map<String, Category> categoriesById;
  final Map<String, ExperienceFamily> familiesById;
  final Map<String, ExperienceFamily> familiesBySlug;

  ExperienceTaxonomy({
    required List<Category> categories,
    required List<ExperienceFamily> families,
  }) : categoriesById = {
         for (final category in categories) category.id: category,
       },
       familiesById = {for (final family in families) family.id: family},
       familiesBySlug = {for (final family in families) family.slug: family};

  Category? categoryFor(String? categoryId) => categoriesById[categoryId];

  ExperienceFamily? familyFor(String? categoryId) {
    final category = categoryFor(categoryId);
    if (category == null) return null;
    return familiesById[category.familyId] ??
        familiesBySlug[fallbackFamilySlugByCategorySlug[category.slug]];
  }
}
