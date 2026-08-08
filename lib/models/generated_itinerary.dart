class ItineraryPick {
  final String experienceId;
  final String title;
  final String? summary;
  final String? difficulty;
  final int durationDays;
  final int priceNpr;
  final String? region;
  final String? category;
  final String reason;

  const ItineraryPick({
    required this.experienceId,
    required this.title,
    this.summary,
    this.difficulty,
    required this.durationDays,
    required this.priceNpr,
    this.region,
    this.category,
    required this.reason,
  });

  factory ItineraryPick.fromJson(Map<String, dynamic> json) {
    return ItineraryPick(
      experienceId: json['id'] as String,
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String?,
      difficulty: json['difficulty'] as String?,
      durationDays: (json['duration_days'] as num?)?.toInt() ?? 0,
      priceNpr: (json['price_npr'] as num?)?.toInt() ?? 0,
      region: json['region'] as String?,
      category: json['category'] as String?,
      reason: json['reason'] as String? ?? '',
    );
  }
}

class GeneratedItinerary {
  final String summary;
  final String? notes;
  final List<ItineraryPick> picks;

  const GeneratedItinerary({
    required this.summary,
    this.notes,
    required this.picks,
  });

  factory GeneratedItinerary.fromJson(Map<String, dynamic> json) {
    final picksJson = json['picks'] as List<dynamic>? ?? [];
    return GeneratedItinerary(
      summary: json['summary'] as String? ?? '',
      notes: json['notes'] as String?,
      picks: picksJson
          .map((p) => ItineraryPick.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}
