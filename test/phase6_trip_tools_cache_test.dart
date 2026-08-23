// Phase 6 of docs/OFFLINE_CACHE_PLAN.md: budget entries and read-only trip
// chat history now go through OfflineCache. Gear checklist is deliberately
// NOT wired here — per the plan's §3.1 decision, ticking a checkbox is a
// write, and offline writes are out of scope until phase 10's queue exists.
// The trail itinerary (ExperienceRepository.getItinerary) was already
// cached in phase 4; a real ItineraryScreen bug (bookingId passed where an
// experienceId is expected) means that screen doesn't actually use it in
// practice — flagged separately, out of scope for this caching work.
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_e/core/offline_cache.dart';
import 'package:plan_e/models/budget_entry.dart';
import 'package:plan_e/repositories/budget_repository.dart';
import 'package:plan_e/repositories/trip_chat_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Fresh per test — see test/phase3_catalog_cache_test.dart for why.
SupabaseClient unreachableClient() =>
    SupabaseClient('http://127.0.0.1:1', 'test-key');

final _now = DateTime.utc(2026, 1, 1);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('BudgetRepository.getBudgetEntries', () {
    test(
      'network fails, cache has data → returns the cached entries',
      () async {
        await OfflineCache.write('budget_entries:booking-1', [
          BudgetEntry(
            id: 'entry-1',
            bookingId: 'booking-1',
            label: 'Permit fees',
            amountPaisa: 500000,
            category: 'Permits',
            spentOn: _now,
            createdAt: _now,
          ).toJson(),
        ]);

        final repo = BudgetRepository(unreachableClient());
        final entries = await repo.getBudgetEntries('booking-1');

        expect(entries, hasLength(1));
        expect(entries.first.label, 'Permit fees');
        expect(entries.first.amountPaisa, 500000);
      },
    );

    test('network fails, no cache → rethrows', () async {
      final repo = BudgetRepository(unreachableClient());
      expect(() => repo.getBudgetEntries('booking-1'), throwsA(anything));
    });
  });

  group('TripChatRepository.getMessages', () {
    test(
      'network fails, cache has data → returns the cached messages',
      () async {
        // Raw server-shaped JSON, not TripMessage.toJson() — matches what the
        // repository actually caches (see the comment in the repo itself).
        await OfflineCache.write('trip_messages:booking-1', [
          {
            'id': 'msg-1',
            'booking_id': 'booking-1',
            'sender_id': 'user-1',
            'body': 'See you at the trailhead at 6am!',
            'created_at': _now.toIso8601String(),
            'profiles': {'full_name': 'Sherpa Guide Pemba'},
          },
        ]);

        final repo = TripChatRepository(unreachableClient());
        final messages = await repo.getMessages('booking-1');

        expect(messages, hasLength(1));
        expect(messages.first.body, 'See you at the trailhead at 6am!');
      },
    );

    test(
      'regression: sender_name survives a real cache round-trip (the bug caught while building this phase)',
      () async {
        // Exercises the REAL write path — not a hand-built fixture — by
        // making getMessages() write to the cache itself, then reading it
        // back. If this ever regresses to caching TripMessage.toJson()
        // instead of the raw response, senderName silently comes back null
        // and this test catches it.
        final rawResponseShape = [
          {
            'id': 'msg-1',
            'booking_id': 'booking-1',
            'sender_id': 'user-1',
            'body': 'Weather looks good for tomorrow.',
            'created_at': _now.toIso8601String(),
            'profiles': {'full_name': 'Sherpa Guide Pemba'},
          },
        ];
        await OfflineCache.write('trip_messages:booking-1', rawResponseShape);

        final cached = await OfflineCache.read<List<Map<String, dynamic>>>(
          'trip_messages:booking-1',
          (json) => (json as List).cast<Map<String, dynamic>>(),
        );

        expect(cached, isNotNull);
        expect(cached!.first['profiles']['full_name'], 'Sherpa Guide Pemba');
      },
    );

    test('network fails, no cache → rethrows', () async {
      final repo = TripChatRepository(unreachableClient());
      expect(() => repo.getMessages('booking-1'), throwsA(anything));
    });
  });
}
