// Phase 8 of docs/OFFLINE_CACHE_PLAN.md: real OfflineBanner mounted beyond
// the single booking screen, plus honest "needs internet" messaging on the
// AI itinerary quiz — the one screen with no cache fallback at all (it's a
// live LLM call, not cached data).
//
// Plans/Trips/Profile/Saved screens got the same OfflineBanner treatment
// but aren't widget-tested here — they pull live Supabase data through
// several chained providers (bookings, saved experiences, profile) that
// would need a much larger provider-override rig to pump safely, matching
// this session's established pattern of not force-testing screens that
// need a real backend (see e.g. test/phase5_user_scoped_cache_test.dart's
// documented limitation). AiItineraryScreen is different: it only reads
// isOfflineProvider, featureFlagProvider, and aiItineraryNotifierProvider,
// none of which touch the network to *render* — only to submit — so it's
// safely testable end to end.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plan_e/features/ai_itinerary/ai_itinerary_screen.dart';
import 'package:plan_e/models/remote_config.dart';
import 'package:plan_e/providers/app_providers.dart';
import 'package:plan_e/widgets/app_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// A real SupabaseClient hangs testWidgets indefinitely even with every
// timer/auto-refresh option turned off — tried disposing it, tried
// autoRefreshToken: false, both still hung the test runner past its own
// internal timeout. Not investigated further; a mock sidesteps the problem
// entirely, since nothing in this screen actually calls a client method —
// it just needs *a* value of the right type to satisfy
// RemoteConfigNotifier's constructor.
class _MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  Future<ProviderContainer> pumpScreen(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        cachedRemoteConfigSnapshotProvider.overrideWithValue(
          RemoteConfigSnapshot.empty(),
        ),
        supabaseClientProvider.overrideWithValue(_MockSupabaseClient()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AiItineraryScreen()),
      ),
    );
    await tester.pump();
    return container;
  }

  testWidgets('online: no offline warning, submit button enabled', (tester) async {
    await pumpScreen(tester);

    expect(find.textContaining('needs an internet connection'), findsNothing);
    final button = tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'Generate My Plan'),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('offline: warning shown, submit button disabled', (tester) async {
    final container = await pumpScreen(tester);

    container.read(isOfflineProvider.notifier).setOffline(true);
    await tester.pump();

    expect(find.textContaining('needs an internet connection'), findsOneWidget);
    final button = tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'Generate My Plan'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('going back online re-enables the button and clears the warning', (
    tester,
  ) async {
    final container = await pumpScreen(tester);

    container.read(isOfflineProvider.notifier).setOffline(true);
    await tester.pump();
    container.read(isOfflineProvider.notifier).setOffline(false);
    await tester.pump();

    expect(find.textContaining('needs an internet connection'), findsNothing);
    final button = tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'Generate My Plan'),
    );
    expect(button.onPressed, isNotNull);
  });
}
