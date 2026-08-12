// Phase 0 of docs/OFFLINE_CACHE_PLAN.md: these repository methods used to
// swallow every exception and return []/null, which meant a network failure
// was indistinguishable from "genuinely no data" — and meant the offline
// cache fallback planned for later phases could never engage, since it
// triggers on an exception that these methods never let escape. Confirms
// the fix actually throws now, against a connection that's guaranteed to
// fail (no live Supabase needed for this).
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_e/features/booking/booking_repository_service.dart';
import 'package:plan_e/features/experience/experience_detail_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  // Port 1 refuses connections immediately on every platform — fast,
  // deterministic failure, no network flakiness in CI.
  final unreachableClient = SupabaseClient(
    'http://127.0.0.1:1',
    'test-anon-key',
  );

  group('ExperienceDetailRepository propagates errors (was: swallowed)', () {
    final repo = ExperienceDetailRepository(unreachableClient);

    test('getDepartures throws instead of returning []', () {
      expect(() => repo.getDepartures('exp-1'), throwsA(anything));
    });

    test('getItinerary throws instead of returning []', () {
      expect(() => repo.getItinerary('exp-1'), throwsA(anything));
    });

    test('getReviews throws instead of returning []', () {
      expect(() => repo.getReviews('exp-1'), throwsA(anything));
    });

    test('getHostProfile throws instead of returning null', () {
      expect(() => repo.getHostProfile('host-1'), throwsA(anything));
    });
  });

  group('BookingFeatureRepository propagates errors (was: swallowed)', () {
    final repo = BookingFeatureRepository(unreachableClient);

    test('getDepartures throws instead of returning []', () {
      expect(() => repo.getDepartures('exp-1'), throwsA(anything));
    });

    test('getBookingById throws instead of returning null', () {
      expect(() => repo.getBookingById('booking-1'), throwsA(anything));
    });
  });
}
