import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:plan_e/features/host/data/mock_host_mode_repository.dart';
import 'package:plan_e/features/host/domain/host_mode_models.dart';
import 'package:plan_e/features/host/host_dashboard_screen.dart';
import 'package:plan_e/features/host/presentation/create_host_experience_screen.dart';
import 'package:plan_e/features/host/presentation/host_booking_detail_screen.dart';
import 'package:plan_e/features/host/presentation/host_bookings_screen.dart';
import 'package:plan_e/features/host/presentation/host_business_screen.dart';
import 'package:plan_e/features/host/presentation/host_conversation_screen.dart';
import 'package:plan_e/features/host/presentation/host_departure_detail_screen.dart';
import 'package:plan_e/features/host/presentation/host_experiences_screen.dart';
import 'package:plan_e/features/host/presentation/host_experience_detail_screen.dart';
import 'package:plan_e/features/host/presentation/host_messages_screen.dart';
import 'package:plan_e/features/host/presentation/host_mode_providers.dart';
import 'package:plan_e/features/host/presentation/host_profile_screen.dart';
import 'package:plan_e/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> setPhoneSize(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('messages search filters people, groups and experiences', (
    tester,
  ) async {
    await setPhoneSize(tester);
    final router = GoRouter(
      initialLocation: '/host/messages',
      routes: _hostTabRoutes(messages: const HostMessagesScreen()),
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();

    expect(find.text('Aarav Shrestha'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Panchase');
    await tester.pump();
    expect(find.text('Panchase · 4 Oct Group'), findsOneWidget);
    expect(find.text('Aarav Shrestha'), findsNothing);

    await tester.enterText(find.byType(TextFormField).first, 'no result');
    await tester.pump();
    expect(find.text('No conversations found'), findsOneWidget);
  });

  testWidgets('experience status chips filter the local list', (tester) async {
    await setPhoneSize(tester);
    final router = GoRouter(
      initialLocation: '/host/experiences',
      routes: _hostTabRoutes(experiences: const HostExperiencesScreen()),
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();

    expect(find.text('Mardi Himal Trek'), findsOneWidget);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(-320, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pending Review').first);
    await tester.pumpAndSettle();
    expect(find.text('Khopra Ridge Discovery'), findsOneWidget);
    expect(find.text('Mardi Himal Trek'), findsNothing);

    router.go('/host/messages');
    await tester.pumpAndSettle();
    router.go('/host/experiences');
    await tester.pumpAndSettle();
    expect(find.text('Khopra Ridge Discovery'), findsOneWidget);
    expect(find.text('Mardi Himal Trek'), findsNothing);
  });

  testWidgets('message search survives Host tab remounts', (tester) async {
    await setPhoneSize(tester);
    final router = GoRouter(
      initialLocation: '/host/messages',
      routes: _hostTabRoutes(messages: const HostMessagesScreen()),
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Panchase');
    await tester.pump();
    router.go('/host/dashboard');
    await tester.pumpAndSettle();
    router.go('/host/messages');
    await tester.pumpAndSettle();

    expect(find.text('Panchase · 4 Oct Group'), findsOneWidget);
    expect(find.text('Aarav Shrestha'), findsNothing);
    expect(find.text('Panchase'), findsOneWidget);
  });

  testWidgets('booking filter survives Host tab remounts', (tester) async {
    await setPhoneSize(tester);
    final router = GoRouter(
      initialLocation: '/host/bookings',
      routes: _hostTabRoutes(bookings: const HostBookingsScreen()),
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirmed').first);
    await tester.pumpAndSettle();
    expect(find.text('Daniel Kim'), findsOneWidget);
    expect(find.text('Aarav Shrestha'), findsNothing);

    router.go('/host/dashboard');
    await tester.pumpAndSettle();
    router.go('/host/bookings');
    await tester.pumpAndSettle();

    expect(find.text('Daniel Kim'), findsOneWidget);
    expect(find.text('Aarav Shrestha'), findsNothing);
  });

  testWidgets(
    'route-provided filters initialize without provider lifecycle errors',
    (tester) async {
      await setPhoneSize(tester);
      final router = GoRouter(
        initialLocation: '/host/experiences',
        routes: _hostTabRoutes(
          experiences: const HostExperiencesScreen(
            initialFilter: HostExperienceStatus.active,
            hasInitialFilter: true,
          ),
        ),
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(_app(router));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Mardi Himal Trek'), findsOneWidget);
      expect(find.text('Ghandruk Village Weekend'), findsNothing);
    },
  );

  testWidgets('Host navigation matches the traveler floating bar', (
    tester,
  ) async {
    await setPhoneSize(tester);
    final router = GoRouter(
      initialLocation: '/host/experiences',
      routes: _hostTabRoutes(experiences: const HostExperiencesScreen()),
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.byKey(const ValueKey('host-navigation-bar')), findsOneWidget);
    final navigation = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(navigation.showSelectedLabels, isFalse);
    expect(navigation.showUnselectedLabels, isFalse);
    expect(navigation.items, hasLength(5));
  });

  testWidgets('Host profile scrolls logout above floating navigation', (
    tester,
  ) async {
    await setPhoneSize(tester);
    final router = GoRouter(
      initialLocation: '/host/profile',
      routes: _hostTabRoutes(profile: const HostProfileScreen()),
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('LOGOUT'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final logoutBottom = tester.getBottomRight(find.text('LOGOUT')).dy;
    final navigationTop = tester
        .getTopLeft(find.byKey(const ValueKey('host-navigation-bar')))
        .dy;
    expect(logoutBottom, lessThan(navigationTop));
  });

  testWidgets('Host dashboard scrolls quick actions above navigation', (
    tester,
  ) async {
    await setPhoneSize(tester);
    final router = GoRouter(
      initialLocation: '/host/dashboard',
      routes: _hostTabRoutes(dashboard: const HostDashboardScreen()),
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Manage Bookings'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final actionBottom = tester.getBottomRight(find.text('Manage Bookings')).dy;
    final navigationTop = tester
        .getTopLeft(find.byKey(const ValueKey('host-navigation-bar')))
        .dy;
    expect(actionBottom, lessThan(navigationTop));
  });

  testWidgets('dashboard statistics navigate to operational destinations', (
    tester,
  ) async {
    await setPhoneSize(tester);
    final router = GoRouter(
      initialLocation: '/host/dashboard',
      routes: [
        GoRoute(
          path: '/host/dashboard',
          builder: (context, state) => const HostDashboardScreen(),
        ),
        GoRoute(
          path: '/host/experiences',
          builder: (context, state) =>
              const Scaffold(body: Text('Experiences destination')),
        ),
        GoRoute(
          path: '/host/bookings',
          builder: (context, state) =>
              const Scaffold(body: Text('Bookings destination')),
        ),
        GoRoute(
          path: '/host/messages',
          builder: (context, state) => const Scaffold(body: Text('Messages')),
        ),
        GoRoute(
          path: '/host/profile',
          builder: (context, state) => const Scaffold(body: Text('Profile')),
        ),
        GoRoute(
          path: '/host/profile/earnings',
          builder: (context, state) =>
              const Scaffold(body: Text('Earnings destination')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Active Experiences'));
    await tester.pumpAndSettle();
    expect(find.text('Experiences destination'), findsOneWidget);
  });

  testWidgets('complete draft advances through all form steps to preview', (
    tester,
  ) async {
    await setPhoneSize(tester);
    final notifier = HostCreateExperienceNotifier()
      ..update(
        HostExperienceDraft(
          title: 'Helambu Local Trail',
          location: 'Sindhupalchok, Nepal',
          description:
              'A locally guided trail experience with village stays and meals.',
          photoAssets: const ['assets/images/welcome_hero.jpg'],
          tripDetails:
              'A moderate four-day trek with lodge accommodation and transport.',
          itinerary: const ['Day 1 · Travel and village orientation'],
          included: const ['Guide and lodge accommodation'],
          bring: const ['Walking shoes and warm layers'],
          startDate: DateTime(2027, 2, 1),
          endDate: DateTime(2027, 2, 4),
          capacity: 8,
          priceNpr: 18000,
          meetingPoint: 'Boudha Gate, Kathmandu',
        ),
      );
    final router = GoRouter(
      initialLocation: '/host/experiences/create',
      routes: [
        GoRoute(
          path: '/host/experiences/create',
          builder: (context, state) => const CreateHostExperienceScreen(),
        ),
        GoRoute(
          path: '/host/experiences/create/preview',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Preview destination'))),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hostModeRepositoryProvider.overrideWithValue(
            MockHostModeRepository(),
          ),
          hostCreateExperienceProvider.overrideWith((ref) => notifier),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (var step = 1; step <= 8; step++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Step ${step + 1} of 10'), findsOneWidget);
    }
    expect(find.text('Meeting Point'), findsOneWidget);
    await tester.tap(find.text('Preview'));
    await tester.pumpAndSettle();
    expect(find.text('Preview destination'), findsOneWidget);
    expect(notifier.state.title, 'Helambu Local Trail');
  });

  testWidgets(
    'operational and business screens render at 9:16 without overflow',
    (tester) async {
      await setPhoneSize(tester);
      final screens = <(String, Widget)>[
        ('bookings', const HostBookingsScreen()),
        (
          'booking details',
          const HostBookingDetailScreen(id: 'mock-booking-1'),
        ),
        (
          'experience management',
          const HostExperienceDetailScreen(id: 'mock-exp-mardi'),
        ),
        (
          'departure details',
          const HostDepartureDetailScreen(experienceId: 'mock-exp-mardi'),
        ),
        ('conversation', const HostConversationScreen(id: 'mock-chat-1')),
        ('host profile', const HostProfileScreen()),
        ('earnings', const HostBusinessScreen(page: HostBusinessPage.earnings)),
      ];

      for (final screen in screens) {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              hostModeRepositoryProvider.overrideWithValue(
                MockHostModeRepository(),
              ),
            ],
            child: MaterialApp(theme: AppTheme.lightTheme, home: screen.$2),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: screen.$1);
      }
    },
  );
}

Widget _app(GoRouter router) => ProviderScope(
  overrides: [
    hostModeRepositoryProvider.overrideWithValue(MockHostModeRepository()),
  ],
  child: MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router),
);

List<RouteBase> _hostTabRoutes({
  Widget? dashboard,
  Widget? experiences,
  Widget? bookings,
  Widget? messages,
  Widget? profile,
}) => [
  GoRoute(
    path: '/host/dashboard',
    builder: (context, state) =>
        dashboard ?? const Scaffold(body: Text('Dashboard')),
  ),
  GoRoute(
    path: '/host/experiences',
    builder: (context, state) =>
        experiences ?? const Scaffold(body: Text('Experiences')),
  ),
  GoRoute(
    path: '/host/bookings',
    builder: (context, state) =>
        bookings ?? const Scaffold(body: Text('Bookings')),
  ),
  GoRoute(
    path: '/host/messages',
    builder: (context, state) =>
        messages ?? const Scaffold(body: Text('Messages')),
  ),
  GoRoute(
    path: '/host/messages/:id',
    builder: (context, state) => const Scaffold(body: Text('Conversation')),
  ),
  GoRoute(
    path: '/host/profile',
    builder: (context, state) =>
        profile ?? const Scaffold(body: Text('Profile')),
  ),
];
