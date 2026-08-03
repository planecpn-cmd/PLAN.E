class ItineraryItem {
  final String id;
  final String experienceId;
  final int dayNumber;
  final String? startTime;
  final String title;
  final String? description;
  final int sortOrder;
  final DateTime createdAt;

  const ItineraryItem({
    required this.id,
    required this.experienceId,
    required this.dayNumber,
    this.startTime,
    required this.title,
    this.description,
    this.sortOrder = 0,
    required this.createdAt,
  });

  factory ItineraryItem.fromJson(Map<String, dynamic> json) {
    return ItineraryItem(
      id: json['id'] as String,
      experienceId: json['experience_id'] as String,
      dayNumber: (json['day_number'] as num).toInt(),
      startTime: json['start_time'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'experience_id': experienceId,
      'day_number': dayNumber,
      'start_time': startTime,
      'title': title,
      'description': description,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ItineraryItem copyWith({
    String? id,
    String? experienceId,
    int? dayNumber,
    String? startTime,
    String? title,
    String? description,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return ItineraryItem(
      id: id ?? this.id,
      experienceId: experienceId ?? this.experienceId,
      dayNumber: dayNumber ?? this.dayNumber,
      startTime: startTime ?? this.startTime,
      title: title ?? this.title,
      description: description ?? this.description,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
