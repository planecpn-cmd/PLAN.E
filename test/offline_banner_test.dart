// Phase 1 of docs/OFFLINE_CACHE_PLAN.md: isOfflineProvider used to be a
// manual toggle nothing ever set from real connectivity. main.dart now
// wires it from connectivity_plus. This test doesn't re-test
// connectivity_plus itself (a well-established plugin) — it verifies the
// actual wiring in this app: that OfflineBanner genuinely appears/disappears
// as isOfflineProvider's state changes, which is what main.dart's listener
// now drives in the real app.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_e/providers/app_providers.dart';
import 'package:plan_e/widgets/offline_banner.dart';

void main() {
  Widget wrap(Widget child) {
    return ProviderScope(
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  testWidgets('online by default — no banner', (tester) async {
    await tester.pumpWidget(wrap(const OfflineBanner()));
    expect(find.textContaining('Offline'), findsNothing);
  });

  testWidgets('setOffline(true) makes the banner appear', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: OfflineBanner())),
      ),
    );
    expect(find.textContaining('Offline'), findsNothing);

    container.read(isOfflineProvider.notifier).setOffline(true);
    await tester.pump();

    expect(find.textContaining('Offline'), findsOneWidget);
  });

  testWidgets('setOffline(false) after true makes the banner disappear again', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: OfflineBanner())),
      ),
    );

    container.read(isOfflineProvider.notifier).setOffline(true);
    await tester.pump();
    expect(find.textContaining('Offline'), findsOneWidget);

    container.read(isOfflineProvider.notifier).setOffline(false);
    await tester.pump();
    expect(find.textContaining('Offline'), findsNothing);
  });
}
