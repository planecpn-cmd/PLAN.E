// H0 stopgap guard: the five host-mode write buttons must not surface an
// unhandled exception. In production SupabaseHostModeRepository inherits the
// fail-closed base for saveDraft / submitForReview / setExperiencePaused /
// updateAvailability / updateBookingStatus, so any of those calls throws a
// StateError. H0 removed the calls from the button handlers.
//
// Each test uses a repository whose reads behave like the mock but whose write
// methods throw a StateError, then taps the control and asserts:
//   * no StateError escaped to FlutterError.onError (the pre-H0 failure mode);
//   * the standard "unavailable" notice is shown instead.
// Unrelated pre-existing debug assertions from these screens (e.g. ListTile
// inside a decorated card) are intentionally not asserted on here.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_e/features/host/data/mock_host_mode_repository.dart';
import 'package:plan_e/features/host/domain/host_mode_models.dart';
import 'package:plan_e/features/host/presentation/create_host_experience_screen.dart';
import 'package:plan_e/features/host/presentation/host_availability_screen.dart';
import 'package:plan_e/features/host/presentation/host_booking_detail_screen.dart';
import 'package:plan_e/features/host/presentation/host_experience_detail_screen.dart';
import 'package:plan_e/features/host/presentation/host_experience_preview_screen.dart';
import 'package:plan_e/features/host/presentation/host_mode_providers.dart';

/// Reads behave like the mock; every write throws like production.
class _WritesThrowRepository extends MockHostModeRepository {
  static Never _blocked() =>
      throw StateError('H0 guard: write path must not be called from the UI');

  @override
  Future<HostExperience> saveDraft(HostExperienceDraft draft) async =>
      _blocked();

  @override
  Future<HostExperience> submitForReview(HostExperienceDraft draft) async =>
      _blocked();

  @override
  Future<void> setExperiencePaused(String id, bool paused) async => _blocked();

  @override
  Future<void> updateAvailability(
    String id,
    DateTime start,
    DateTime end,
    int capacity,
  ) async => _blocked();

  @override
  Future<void> updateBookingStatus(String id, HostBookingStatus status) async =>
      _blocked();
}

const _notice = 'is currently unavailable. No changes were saved.';

HostExperienceDraft _validDraft() => HostExperienceDraft(
  id: 'mock-exp-mardi',
  title: 'Mardi Himal Ridge Trek',
  location: 'Kaski, Nepal',
  description:
      'A five-day ridge trek with teahouse stays, local guides and sunrise views.',
  photoAssets: const ['assets/images/welcome_hero.jpg'],
  tripDetails:
      'Moderate difficulty, five days, teahouse accommodation throughout.',
  itinerary: const ['Day 1 — drive to trailhead', 'Day 2 — ascend to camp'],
  included: const ['Licensed guide', 'Teahouse stays'],
  bring: const ['Warm layers', 'Broken-in boots'],
  startDate: DateTime(2026, 9, 18),
  endDate: DateTime(2026, 9, 22),
  capacity: 8,
  priceNpr: 24500,
  meetingPoint: 'Lakeside Bus Stop, Pokhara — beside the tourism office',
);

Widget _host(Widget screen, {HostExperienceDraft? draft}) => ProviderScope(
  overrides: [
    hostModeRepositoryProvider.overrideWithValue(_WritesThrowRepository()),
    if (draft != null)
      hostCreateExperienceProvider.overrideWith(
        (ref) => HostCreateExperienceNotifier()..update(draft),
      ),
  ],
  child: MaterialApp(home: screen),
);

/// Runs [body] with FlutterError.onError capturing, and asserts no StateError
/// (the pre-H0 failure signature) was raised.
Future<void> expectNoWritePathError(
  WidgetTester tester,
  Future<void> Function() body,
) async {
  final captured = <Object>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) => captured.add(details.exception);
  try {
    await body();
  } finally {
    FlutterError.onError = previous;
  }
  // Drain the framework's own store so a captured error is not re-reported.
  tester.takeException();
  expect(
    captured.whereType<StateError>(),
    isEmpty,
    reason: 'a write-path StateError escaped a host write button handler',
  );
}

/// Mounts on a tall surface so long screens build every `ListView` child
/// (off-screen `ListView` children are not inflated and cannot be found).
Future<void> _pump(WidgetTester tester, Widget widget) async {
  tester.view.physicalSize = const Size(1400, 4200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(widget);
  await tester.pumpAndSettle();
}

Future<void> _tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Save draft (create experience) does not hit the write path', (
    tester,
  ) async {
    await _pump(tester, _host(const CreateHostExperienceScreen()));

    await expectNoWritePathError(
      tester,
      () => _tapAndSettle(tester, find.text('Save draft')),
    );
    expect(find.textContaining(_notice), findsOneWidget);
  });

  testWidgets('Submit for review (preview) does not hit the write path', (
    tester,
  ) async {
    await _pump(
      tester,
      _host(const HostExperiencePreviewScreen(), draft: _validDraft()),
    );

    await expectNoWritePathError(
      tester,
      () => _tapAndSettle(tester, find.text('Submit for review')),
    );
    expect(find.textContaining(_notice), findsOneWidget);
  });

  testWidgets('Pause listing (experience detail) does not hit the write path', (
    tester,
  ) async {
    await _pump(
      tester,
      _host(const HostExperienceDetailScreen(id: 'mock-exp-mardi')),
    );

    await expectNoWritePathError(
      tester,
      () => _tapAndSettle(tester, find.text('Pause listing')),
    );
    expect(find.textContaining(_notice), findsOneWidget);
  });

  testWidgets('Update availability does not hit the write path', (tester) async {
    await _pump(
      tester,
      _host(const HostAvailabilityScreen(id: 'mock-exp-mardi')),
    );

    await expectNoWritePathError(
      tester,
      () => _tapAndSettle(tester, find.text('Update availability')),
    );
    expect(find.textContaining(_notice), findsOneWidget);
  });

  testWidgets('Accept / Decline (booking detail) do not hit the write path', (
    tester,
  ) async {
    await _pump(
      tester,
      _host(const HostBookingDetailScreen(id: 'mock-booking-1')),
    );

    await expectNoWritePathError(
      tester,
      () => _tapAndSettle(tester, find.text('Accept request')),
    );
    expect(find.textContaining(_notice), findsOneWidget);

    await expectNoWritePathError(
      tester,
      () => _tapAndSettle(tester, find.text('Decline')),
    );
  });
}
