import 'package:flutter_test/flutter_test.dart';
import 'package:plan_e/core/format.dart';
import 'package:plan_e/models/booking.dart';
import 'package:plan_e/models/booking_intent.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Booking Intent & Payment Unit Tests', () {
    test('BookingIntentResult deserializes json correctly', () {
      final json = {
        'success': true,
        'booking_id': 'bkg-101',
        'booking_ref': 'PLE-982134',
        'idempotency_key': 'intent_test_123',
        'quote_expires_at': '2026-08-06T12:30:00.000Z',
        'subtotal_paisa': 1000000,
        'fees_paisa': 50000,
        'total_paisa': 1050000,
        'provider': 'khalti',
      };

      final intent = BookingIntentResult.fromJson(json);

      expect(intent.bookingId, equals('bkg-101'));
      expect(intent.bookingRef, equals('PLE-982134'));
      expect(intent.idempotencyKey, equals('intent_test_123'));
      expect(intent.subtotalPaisa, equals(1000000));
      expect(intent.feesPaisa, equals(50000));
      expect(intent.totalPaisa, equals(1050000));
      expect(intent.provider, equals('khalti'));
      expect(AppFormatters.formatNpr(intent.totalPaisa), equals('Rs. 10,500'));
    });

    test('BookingIntentResult handles nested payment_intent structure', () {
      final json = {
        'success': true,
        'booking_id': 'bkg-202',
        'booking_ref': 'PLE-123456',
        'payment_intent': {
          'idempotency_key': 'intent_nested_999',
          'booking_id': 'bkg-202',
          'amount_paisa': 2100000,
          'provider': 'esewa',
          'expires_at': '2026-08-06T12:45:00.000Z',
        },
      };

      final intent = BookingIntentResult.fromJson(json);

      expect(intent.bookingId, equals('bkg-202'));
      expect(intent.idempotencyKey, equals('intent_nested_999'));
      expect(intent.totalPaisa, equals(2100000));
      expect(intent.provider, equals('esewa'));
      expect(AppFormatters.formatNpr(intent.totalPaisa), equals('Rs. 21,000'));
    });

    test('BookingStatus string conversion handles all values', () {
      expect(BookingStatus.fromString('pending'), equals(BookingStatus.pending));
      expect(BookingStatus.fromString('confirmed'), equals(BookingStatus.confirmed));
      expect(BookingStatus.fromString('cancelled'), equals(BookingStatus.cancelled));
      expect(BookingStatus.fromString('completed'), equals(BookingStatus.completed));
      expect(BookingStatus.fromString('expired'), equals(BookingStatus.expired));
      expect(BookingStatus.fromString('cancellation_requested'), equals(BookingStatus.cancellationRequested));

      expect(BookingStatus.pending.toJson(), equals('pending'));
      expect(BookingStatus.confirmed.toJson(), equals('confirmed'));
    });
  });
}
