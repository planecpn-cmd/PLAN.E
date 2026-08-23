import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_e/core/trip_presence_controller.dart';
import 'package:plan_e/theme/app_theme.dart';
import 'package:plan_e/widgets/trip_presence_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'presence aggregation excludes self and deduplicates remote devices',
    () {
      const currentUser = '96000000-0000-4000-8000-000000000001';
      const traveler = '96000000-0000-4000-8000-000000000002';
      final snapshot = TripPresenceSnapshot.fromPresenceState([
        const SinglePresenceState(
          key: currentUser,
          presences: [
            Presence(
              presenceRef: 'self-device',
              payload: {'role': 'host', 'typing': true},
            ),
          ],
        ),
        const SinglePresenceState(
          key: traveler,
          presences: [
            Presence(
              presenceRef: 'traveler-phone',
              payload: {'role': 'traveler', 'typing': true},
            ),
            Presence(
              presenceRef: 'traveler-web',
              payload: {'role': 'traveler', 'typing': false},
            ),
          ],
        ),
      ], currentUserId: currentUser);

      expect(snapshot.remoteOnlineCount, 1);
      expect(snapshot.typingRoles, {'traveler'});
      expect(snapshot.isAnyoneTyping, isTrue);
    },
  );

  test('presence starts only for canonical booking UUIDs', () {
    expect(
      TripPresenceController.isValidBookingId(
        '96000000-0000-4000-8000-000000000008',
      ),
      isTrue,
    );
    expect(TripPresenceController.isValidBookingId('mock-chat-1'), isFalse);
    expect(
      TripPresenceController.isValidBookingId(
        '96000000-0000-4000-8000-000000000008/extra',
      ),
      isFalse,
    );
  });

  testWidgets('indicator describes typing without exposing identity', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: TripPresenceIndicator(
            viewerRole: 'host',
            snapshot: TripPresenceSnapshot(
              isConnected: true,
              remoteOnlineCount: 1,
              typingRoles: {'traveler'},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Traveler is typing…'), findsOneWidget);
  });
}
