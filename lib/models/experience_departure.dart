class ExperienceDeparture {
  final String id;
  final String experienceId;
  final DateTime startDate;
  final DateTime endDate;
  final int totalSpots;
  final int spotsLeft;
  final int? priceOverridePaisa;
  final String status;
  final DateTime createdAt;

  const ExperienceDeparture({
    required this.id,
    required this.experienceId,
    required this.startDate,
    required this.endDate,
    required this.totalSpots,
    required this.spotsLeft,
    this.priceOverridePaisa,
    this.status = 'open',
    required this.createdAt,
  });

  factory ExperienceDeparture.fromJson(Map<String, dynamic> json) {
    return ExperienceDeparture(
      id: json['id'] as String,
      experienceId: json['experience_id'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      totalSpots: (json['total_spots'] as num).toInt(),
      spotsLeft: (json['spots_left'] as num).toInt(),
      priceOverridePaisa: (json['price_override_paisa'] as num?)?.toInt(),
      status: (json['status'] as String?) ?? 'open',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'experience_id': experienceId,
      'start_date': "${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}",
      'end_date': "${endDate.year.toString().padLeft(4, '0')}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}",
      'total_spots': totalSpots,
      'spots_left': spotsLeft,
      'price_override_paisa': priceOverridePaisa,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ExperienceDeparture copyWith({
    String? id,
    String? experienceId,
    DateTime? startDate,
    DateTime? endDate,
    int? totalSpots,
    int? spotsLeft,
    int? priceOverridePaisa,
    String? status,
    DateTime? createdAt,
  }) {
    return ExperienceDeparture(
      id: id ?? this.id,
      experienceId: experienceId ?? this.experienceId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalSpots: totalSpots ?? this.totalSpots,
      spotsLeft: spotsLeft ?? this.spotsLeft,
      priceOverridePaisa: priceOverridePaisa ?? this.priceOverridePaisa,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
