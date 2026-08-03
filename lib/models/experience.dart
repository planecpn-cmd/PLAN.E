enum DifficultyLevel {
  easy,
  moderate,
  challenging,
  strenuous;

  static DifficultyLevel fromString(String? value) {
    switch (value) {
      case 'easy':
        return DifficultyLevel.easy;
      case 'challenging':
        return DifficultyLevel.challenging;
      case 'strenuous':
        return DifficultyLevel.strenuous;
      case 'moderate':
      default:
        return DifficultyLevel.moderate;
    }
  }

  String toJson() => name;
}

enum ExperienceStatus {
  draft,
  pendingReview,
  published,
  paused,
  archived;

  static ExperienceStatus fromString(String? value) {
    switch (value) {
      case 'pending_review':
        return ExperienceStatus.pendingReview;
      case 'published':
        return ExperienceStatus.published;
      case 'paused':
        return ExperienceStatus.paused;
      case 'archived':
        return ExperienceStatus.archived;
      case 'draft':
      default:
        return ExperienceStatus.draft;
    }
  }

  String toJson() {
    switch (this) {
      case ExperienceStatus.pendingReview:
        return 'pending_review';
      case ExperienceStatus.published:
        return 'published';
      case ExperienceStatus.paused:
        return 'paused';
      case ExperienceStatus.archived:
        return 'archived';
      case ExperienceStatus.draft:
        return 'draft';
    }
  }
}

class Experience {
  final String id;
  final String? hostId;
  final String? categoryId;
  final String? regionId;
  final String title;
  final String slug;
  final String? summary;
  final String? description;
  final String coverImageUrl;
  final List<String> gallery;
  final String? locationName;
  final String? meetingPoint;
  final double? lat;
  final double? lng;
  final int durationHours;
  final DifficultyLevel difficulty;
  final int? maxAltitudeM;
  final int groupSizeMin;
  final int groupSizeMax;
  final int minAge;
  final int pricePaisa;
  final int? childPricePaisa;
  final String currency;
  final List<String> included;
  final List<String> bringList;
  final List<String> thingsToKnow;
  final List<String> permitsRequired;
  final List<int> bestSeason;
  final double ratingAvg;
  final int ratingCount;
  final ExperienceStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Experience({
    required this.id,
    this.hostId,
    this.categoryId,
    this.regionId,
    required this.title,
    required this.slug,
    this.summary,
    this.description,
    required this.coverImageUrl,
    this.gallery = const [],
    this.locationName,
    this.meetingPoint,
    this.lat,
    this.lng,
    this.durationHours = 24,
    this.difficulty = DifficultyLevel.moderate,
    this.maxAltitudeM,
    this.groupSizeMin = 1,
    this.groupSizeMax = 12,
    this.minAge = 10,
    required this.pricePaisa,
    this.childPricePaisa,
    this.currency = 'NPR',
    this.included = const [],
    this.bringList = const [],
    this.thingsToKnow = const [],
    this.permitsRequired = const [],
    this.bestSeason = const [3, 4, 5, 9, 10, 11],
    this.ratingAvg = 0.0,
    this.ratingCount = 0,
    this.status = ExperienceStatus.draft,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Experience.fromJson(Map<String, dynamic> json) {
    return Experience(
      id: json['id'] as String,
      hostId: json['host_id'] as String?,
      categoryId: json['category_id'] as String?,
      regionId: json['region_id'] as String?,
      title: json['title'] as String,
      slug: json['slug'] as String,
      summary: json['summary'] as String?,
      description: json['description'] as String?,
      coverImageUrl: json['cover_image_url'] as String,
      gallery: (json['gallery'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      locationName: json['location_name'] as String?,
      meetingPoint: json['meeting_point'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      durationHours: (json['duration_hours'] as num?)?.toInt() ?? 24,
      difficulty: DifficultyLevel.fromString(json['difficulty'] as String?),
      maxAltitudeM: (json['max_altitude_m'] as num?)?.toInt(),
      groupSizeMin: (json['group_size_min'] as num?)?.toInt() ?? 1,
      groupSizeMax: (json['group_size_max'] as num?)?.toInt() ?? 12,
      minAge: (json['min_age'] as num?)?.toInt() ?? 10,
      pricePaisa: (json['price_paisa'] as num).toInt(),
      childPricePaisa: (json['child_price_paisa'] as num?)?.toInt(),
      currency: (json['currency'] as String?) ?? 'NPR',
      included: (json['included'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      bringList: (json['bring_list'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      thingsToKnow: (json['things_to_know'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      permitsRequired: (json['permits_required'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      bestSeason: (json['best_season'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ?? const [3, 4, 5, 9, 10, 11],
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
      status: ExperienceStatus.fromString(json['status'] as String?),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'host_id': hostId,
      'category_id': categoryId,
      'region_id': regionId,
      'title': title,
      'slug': slug,
      'summary': summary,
      'description': description,
      'cover_image_url': coverImageUrl,
      'gallery': gallery,
      'location_name': locationName,
      'meeting_point': meetingPoint,
      'lat': lat,
      'lng': lng,
      'duration_hours': durationHours,
      'difficulty': difficulty.toJson(),
      'max_altitude_m': maxAltitudeM,
      'group_size_min': groupSizeMin,
      'group_size_max': groupSizeMax,
      'min_age': minAge,
      'price_paisa': pricePaisa,
      'child_price_paisa': childPricePaisa,
      'currency': currency,
      'included': included,
      'bring_list': bringList,
      'things_to_know': thingsToKnow,
      'permits_required': permitsRequired,
      'best_season': bestSeason,
      'rating_avg': ratingAvg,
      'rating_count': ratingCount,
      'status': status.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
