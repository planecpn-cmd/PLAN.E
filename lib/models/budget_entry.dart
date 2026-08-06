class BudgetEntry {
  final String id;
  final String bookingId;
  final String label;
  final int amountPaisa;
  final String category;
  final DateTime spentOn;
  final DateTime createdAt;

  const BudgetEntry({
    required this.id,
    required this.bookingId,
    required this.label,
    required this.amountPaisa,
    this.category = 'Miscellaneous',
    required this.spentOn,
    required this.createdAt,
  });

  factory BudgetEntry.fromJson(Map<String, dynamic> json) {
    return BudgetEntry(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      label: json['label'] as String,
      amountPaisa: (json['amount_paisa'] as num).toInt(),
      category: json['category'] as String? ?? 'Miscellaneous',
      spentOn: json['spent_on'] != null
          ? DateTime.parse(json['spent_on'] as String)
          : DateTime.now().toUtc(),
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
      'amount_paisa': amountPaisa,
      'category': category,
      'spent_on': spentOn.toIso8601String().split('T').first,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  BudgetEntry copyWith({
    String? id,
    String? bookingId,
    String? label,
    int? amountPaisa,
    String? category,
    DateTime? spentOn,
    DateTime? createdAt,
  }) {
    return BudgetEntry(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      label: label ?? this.label,
      amountPaisa: amountPaisa ?? this.amountPaisa,
      category: category ?? this.category,
      spentOn: spentOn ?? this.spentOn,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
