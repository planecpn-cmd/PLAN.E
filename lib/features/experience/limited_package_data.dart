import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/category.dart';
import '../../models/experience.dart';
import '../../models/experience_departure.dart';
import '../../models/region.dart';

enum DetailPresentationType { limited, full }

// Existing category slugs, not invented IDs. Climbing includes peak expeditions.
const limitedCategorySlugs = {
  'trekking',
  'climbing',
  'multi-day-tour',
  'travel-package',
};

DetailPresentationType detailPresentationFor(Category? category) =>
    category == null || limitedCategorySlugs.contains(category.slug)
    ? DetailPresentationType.limited
    : DetailPresentationType.full;

/// Only editorially reviewed customer-facing copy belongs in this model.
/// Never populate it by copying unrestricted itinerary/host/vendor descriptions.
/// The current schema has no reviewed public package content or option catalogue.
final limitedPackageContentProvider =
    Provider.family<LimitedPackageContent, String>(
      (ref, id) => const LimitedPackageContent(),
    );

class LimitedPackageContent {
  final String? startingPoint;
  final String? totalDistance;
  final List<BasicItineraryStage> stages;
  final List<String> checklist;
  final List<String> thingsToKnow;
  final List<String> inclusions;
  final List<PackageOption> options;
  const LimitedPackageContent({
    this.startingPoint,
    this.totalDistance,
    this.stages = const [],
    this.checklist = const [],
    this.thingsToKnow = const [],
    this.inclusions = const [],
    this.options = const [],
  });
}

class BasicItineraryStage {
  final int day;
  final String route;
  final String? distance;
  final String? altitude;
  final String? walkingTime;
  final List<String> highlights;
  const BasicItineraryStage({
    required this.day,
    required this.route,
    this.distance,
    this.altitude,
    this.walkingTime,
    this.highlights = const [],
  });
}

class PackageOption {
  final String id;
  final String label;
  final String group;
  final bool required;
  // Non-null means options in this group are mutually exclusive.
  final String? exclusiveGroup;
  final bool allowsNote;
  const PackageOption({
    required this.id,
    required this.label,
    required this.group,
    this.required = false,
    this.exclusiveGroup,
    this.allowsNote = false,
  });
}

/// Narrow projection: no host, meeting point, coordinates, unrestricted prose,
/// review bodies, supplier information, or raw itinerary objects reach the view.
class LimitedPackageData {
  final String title;
  final String category;
  final String? region;
  final List<String> photos;
  final int durationHours;
  final int groupMin;
  final int groupMax;
  final String difficulty;
  final int? maxAltitudeM;
  final List<int> bestSeason;
  final int minAge;
  final int pricePaisa;
  final String currency;
  final double rating;
  final int reviewCount;

  LimitedPackageData.from(
    Experience experience,
    Category? category,
    Region? region,
  ) : title = experience.title,
      category = category?.nameEn ?? 'Package',
      region = region?.nameEn,
      photos = {
        experience.coverImageUrl,
        ...experience.gallery,
      }.where((url) => url.isNotEmpty).toList(growable: false),
      durationHours = experience.durationHours,
      groupMin = experience.groupSizeMin,
      groupMax = experience.groupSizeMax,
      difficulty = experience.difficulty.name,
      maxAltitudeM = experience.maxAltitudeM,
      bestSeason =
          experience.bestSeason.where((m) => m >= 1 && m <= 12).toSet().toList()
            ..sort(),
      minAge = experience.minAge,
      pricePaisa = experience.pricePaisa,
      currency = experience.currency,
      rating = experience.ratingAvg,
      reviewCount = experience.ratingCount;
}

ExperienceDeparture? nextPackageDeparture(
  List<ExperienceDeparture> departures,
  DateTime now,
) {
  final today = DateTime(now.year, now.month, now.day);
  final upcoming =
      departures
          .where(
            (d) =>
                d.status == 'open' &&
                d.spotsLeft > 0 &&
                !DateTime(
                  d.startDate.year,
                  d.startDate.month,
                  d.startDate.day,
                ).isBefore(today),
          )
          .toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));
  return upcoming.isEmpty ? null : upcoming.first;
}
