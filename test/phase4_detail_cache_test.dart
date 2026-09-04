// Phase 4 of docs/OFFLINE_CACHE_PLAN.md: experience detail + its
// departures/itinerary/reviews/host-profile now go through OfflineCache.
// This is the phase that depends on phase 0's fix actually holding — these
// four ExperienceRepository detail methods used to swallow every exception
// and return []/null, which would have made the cache fallback below
// unreachable dead code.
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_e/core/offline_cache.dart';
import 'package:plan_e/repositories/experience_repository.dart';
import 'package:plan_e/models/experience_departure.dart';
import 'package:plan_e/models/itinerary_item.dart';
import 'package:plan_e/models/profile.dart';
import 'package:plan_e/models/review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Constructed fresh inside each test — see test/phase3_catalog_cache_test.dart
// for why (TestWidgetsFlutterBinding's HTTP mock only applies inside a
// running test's zone, and SupabaseClient builds its http.Client eagerly).
SupabaseClient unreachableClient() =>
    SupabaseClient('http://127.0.0.1:1', 'test-key');

final _now = DateTime.utc(2026, 1, 1);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ExperienceRepository.getExperienceById', () {
    test(
      'network fails, cache has data → returns the cached experience',
      () async {
        await OfflineCache.write('experience_detail:exp-1', {
          'id': 'exp-1',
          'title': 'Everest Base Camp Trek',
          'slug': 'ebc-trek',
          'cover_image_url': 'https://example.com/x.jpg',
          'price_paisa': 500000,
          'created_at': _now.toIso8601String(),
          'updated_at': _now.toIso8601String(),
        });

        final repo = ExperienceRepository(unreachableClient());
        final experience = await repo.getExperienceById('exp-1');

        expect(experience, isNotNull);
        expect(experience!.title, 'Everest Base Camp Trek');
      },
    );

    test('network fails, no cache → rethrows', () async {
      final repo = ExperienceRepository(unreachableClient());
      expect(() => repo.getExperienceById('exp-1'), throwsA(anything));
    });
  });

  group('ExperienceRepository.getDepartures', () {
    test(
      'network fails, cache has data → returns the cached departures',
      () async {
        await OfflineCache.write('experience_departures:exp-1', [
          ExperienceDeparture(
            id: 'dep-1',
            experienceId: 'exp-1',
            startDate: _now,
            endDate: _now.add(const Duration(days: 5)),
            totalSpots: 10,
            spotsLeft: 3,
            createdAt: _now,
          ).toJson(),
        ]);

        final repo = ExperienceRepository(unreachableClient());
        final departures = await repo.getDepartures('exp-1');

        expect(departures, hasLength(1));
        expect(departures.first.spotsLeft, 3);
      },
    );

    test(
      'network fails, no cache → rethrows (phase 0 fix must hold)',
      () async {
        final repo = ExperienceRepository(unreachableClient());
        expect(() => repo.getDepartures('exp-1'), throwsA(anything));
      },
    );
  });

  group('ExperienceRepository.getItinerary', () {
    test(
      'network fails, cache has data → returns the cached itinerary',
      () async {
        await OfflineCache.write('experience_itinerary:exp-1', [
          ItineraryItem(
            id: 'day-1',
            experienceId: 'exp-1',
            dayNumber: 1,
            title: 'Fly to Lukla, trek to Phakding',
            createdAt: _now,
          ).toJson(),
        ]);

        final repo = ExperienceRepository(unreachableClient());
        final itinerary = await repo.getItinerary('exp-1');

        expect(itinerary, hasLength(1));
        expect(itinerary.first.title, 'Fly to Lukla, trek to Phakding');
      },
    );

    test(
      'network fails, no cache → rethrows (phase 0 fix must hold)',
      () async {
        final repo = ExperienceRepository(unreachableClient());
        expect(() => repo.getItinerary('exp-1'), throwsA(anything));
      },
    );
  });

  group('ExperienceRepository.getReviews', () {
    test(
      'network fails, cache has data → returns the cached reviews',
      () async {
        await OfflineCache.write('experience_reviews:v2:exp-1', [
          Review(
            id: 'rev-1',
            experienceId: 'exp-1',
            rating: 5,
            body: 'Incredible trek, highly recommend.',
            createdAt: _now,
            updatedAt: _now,
          ).toJson(),
        ]);

        final repo = ExperienceRepository(unreachableClient());
        final reviews = await repo.getReviews('exp-1');

        expect(reviews, hasLength(1));
        expect(reviews.first.rating, 5);
      },
    );

    test(
      'network fails, no cache → rethrows (phase 0 fix must hold)',
      () async {
        final repo = ExperienceRepository(unreachableClient());
        expect(() => repo.getReviews('exp-1'), throwsA(anything));
      },
    );
  });

  group('ExperienceRepository.getHostProfile', () {
    test(
      'network fails, cache has data → returns the cached host profile',
      () async {
        await OfflineCache.write(
          'host_profile:host-1',
          Profile(
            id: 'host-1',
            fullName: 'Siddharth Gurung',
            createdAt: _now,
            updatedAt: _now,
          ).toJson(),
        );

        final repo = ExperienceRepository(unreachableClient());
        final profile = await repo.getHostProfile('host-1');

        expect(profile, isNotNull);
        expect(profile!.fullName, 'Siddharth Gurung');
      },
    );

    test(
      'network fails, no cache → rethrows (phase 0 fix must hold)',
      () async {
        final repo = ExperienceRepository(unreachableClient());
        expect(() => repo.getHostProfile('host-1'), throwsA(anything));
      },
    );
  });
}
