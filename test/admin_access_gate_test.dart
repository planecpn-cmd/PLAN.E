import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_e/features/profile/admin_access_gate.dart';
import 'package:plan_e/models/profile.dart';
import 'package:plan_e/providers/app_providers.dart';

Profile _profile(UserRole role) => Profile(
      id: 'u1',
      role: role,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

Future<void> _pump(WidgetTester tester, Profile? profile) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [profileProvider.overrideWith((ref) async => profile)],
      child: const MaterialApp(
        home: AdminAccessGate(child: Text('MOD QUEUE')),
      ),
    ),
  );
}

void main() {
  testWidgets('admin sees the wrapped screen', (tester) async {
    await _pump(tester, _profile(UserRole.admin));
    await tester.pumpAndSettle();
    expect(find.text('MOD QUEUE'), findsOneWidget);
    expect(find.text('Admin access required'), findsNothing);
  });

  testWidgets('a non-admin is blocked and the wrapped screen never renders', (
    tester,
  ) async {
    await _pump(tester, _profile(UserRole.traveler));
    await tester.pumpAndSettle();
    expect(find.text('MOD QUEUE'), findsNothing);
    expect(find.text('Admin access required'), findsOneWidget);
  });

  testWidgets('no profile (signed out / load failed) is blocked', (tester) async {
    await _pump(tester, null);
    await tester.pumpAndSettle();
    expect(find.text('MOD QUEUE'), findsNothing);
    expect(find.text('Admin access required'), findsOneWidget);
  });
}
