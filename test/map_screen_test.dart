import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:plan_e/features/explore/map_screen.dart';
import 'package:plan_e/features/explore/map_strings.dart';
import 'package:plan_e/models/experience.dart';
import 'package:plan_e/providers/app_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockExperiences = [
    Experience(
      id: 'exp-ktm-1',
      title: 'Kathmandu Heritage Walk',
      slug: 'ktm-heritage-walk',
      summary: 'Explore ancient Durbar Squares',
      coverImageUrl: 'https://example.com/ktm.jpg',
      pricePaisa: 250000,
      meetingPoint: 'Thamel, Kathmandu Gate',
      locationName: 'Kathmandu Valley',
      lat: 27.7172,
      lng: 85.3240,
      ratingAvg: 4.8,
      ratingCount: 24,
      status: ExperienceStatus.published,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    ),
    Experience(
      id: 'exp-pkr-2',
      title: 'Phewa Lake Boating & Hike',
      slug: 'phewa-lake-boating',
      summary: 'Serene boating in Pokhara',
      coverImageUrl: 'https://example.com/pkr.jpg',
      pricePaisa: 400000,
      meetingPoint: 'Lakeside Pokhara',
      locationName: 'Pokhara',
      lat: 28.2096,
      lng: 83.9856,
      ratingAvg: 4.9,
      ratingCount: 42,
      status: ExperienceStatus.published,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    ),
  ];

  Widget createMapScreenWidget({
    List<Experience>? experiences,
    double? lat,
    double? lng,
    String? title,
    String? meetingPoint,
  }) {
    final router = GoRouter(
      initialLocation: '/map',
      routes: [
        GoRoute(
          path: '/map',
          builder: (context, state) => MapScreen(
            lat: lat,
            lng: lng,
            title: title,
            meetingPoint: meetingPoint,
          ),
        ),
        GoRoute(
          path: '/experience/:id',
          builder: (context, state) => Scaffold(
            body: Text('Detail for ${state.pathParameters['id']}'),
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        experiencesProvider(const {}).overrideWith(
          (ref) async => experiences ?? mockExperiences,
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('Phase 6 - MapScreen (RM-08) Tests', () {
    testWidgets('MapScreen renders title, map controls, and meeting point details', (tester) async {
      await tester.pumpWidget(createMapScreenWidget());
      await tester.pumpAndSettle();

      expect(find.text(MapStrings.pageTitle), findsOneWidget);
      expect(find.text(MapStrings.meetingPointHeader), findsOneWidget);
      expect(find.text(MapStrings.copyAddress), findsOneWidget);
      expect(find.text(MapStrings.openExternalMaps), findsOneWidget);

      // Verify zoom indicator and style pill
      expect(find.textContaining(MapStrings.styleTopographic), findsWidgets);
    });

    testWidgets('MapScreen pin markers render and tapping pin shows preview card overlay', (tester) async {
      await tester.pumpWidget(createMapScreenWidget());
      await tester.pumpAndSettle();

      // Check pin marker text
      final expTitleFinder = find.text('Kathmandu Heritage Walk');
      expect(expTitleFinder, findsWidgets);

      // Tap on pin marker
      await tester.tap(expTitleFinder.first);
      await tester.pumpAndSettle();

      // Verify Experience Preview Card Overlay appears
      expect(find.text(MapStrings.viewExperience), findsOneWidget);
      expect(find.text('Rs. 2,500'), findsWidgets);
    });

    testWidgets('MapScreen control buttons (Zoom, Recenter, Style) trigger properly', (tester) async {
      await tester.pumpWidget(createMapScreenWidget());
      await tester.pumpAndSettle();

      // Zoom In button
      final zoomInFinder = find.byTooltip('Zoom In');
      expect(zoomInFinder, findsOneWidget);
      await tester.tap(zoomInFinder);
      await tester.pumpAndSettle();
      expect(find.textContaining('15x'), findsOneWidget);

      // Map Style Toggle button
      final styleToggleFinder = find.byTooltip('Map Style Toggle');
      expect(styleToggleFinder, findsOneWidget);
      await tester.tap(styleToggleFinder);
      await tester.pumpAndSettle();
      expect(find.textContaining(MapStrings.styleSatellite), findsWidgets);
    });

    testWidgets('MapScreen fallback renders gracefully when no experiences are returned', (tester) async {
      await tester.pumpWidget(createMapScreenWidget(experiences: []));
      await tester.pumpAndSettle();

      expect(find.text(MapStrings.pageTitle), findsOneWidget);
      expect(find.text(MapStrings.meetingPointHeader), findsOneWidget);
      expect(find.text(MapStrings.defaultMeetingPoint), findsOneWidget);
      expect(find.text(MapStrings.defaultLandmark), findsOneWidget);
    });
  });
}
