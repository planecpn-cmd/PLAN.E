import 'package:flutter_test/flutter_test.dart';
import 'package:plan_e/models/booking.dart';
import 'package:plan_e/models/review.dart';

void main() {
  group('Phase 9 - Trips and Reviews Models & Logic', () {
    test('Booking parses status and joined experience & review correctly', () {
      final json = {
        'id': 'b-100',
        'booking_ref': 'PLE-123456',
        'user_id': 'u-1',
        'experience_id': 'e-1',
        'departure_id': 'd-1',
        'adults': 2,
        'children': 1,
        'contact_name': 'Ram Thapa',
        'contact_phone': '9841234567',
        'subtotal_paisa': 1000000,
        'addons_paisa': 0,
        'fees_paisa': 0,
        'total_paisa': 1000000,
        'status': 'completed',
        'completed_at': '2026-08-01T10:00:00.000Z',
        'created_at': '2026-07-25T10:00:00.000Z',
        'updated_at': '2026-08-01T10:00:00.000Z',
        'experiences': {
          'id': 'e-1',
          'title': 'Annapurna Sunrise Trek',
          'slug': 'annapurna-sunrise-trek',
          'cover_image_url': 'https://example.com/trek.jpg',
          'price_paisa': 500000,
          'duration_hours': 72,
          'difficulty': 'moderate',
          'created_at': '2026-07-01T10:00:00.000Z',
          'updated_at': '2026-07-01T10:00:00.000Z',
        },
        'reviews': [
          {
            'id': 'r-1',
            'booking_id': 'b-100',
            'experience_id': 'e-1',
            'user_id': 'u-1',
            'rating': 5,
            'body': 'Amazing sunrise view over Annapurna!',
            'created_at': '2026-08-02T10:00:00.000Z',
            'updated_at': '2026-08-02T10:00:00.000Z',
          }
        ],
      };

      final booking = Booking.fromJson(json);

      expect(booking.id, equals('b-100'));
      expect(booking.status, equals(BookingStatus.completed));
      expect(booking.hasReview, isTrue);
      expect(booking.review?.rating, equals(5));
      expect(booking.review?.body, equals('Amazing sunrise view over Annapurna!'));
      expect(booking.experience?.title, equals('Annapurna Sunrise Trek'));
    });

    test('Booking without review hasReview returns false', () {
      final json = {
        'id': 'b-101',
        'booking_ref': 'PLE-654321',
        'user_id': 'u-1',
        'experience_id': 'e-1',
        'departure_id': 'd-1',
        'adults': 1,
        'contact_name': 'Sita Shrestha',
        'contact_phone': '9841234568',
        'subtotal_paisa': 500000,
        'total_paisa': 500000,
        'status': 'completed',
        'completed_at': '2026-08-05T10:00:00.000Z',
        'created_at': '2026-08-01T10:00:00.000Z',
        'updated_at': '2026-08-05T10:00:00.000Z',
        'reviews': [],
      };

      final booking = Booking.fromJson(json);

      expect(booking.status, equals(BookingStatus.completed));
      expect(booking.hasReview, isFalse);
      expect(booking.review, isNull);
    });

    test('Review model serialization and experience parsing', () {
      final reviewJson = {
        'id': 'r-200',
        'booking_id': 'b-200',
        'experience_id': 'e-2',
        'user_id': 'u-1',
        'rating': 4,
        'title': 'Great Homestay',
        'body': 'Warm tea and cultural hospitality in Panauti.',
        'created_at': '2026-08-04T12:00:00.000Z',
        'updated_at': '2026-08-04T12:00:00.000Z',
        'experiences': {
          'id': 'e-2',
          'title': 'Panauti Homestay',
          'slug': 'panauti-homestay',
          'location_name': 'Panauti, Kavre',
          'cover_image_url': 'https://example.com/panauti.jpg',
          'price_paisa': 300000,
          'created_at': '2026-07-01T10:00:00.000Z',
          'updated_at': '2026-07-01T10:00:00.000Z',
        },
      };

      final review = Review.fromJson(reviewJson);

      expect(review.id, equals('r-200'));
      expect(review.rating, equals(4));
      expect(review.title, equals('Great Homestay'));
      expect(review.experience?.title, equals('Panauti Homestay'));
      expect(review.experience?.locationName, equals('Panauti, Kavre'));

      final map = review.toJson();
      expect(map['rating'], equals(4));
      expect(map['booking_id'], equals('b-200'));
    });
  });
}
