enum BookingStatus {
  pending,
  confirmed,
  cancellationRequested,
  cancelled,
  completed,
  expired;

  static BookingStatus fromString(String? value) {
    switch (value) {
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'cancellation_requested':
        return BookingStatus.cancellationRequested;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'completed':
        return BookingStatus.completed;
      case 'expired':
        return BookingStatus.expired;
      case 'pending':
      default:
        return BookingStatus.pending;
    }
  }

  String toJson() {
    switch (this) {
      case BookingStatus.confirmed:
        return 'confirmed';
      case BookingStatus.cancellationRequested:
        return 'cancellation_requested';
      case BookingStatus.cancelled:
        return 'cancelled';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.expired:
        return 'expired';
      case BookingStatus.pending:
        return 'pending';
    }
  }
}

class Booking {
  final String id;
  final String bookingRef;
  final String userId;
  final String experienceId;
  final String? experienceTitle;
  final String? experienceCoverImageUrl;
  final String departureId;
  final int adults;
  final int children;
  final List<Map<String, dynamic>> addons;
  final String contactName;
  final String contactPhone;
  final int subtotalPaisa;
  final int addonsPaisa;
  final int feesPaisa;
  final int totalPaisa;
  final BookingStatus status;
  final DateTime? quoteExpiresAt;
  final bool isDraft;
  final DateTime? cancelledAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Booking({
    required this.id,
    required this.bookingRef,
    required this.userId,
    required this.experienceId,
    this.experienceTitle,
    this.experienceCoverImageUrl,
    required this.departureId,
    required this.adults,
    this.children = 0,
    this.addons = const [],
    required this.contactName,
    required this.contactPhone,
    required this.subtotalPaisa,
    this.addonsPaisa = 0,
    this.feesPaisa = 0,
    required this.totalPaisa,
    this.status = BookingStatus.pending,
    this.quoteExpiresAt,
    this.isDraft = false,
    this.cancelledAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    final experience = json['experiences'] as Map<String, dynamic>?;
    return Booking(
      id: json['id'] as String,
      bookingRef: json['booking_ref'] as String,
      userId: json['user_id'] as String,
      experienceId: json['experience_id'] as String,
      experienceTitle: experience?['title'] as String?,
      experienceCoverImageUrl: experience?['cover_image_url'] as String?,
      departureId: json['departure_id'] as String,
      adults: (json['adults'] as num).toInt(),
      children: (json['children'] as num?)?.toInt() ?? 0,
      addons:
          (json['addons'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      contactName: json['contact_name'] as String,
      contactPhone: json['contact_phone'] as String,
      subtotalPaisa: (json['subtotal_paisa'] as num).toInt(),
      addonsPaisa: (json['addons_paisa'] as num?)?.toInt() ?? 0,
      feesPaisa: (json['fees_paisa'] as num?)?.toInt() ?? 0,
      totalPaisa: (json['total_paisa'] as num).toInt(),
      status: BookingStatus.fromString(json['status'] as String?),
      quoteExpiresAt: json['quote_expires_at'] != null
          ? DateTime.parse(json['quote_expires_at'] as String)
          : null,
      isDraft: (json['is_draft'] as bool?) ?? false,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
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
      'booking_ref': bookingRef,
      'user_id': userId,
      'experience_id': experienceId,
      'departure_id': departureId,
      'adults': adults,
      'children': children,
      'addons': addons,
      'contact_name': contactName,
      'contact_phone': contactPhone,
      'subtotal_paisa': subtotalPaisa,
      'addons_paisa': addonsPaisa,
      'fees_paisa': feesPaisa,
      'total_paisa': totalPaisa,
      'status': status.toJson(),
      'quote_expires_at': quoteExpiresAt?.toIso8601String(),
      'is_draft': isDraft,
      'cancelled_at': cancelledAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
