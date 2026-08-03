enum PaymentProvider {
  khalti,
  esewa;

  static PaymentProvider fromString(String? value) {
    switch (value) {
      case 'esewa':
        return PaymentProvider.esewa;
      case 'khalti':
      default:
        return PaymentProvider.khalti;
    }
  }

  String toJson() => name;
}

enum PaymentStatus {
  initiated,
  paid,
  failed,
  refunded;

  static PaymentStatus fromString(String? value) {
    switch (value) {
      case 'paid':
        return PaymentStatus.paid;
      case 'failed':
        return PaymentStatus.failed;
      case 'refunded':
        return PaymentStatus.refunded;
      case 'initiated':
      default:
        return PaymentStatus.initiated;
    }
  }

  String toJson() => name;
}

class Payment {
  final String id;
  final String bookingId;
  final PaymentProvider provider;
  final String? providerRef;
  final String idempotencyKey;
  final int amountPaisa;
  final PaymentStatus status;
  final Map<String, dynamic> rawResponse;
  final DateTime? paidAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Payment({
    required this.id,
    required this.bookingId,
    required this.provider,
    this.providerRef,
    required this.idempotencyKey,
    required this.amountPaisa,
    this.status = PaymentStatus.initiated,
    this.rawResponse = const {},
    this.paidAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      provider: PaymentProvider.fromString(json['provider'] as String?),
      providerRef: json['provider_ref'] as String?,
      idempotencyKey: json['idempotency_key'] as String,
      amountPaisa: (json['amount_paisa'] as num).toInt(),
      status: PaymentStatus.fromString(json['status'] as String?),
      rawResponse: json['raw_response'] != null
          ? Map<String, dynamic>.from(json['raw_response'] as Map)
          : const {},
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
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
      'booking_id': bookingId,
      'provider': provider.toJson(),
      'provider_ref': providerRef,
      'idempotency_key': idempotencyKey,
      'amount_paisa': amountPaisa,
      'status': status.toJson(),
      'raw_response': rawResponse,
      'paid_at': paidAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
