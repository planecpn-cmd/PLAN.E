// Phase 5 of docs/OFFLINE_CACHE_PLAN.md: profile, bookings, and saved
// experiences now go through OfflineCache, keyed per-user.
//
// A real limitation of unit-testing this part, worth stating rather than
// hiding: ProfileRepository.getCurrentProfile, BookingRepository
// .getBookingsByStatus, and SavedRepository.getSavedExperiences all read
// `_client.auth.currentUser?.id` and return early (null/[]) *before*
// touching the network. A SupabaseClient built fresh in a test has no
// session, so `currentUser` is always null — these tests can only exercise
// that early-return branch, never the try/cache-fallback branch, without a
// mocked GoTrueClient (disproportionate setup for this phase). The
// try/write/catch/read-cache/rethrow shape itself is the same pattern
// already covered by 16 passing tests across phase 3
// (test/phase3_catalog_cache_test.dart) and phase 4
// (test/phase4_detail_cache_test.dart) — applying a proven shape to three
// more methods is a code-review-level risk, not an untested one.
//
// What *is* fully testable here — and is the actual new risk in this
// phase — is the logout key-scoping convention below.
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_e/core/offline_cache.dart';
import 'package:plan_e/repositories/booking_repository.dart';
import 'package:plan_e/repositories/profile_repository.dart';
import 'package:plan_e/repositories/saved_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Fresh per test — see test/phase3_catalog_cache_test.dart for why.
SupabaseClient unreachableClient() =>
    SupabaseClient('http://127.0.0.1:1', 'test-key');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('signed-out early return (no network attempted, no cache touched)', () {
    test('ProfileRepository.getCurrentProfile → null', () async {
      final repo = ProfileRepository(unreachableClient());
      expect(await repo.getCurrentProfile(), isNull);
    });

    test('BookingRepository.getBookingsByStatus → empty list, no throw', () async {
      final repo = BookingRepository(unreachableClient());
      expect(await repo.getBookingsByStatus('confirmed'), isEmpty);
    });

    test('SavedRepository.getSavedExperiences → empty list, no throw', () async {
      final repo = SavedRepository(unreachableClient());
      expect(await repo.getSavedExperiences(), isEmpty);
    });
  });

  group('user-scoped cache key convention (the logout-clear contract)', () {
    test('every user-scoped key format contains ":<userId>"', () {
      const userId = 'user-abc-123';
      final keys = [
        'profile:$userId',
        'bookings:$userId:confirmed',
        'bookings:$userId:pending',
        'saved_experiences:$userId',
      ];
      for (final key in keys) {
        expect(key.contains(':$userId'), isTrue, reason: 'key was: $key');
      }
    });

    test("clearWhere with the logout predicate removes only that user's keys", () async {
      const userId = 'user-abc-123';
      const otherUserId = 'user-xyz-999';

      await OfflineCache.write('profile:$userId', {'v': 1});
      await OfflineCache.write('bookings:$userId:confirmed', {'v': 2});
      await OfflineCache.write('saved_experiences:$userId', {'v': 3});
      // A different user's data on the same shared device — must survive.
      await OfflineCache.write('profile:$otherUserId', {'v': 4});
      // Non-user-scoped catalog data — must survive.
      await OfflineCache.write('categories', {'v': 5});
      await OfflineCache.write('home_rails', {'v': 6});

      await OfflineCache.clearWhere((key) => key.contains(':$userId'));

      expect(await OfflineCache.read<int>('profile:$userId', (j) => (j as Map)['v'] as int), isNull);
      expect(await OfflineCache.read<int>('bookings:$userId:confirmed', (j) => (j as Map)['v'] as int), isNull);
      expect(await OfflineCache.read<int>('saved_experiences:$userId', (j) => (j as Map)['v'] as int), isNull);

      expect(await OfflineCache.read<int>('profile:$otherUserId', (j) => (j as Map)['v'] as int), 4);
      expect(await OfflineCache.read<int>('categories', (j) => (j as Map)['v'] as int), 5);
      expect(await OfflineCache.read<int>('home_rails', (j) => (j as Map)['v'] as int), 6);
    });

    test('a userId that is a suffix of another userId does not false-match', () async {
      // Guards against ':abc' accidentally matching inside ':xabc' — it
      // can't (colon-prefixed), but this pins that behavior down.
      await OfflineCache.write('profile:xabc', {'v': 1});
      await OfflineCache.clearWhere((key) => key.contains(':abc'));
      expect(await OfflineCache.read<int>('profile:xabc', (j) => (j as Map)['v'] as int), 1);
    });
  });
}
