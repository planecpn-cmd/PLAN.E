import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plan_e/features/home/home_screen.dart';
import 'package:plan_e/l10n/app_localizations.dart';
import 'package:plan_e/models/experience_family.dart';
import 'package:plan_e/providers/app_providers.dart';
import 'package:plan_e/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:plan_e/features/home/home_category_section.dart';
import 'package:plan_e/features/home/home_discovery.dart';
import 'package:plan_e/models/experience.dart';
import 'package:plan_e/widgets/experience_card.dart';

Experience experience(
  String id,
  String title, {
  double rating = 4,
  int reviews = 2,
}) => Experience(
  id: id,
  title: title,
  slug: id,
  coverImageUrl: '',
  pricePaisa: 100000,
  ratingAvg: rating,
  ratingCount: reviews,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('Home loads and hero navigation works at text scale $scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
          GoRoute(
            path: '/collection/trips-tours',
            builder: (_, _) => const Text('Trips destination'),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeRailsProvider.overrideWith(
              (ref) async => {
                'recommended': [experience('yoga', 'Lakeside Yoga')],
              },
            ),
            savedExperiencesProvider.overrideWith((ref) async => []),
            profileProvider.overrideWith((ref) async => null),
            unreadNotificationCountProvider.overrideWith((ref) async => 0),
            featureFlagProvider('ai_itinerary').overrideWithValue(true),
            experienceTaxonomyProvider.overrideWith(
              (ref) async => ExperienceTaxonomy(categories: [], families: []),
            ),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final weeklyCard = tester.widget<ExperienceCard>(
        find.byType(ExperienceCard).first,
      );
      expect(weeklyCard.variant, ExperienceCardVariant.square);
      expect(weeklyCard.width, (200 * scale).clamp(200.0, 340.0));
      expect(find.text('Curated Trips'), findsOneWidget);
      expect(find.text('Plan with AI'), findsOneWidget);
      expect(find.text('Recommended For You'), findsNothing);
      expect(find.text('Trending Now'), findsNothing);
      expect(find.text('Explore Nepal'), findsNothing);
      final titles = [
        'Happening This Week',
        ...homeSections.map((s) => s.title),
      ];
      final offsets = titles
          .map((title) => tester.getTopLeft(find.text(title)).dy)
          .toList();
      expect(offsets, orderedEquals([...offsets]..sort()));
      await tester.ensureVisible(find.text('Curated Trips'));
      await tester.tap(find.text('Curated Trips'));
      await tester.pumpAndSettle();
      expect(find.text('Trips destination'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
    });
  }

  test(
    'ranking deduplicates and uses rating then review count with stable ties',
    () {
      final a = experience('a', 'Trek', rating: 5);
      final b = experience('b', 'Rafting', rating: 5, reviews: 10);
      final c = experience('c', 'Yoga');
      expect(rankHomeExperiences([c, a, b, a]).map((e) => e.id), [
        'b',
        'a',
        'c',
      ]);
      expect(homeSections.map((s) => s.title), [
        'Adventure Together',
        'Soul & Mind',
        'Meet People',
        'Give Back',
        'Live Like a Local',
      ]);
      final changedOffering = experience(
        'everest-trek',
        'Community Social Evening',
      );
      expect(
        homeSections.first.filters.first.matches(changedOffering, null),
        isFalse,
      );
      expect(
        homeSections.first.filters[2].matches(
          experience('water', 'White Water Rafting'),
          null,
        ),
        isTrue,
      );
    },
  );

  for (final size in [
    const Size(320, 640),
    const Size(375, 812),
    const Size(812, 375),
  ]) {
    testWidgets(
      'all sections overview, filter, reset, actions and layout at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        for (final spec in homeSections) {
          var opens = 0;
          var saves = 0;
          final sample = experience(
            'a',
            '${spec.filters.first.terms.firstOrNull ?? ''} An exceptionally long experience name to check two-line ellipsis',
          );
          final router = GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => Scaffold(
                  body: SingleChildScrollView(
                    child: HomeCategorySection(
                      spec: spec,
                      experiences: [sample],
                      taxonomy: null,
                      cardBuilder: (e, width) => ExperienceCard(
                        title: e.title,
                        location: 'Kathmandu',
                        rating: e.ratingAvg,
                        priceText: 'NPR 1,000',
                        width: width,
                        variant: ExperienceCardVariant.square,
                        onTap: () => opens++,
                        onBookmarkTap: () => saves++,
                      ),
                    ),
                  ),
                ),
              ),
              GoRoute(
                path: '/collection/:slug',
                builder: (_, state) =>
                    Text('Collection ${state.pathParameters['slug']}'),
              ),
            ],
          );
          await tester.pumpWidget(MaterialApp.router(routerConfig: router));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            tester
                .widgetList<FilterChip>(find.byType(FilterChip))
                .every((chip) => !chip.selected),
            isTrue,
          );
          expect(find.text('Most Popular'), findsNothing);
          final grid = tester.widget<GridView>(find.byType(GridView));
          expect(
            grid.childrenDelegate.estimatedChildCount,
            spec.filters.where((filter) => filter.matches(sample, null)).length,
          );
          expect(grid.scrollDirection, Axis.horizontal);
          final delegate =
              grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
          expect(delegate.childAspectRatio, 1.5);
          expect(delegate.crossAxisCount, 1);
          await tester.drag(find.byType(GridView), const Offset(-240, 0));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.tap(find.byType(FilterChip).first);
          await tester.pumpAndSettle();
          expect(find.text('Most Popular'), findsOneWidget);
          expect(
            tester.widget<FilterChip>(find.byType(FilterChip).first).selected,
            isTrue,
          );
          if (find.byType(ExperienceCard).evaluate().isNotEmpty) {
            await tester.ensureVisible(find.byType(ExperienceCard).first);
            await tester.tap(find.byIcon(Icons.bookmark_border).first);
            await tester.pump();
            expect(saves, 1);
            await tester.tap(find.byType(ExperienceCard).first);
            expect(opens, 1);
          }
          await tester.ensureVisible(find.text('Overview'));
          await tester.tap(find.text('Overview'));
          await tester.pumpAndSettle();
          expect(find.text('Most Popular'), findsNothing);
          await tester.ensureVisible(find.text('See All'));
          await tester.tap(find.text('See All'));
          await tester.pumpAndSettle();
          expect(find.text('Collection ${spec.slug}'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          router.dispose();
        }
      },
    );
  }

  testWidgets('large text and unavailable categories remain usable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: HomeCategorySection(
                spec: homeSections[3],
                experiences: const [],
                taxonomy: null,
                cardBuilder: (_, width) => SizedBox(width: width),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(FilterChip).first);
    await tester.pumpAndSettle();
    expect(find.text('No Community experiences available yet.'), findsNothing);
    expect(find.byType(GridView), findsNothing);
    expect(
      tester.widget<FilterChip>(find.byType(FilterChip).first).onSelected,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
}
