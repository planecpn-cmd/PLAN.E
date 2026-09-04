import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:plan_e/features/experience/experience_detail_providers.dart';
import 'package:plan_e/features/experience/experience_detail_screen.dart';
import 'package:plan_e/features/experience/limited_package_data.dart';
import 'package:plan_e/features/experience/limited_package_detail.dart';
import 'package:plan_e/models/category.dart';
import 'package:plan_e/models/experience.dart';
import 'package:plan_e/models/experience_departure.dart';
import 'package:plan_e/models/experience_family.dart';
import 'package:plan_e/models/review.dart';
import 'package:plan_e/providers/app_providers.dart';

final now = DateTime.utc(2026, 9, 4);
Category category(String slug) => Category(
  id: 'category-id',
  slug: slug,
  nameEn: 'Trekking',
  nameNe: '',
  createdAt: now,
);
Experience experience() => Experience(
  id: 'trek',
  categoryId: 'category-id',
  hostId: 'private-host',
  title: 'A journey with a long title through the mountains',
  slug: 'journey',
  coverImageUrl: '',
  pricePaisa: 9500000,
  meetingPoint: 'Private supplier meeting point',
  description: 'Call secret provider',
  locationName: 'Private lodge',
  included: const ['Private supplier'],
  bringList: const ['Call provider@example.com'],
  thingsToKnow: const ['Private guide'],
  createdAt: now,
  updatedAt: now,
);

ExperienceDeparture departure(
  String id,
  DateTime date, {
  String status = 'open',
  int spots = 8,
}) => ExperienceDeparture(
  id: id,
  experienceId: 'trek',
  startDate: date,
  endDate: date,
  totalSpots: 10,
  spotsLeft: spots,
  status: status,
  createdAt: now,
);

