import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_e/features/home/home_screen.dart';
import 'package:plan_e/features/experience/limited_package_data.dart';
import 'package:plan_e/l10n/app_localizations.dart';
import 'package:plan_e/models/experience.dart';
import 'package:plan_e/models/experience_family.dart';
import 'package:plan_e/providers/app_providers.dart';
import 'package:plan_e/theme/theme.dart';
import 'package:plan_e/widgets/app_photo.dart';
import 'package:plan_e/widgets/experience_card.dart';
import 'package:plan_e/widgets/experience_family_card.dart';

const databaseCover = 'https://example.com/catalog/updated-by-host.webp';
final plan = Experience(
  id: 'test-plan',
  slug: 'everest-base-camp-trek',
  title: 'Everest Base Camp Trek',
  coverImageUrl: databaseCover,
  pricePaisa: 100000,
  ratingAvg: 4.9,
  ratingCount: 42,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  testWidgets(
    'Home honors the database cover even for an editorially known plan',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeRailsProvider.overrideWith(
              (ref) async => {
                'recommended': [plan],
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
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final cards = tester.widgetList<ExperienceCard>(
        find.byType(ExperienceCard),
      );
      expect(cards, isNotEmpty);
      expect(cards.every((card) => card.imageUrl == databaseCover), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'detail, saved/trip photos and card variants share the supplied cover',
    (tester) async {
      expect(
        LimitedPackageData.from(plan, null, null).photos.first,
        databaseCover,
      );
      for (final variant in ExperienceCardVariant.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Column(
                children: [
                  SizedBox(
                    width: variant == ExperienceCardVariant.horizontal
                        ? 400
                        : 200,
                    height: 400,
                    child: ExperienceCard(
                      width: variant == ExperienceCardVariant.horizontal
                          ? 400
                          : 200,
                      title: plan.title,
                      location: 'Nepal',
                      rating: 4.9,
                      reviewCount: 42,
                      priceText: 'NPR 1,000',
                      imageUrl: plan.coverImageUrl,
                      variant: variant,
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: PlanEPhoto(imageUrl: plan.coverImageUrl),
                  ),
                ],
              ),
            ),
          ),
        );
        // Inspect URL propagation without waiting for the network placeholder.
        await tester.pump();
        final photos = tester.widgetList<CachedNetworkImage>(
          find.byType(CachedNetworkImage),
        );
        expect(photos.length, 2);
        expect(
          photos.every((image) => image.imageUrl == databaseCover),
          isTrue,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'Explore category honors its database photo instead of a local override',
    (tester) async {
      final family = ExperienceFamily.fromJson({
        'id': 'adventure-together',
        'slug': 'adventure-together',
        'name_en': 'Adventure Together',
        'name_ne': 'Adventure',
        'description': 'Adventure',
        'icon': 'groups',
        'sort_order': 1,
        'cover_image_url': databaseCover,
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 160,
              child: ExperienceFamilyCard(family: family, onTap: () {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CachedNetworkImage>(find.byType(CachedNetworkImage))
            .imageUrl,
        databaseCover,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
