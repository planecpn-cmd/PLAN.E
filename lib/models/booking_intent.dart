import 'booking.dart';

class BookingIntentResult {
  final String bookingId;
  final String bookingRef;
  final String idempotencyKey;
  final DateTime quoteExpiresAt;
  final int subtotalPaisa;
  final int feesPaisa;
  final int totalPaisa;
  final String provider;
  final Booking? booking;

  const BookingIntentResult({
    required this.bookingId,
    required this.bookingRef,
    required this.idempotencyKey,
    required this.quoteExpiresAt,
    required this.subtotalPaisa,
    required this.feesPaisa,
    required this.totalPaisa,
    required this.provider,
    this.booking,
  });

  factory BookingIntentResult.fromJson(Map<String, dynamic> json) {
    Booking? booking;
    if (json['booking'] != null && json['booking'] is Map<String, dynamic>) {
      booking = Booking.fromJson(json['booking'] as Map<String, dynamic>);
    }

    final paymentIntent = json['payment_intent'] is Map<String, dynamic>
        ? json['payment_intent'] as Map<String, dynamic>
        : <String, dynamic>{};

    final String idempotencyKey = (json['idempotency_key'] ?? paymentIntent['idempotency_key'] ?? '') as String;
    final String provider = (json['provider'] ?? paymentIntent['provider'] ?? 'khalti') as String;
    final String expiresStr = (json['quote_expires_at'] ?? paymentIntent['expires_at'] ?? DateTime.now().add(const Duration(minutes: 15)).toIso8601String()) as String;

    return BookingIntentResult(
      bookingId: (json['booking_id'] ?? paymentIntent['booking_id'] ?? '') as String,
      bookingRef: (json['booking_ref'] ?? '') as String,
      idempotencyKey: idempotencyKey,
      quoteExpiresAt: DateTime.tryParse(expiresStr) ?? DateTime.now().add(const Duration(minutes: 15)),
      subtotalPaisa: (json['subtotal_paisa'] as num?)?.toInt() ?? (paymentIntent['subtotal_paisa'] as num?)?.toInt() ?? 0,
      feesPaisa: (json['fees_paisa'] as num?)?.toInt() ?? (paymentIntent['fees_paisa'] as num?)?.toInt() ?? 0,
      totalPaisa: (json['total_paisa'] as num?)?.toInt() ??
          (json['amount_paisa'] as num?)?.toInt() ??
          (paymentIntent['amount_paisa'] as num?)?.toInt() ??
          (paymentIntent['total_paisa'] as num?)?.toInt() ??
          0,
      provider: provider,
      booking: booking,
    );
  }
}
