import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plan_e/main.dart';
import 'package:plan_e/providers/app_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late final SupabaseClient testClient;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.invalid',
      publishableKey: 'test-anon-key',
    );
    testClient = Supabase.instance.client;
  });

  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [supabaseClientProvider.overrideWithValue(testClient)],
        child: const PlanEApp(),
      ),
    );
    // The splash screen wordmark animates letter-by-letter (and morphs the
    // 'A' into a mountain icon), so it's exposed as a single a11y label
    // rather than a literal 'NEPAL' Text widget.
    expect(find.bySemanticsLabel('NEPAL'), findsOneWidget);
  });
}
