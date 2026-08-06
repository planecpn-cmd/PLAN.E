import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plan_e/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: PlanEApp(),
      ),
    );
    // The splash screen wordmark animates letter-by-letter (and morphs the
    // 'A' into a mountain icon), so it's exposed as a single a11y label
    // rather than a literal 'NEPAL' Text widget.
    expect(find.bySemanticsLabel('NEPAL'), findsOneWidget);
  });
}
