class GearChecklistItem {
  final String id;
  final String bookingId;
  final String label;
  final bool isChecked;
  final bool isCustom;
  final int sortOrder;
  final DateTime createdAt;

  const GearChecklistItem({
    required this.id,
    required this.bookingId,
    required this.label,
    this.isChecked = false,
    this.isCustom = false,
    this.sortOrder = 0,
    required this.createdAt,
  });

  factory GearChecklistItem.fromJson(Map<String, dynamic> json) {
    return GearChecklistItem(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      label: json['label'] as String,
      isChecked: json['is_checked'] as bool? ?? false,
      isCustom: json['is_custom'] as bool? ?? false,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'label': label,
      'is_checked': isChecked,
      'is_custom': isCustom,
      'sort_order': sortOrder,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  GearChecklistItem copyWith({
    String? id,
    String? bookingId,
    String? label,
    bool? isChecked,
    bool? isCustom,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return GearChecklistItem(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      label: label ?? this.label,
      isChecked: isChecked ?? this.isChecked,
      isCustom: isCustom ?? this.isCustom,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