void main() {
  test(
    'category slugs select automatically and unresolved categories fail closed',
    () {
      for (final slug in limitedCategorySlugs) {
        expect(
          detailPresentationFor(category(slug)),
          DetailPresentationType.limited,
        );
      }
      for (final slug in ['hiking', 'craft-workshop', 'day-trip', 'wellness']) {
        expect(
          detailPresentationFor(category(slug)),
          DetailPresentationType.full,
        );
      }
      expect(detailPresentationFor(null), DetailPresentationType.limited);
    },
  );

  test('next departure excludes closed, sold out and past dates and sorts', () {
    final departures = [
      departure('later', DateTime(2026, 9, 20)),
      departure('closed', DateTime(2026, 9, 5), status: 'cancelled'),
      departure('sold', DateTime(2026, 9, 5), spots: 0),
      departure('past', DateTime(2026, 9, 3)),
      departure('next', DateTime(2026, 9, 6)),
    ];
    expect(nextPackageDeparture(departures, now)?.id, 'next');
    expect(nextPackageDeparture([], now), isNull);
  });

  test('missing seasons stay empty; sensitive prose is not projected', () {
    final json = experience().toJson()..remove('best_season');
    expect(Experience.fromJson(json).bestSeason, isEmpty);
    final data = LimitedPackageData.from(
      experience(),
      category('trekking'),
      null,
    );
    expect(data.region, isNull);
    expect(data.bestSeason, isEmpty);
    expect(const LimitedPackageContent().options, isEmpty);
  });

  testWidgets('taxonomy loading never renders or requests host details', (
    tester,
  ) async {
    final taxonomy = Completer<ExperienceTaxonomy>();
    var hostRequested = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          experienceDetailProvider.overrideWith(
            (ref, id) async => experience(),
          ),
          isSavedExperienceProvider.overrideWith((ref, id) async => false),
          experienceTaxonomyProvider.overrideWith((ref) => taxonomy.future),
          hostProfileProvider.overrideWith((ref, id) async {
            hostRequested = true;
            return null;
          }),
        ],
        child: const MaterialApp(home: ExperienceDetailScreen(id: 'trek')),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Verified local host'), findsNothing);
    expect(hostRequested, isFalse);
    await tester.pumpWidget(const SizedBox());
    taxonomy.complete(ExperienceTaxonomy(categories: [], families: []));
    await tester.pump();
  });

  testWidgets(
    'limited route excludes sensitive fields and standard reaches existing booking',
    (tester) async {
      var hostRequested = false;
      var itineraryRequested = false;
      final router = GoRouter(
        initialLocation: '/experience/trek',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const Text('Home destination'),
          ),
          GoRoute(
            path: '/experience/:id',
            builder: (context, state) =>
                const ExperienceDetailScreen(id: 'trek'),
          ),
          GoRoute(
            path: '/booking/:id',
            builder: (context, state) =>
                Text('Booking ${state.pathParameters['id']}'),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            experienceDetailProvider.overrideWith(
              (ref, id) async => experience(),
            ),
            isSavedExperienceProvider.overrideWith((ref, id) async => false),
            experienceTaxonomyProvider.overrideWith(
              (ref) async => ExperienceTaxonomy(
                categories: [category('trekking')],
                families: [],
              ),
            ),
            regionsProvider.overrideWith((ref) async => []),
            experienceDeparturesProvider.overrideWith((ref, id) async => []),
            experienceReviewsProvider.overrideWith(
              (ref, id) async => [
                Review(
                  id: 'review',
                  experienceId: id,
                  rating: 5,
                  body: 'Book via provider@example.com',
                  createdAt: now,
                  updatedAt: now,
                ),
              ],
            ),
            hostProfileProvider.overrideWith((ref, id) async {
              hostRequested = true;
              return null;
            }),
            experienceItineraryProvider.overrideWith((ref, id) async {
              itineraryRequested = true;
              return [];
            }),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LimitedPackageDetail), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
      expect(find.text('Group size'), findsOneWidget);
      expect(find.text('Difficulty'), findsOneWidget);
      expect(find.text('Trekking'), findsOneWidget);
      expect(find.textContaining('provider@example.com'), findsNothing);
      expect(find.textContaining('Private'), findsNothing);
      expect(find.text('Verified local host'), findsNothing);
      expect(hostRequested, isFalse);
      expect(itineraryRequested, isFalse);
      await tester.tap(find.text('CHOOSE PACKAGE'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Standard Package'));
      await tester.tap(find.text('Standard Package'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CONTINUE'));
      await tester.pumpAndSettle();
      expect(find.text('Booking trek'), findsOneWidget);
      router.go('/experience/trek');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Go back'));
      await tester.tap(find.byTooltip('Go back'));
      await tester.pumpAndSettle();
      expect(find.text('Home destination'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [
    const Size(320, 740),
    const Size(375, 812),
    const Size(812, 375),
  ]) {
    testWidgets(
      'package controls, required services, accordion and safe area at $size',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        var saves = 0;
        var shares = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: const TextScaler.linear(1.5),
                disableAnimations: true,
              ),
              child: LimitedPackageDetail(
                data: LimitedPackageData.from(
                  experience(),
                  category('trekking'),
                  null,
                ),
                content: const LimitedPackageContent(
                  stages: [
                    BasicItineraryStage(
                      day: 1,
                      route: 'Reviewed public route',
                      distance: '8 km',
                      altitude: '2000 m',
                      highlights: ['Mountain views'],
                    ),
                  ],
                  checklist: ['Walking boots'],
                  options: [
                    PackageOption(
                      id: 'guide',
                      label: 'Licensed guide',
                      group: 'Support',
                      required: true,
                    ),
                    PackageOption(
                      id: 'porter',
                      label: 'Porter support',
                      group: 'Support',
                    ),
                    PackageOption(
                      id: 'private',
                      label: 'Private room',
                      group: 'Accommodation',
                      exclusiveGroup: 'room',
                    ),
                    PackageOption(
                      id: 'comfort',
                      label: 'Comfort room',
                      group: 'Accommodation',
                      exclusiveGroup: 'room',
                    ),
                    PackageOption(
                      id: 'diet',
                      label: 'Dietary preference',
                      group: 'Meals',
                      allowsNote: true,
                    ),
                  ],
                ),
                departures: const AsyncData([]),
                reviews: const AsyncData([]),
                isSaved: false,
                onBack: () {},
                onSave: () => saves++,
                onShare: () => shares++,
                onContinueStandard: () {},
                onRetryDepartures: () {},
                onRetryReviews: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(AppBar), findsNothing);
        final footer = find.widgetWithText(ElevatedButton, 'CHOOSE PACKAGE');
        expect(tester.getCenter(footer).dx, greaterThan(size.width / 2));
        expect(find.text('Group size'), findsOneWidget);
        await tester.tap(find.byTooltip('Save experience'));
        await tester.tap(find.byTooltip('Share experience'));
        expect(saves, 1);
        expect(shares, 1);
        await tester.ensureVisible(find.text('Day 1  Reviewed public route'));
        await tester.tap(find.text('Day 1  Reviewed public route'));
        await tester.pumpAndSettle();
        expect(find.text('Distance: 8 km'), findsOneWidget);
        await tester.ensureVisible(find.text('Download Itinerary').last);
        final download = tester.widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'Download Itinerary'),
        );
        expect(download.onPressed, isNull);
        await tester.ensureVisible(find.text('Plan It Your Own Style'));
        await tester.tap(find.text('Plan It Your Own Style'));
        await tester.pumpAndSettle();
        expect(find.text('Included / Required'), findsOneWidget);
        expect(
          find.widgetWithText(CheckboxListTile, 'Licensed guide'),
          findsNothing,
        );
        await tester.ensureVisible(
          find.widgetWithText(CheckboxListTile, 'Porter support'),
        );
        await tester.tap(
          find.widgetWithText(CheckboxListTile, 'Porter support'),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<CheckboxListTile>(
                find.widgetWithText(CheckboxListTile, 'Porter support'),
              )
              .value,
          isTrue,
        );
        for (final label in ['Private room', 'Comfort room']) {
          await tester.ensureVisible(
            find.widgetWithText(RadioListTile<String>, label),
          );
          await tester.tap(find.widgetWithText(RadioListTile<String>, label));
          await tester.pumpAndSettle();
        }
        expect(find.text('Private room'), findsOneWidget);
        expect(find.text('Comfort room'), findsNWidgets(2));
        await tester.ensureVisible(
          find.widgetWithText(CheckboxListTile, 'Dietary preference'),
        );
        await tester.tap(
          find.widgetWithText(CheckboxListTile, 'Dietary preference'),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byType(TextFormField));
        await tester.enterText(find.byType(TextFormField), 'Vegetarian');
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Final price will be confirmed after customization review.',
          ),
          findsOneWidget,
        );
        expect(
          tester
              .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, 'CONTINUE'),
              )
              .onPressed,
          isNull,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
