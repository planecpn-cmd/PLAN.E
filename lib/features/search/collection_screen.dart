// RM-06 Collection / See All
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/experience_presentation.dart';
import '../../l10n/app_localizations.dart';
import '../../models/experience.dart';
import '../../models/experience_family.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

class CollectionScreen extends ConsumerWidget {
  final String slug;

  const CollectionScreen({super.key, required this.slug});

  String get _collectionTitle {
    switch (slug.toLowerCase()) {
      case 'recommended':
        return 'Recommended for You';
      case 'trending':
        return 'Trending Experiences';
      case 'homestays':
        return 'Local Homestays';
      case 'community':
        return 'Community-Led Tours';
      case 'adventure-together':
        return 'Adventure Together';
      case 'mind-soul':
        return 'Mind & Soul';
      case 'give-back':
        return 'Give Back';
      case 'trips-tours':
        return 'Trips & Tours';
      case 'live-like-a-local':
        return 'Live Like a Local';
      case 'meet-people':
        return 'Meet People';
      default:
        if (slug.isNotEmpty) {
          return '${slug[0].toUpperCase()}${slug.substring(1)} Collection';
        }
        return 'Experience Collection';
    }
  }

  String get _collectionSubtitle {
    switch (slug.toLowerCase()) {
      case 'recommended':
        return 'Handpicked journeys customized for travelers in Nepal';
      case 'trending':
        return 'Most booked and highest rated experiences this month';
      case 'homestays':
        return 'Authentic village homestays and community warm welcomes';
      case 'community':
        return 'Sustainable tours directly benefiting local Nepalese guides';
      case 'adventure-together':
        return 'Experiences made for couples, friends, families, and groups';
      case 'mind-soul':
        return 'Wellness, yoga, meditation, nature, and restorative escapes';
      case 'give-back':
        return 'Community service, conservation, and positive local impact';
      case 'trips-tours':
        return 'Day trips, guided tours, packages, and sightseeing';
      case 'live-like-a-local':
        return 'Food, homes, villages, culture, and crafts';
      case 'meet-people':
        return 'Meetups, activities, events, and communities';
      default:
        return 'Explore our curated list of authentic experiences';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final taxonomy = ref.watch(experienceTaxonomyProvider).valueOrNull;
    // If slug is one of the rail types, we can use homeRailsProvider or experiencesProvider
    final isRailType = [
      'recommended',
      'trending',
      'homestays',
      'community',
      'adventure-together',
      'mind-soul',
      'give-back',
      'trips-tours',
      'live-like-a-local',
      'meet-people',
    ].contains(slug.toLowerCase());

    if (isRailType) {
      final homeRailsAsync = ref.watch(homeRailsProvider);
      return Scaffold(
        backgroundColor: AppColors.ivory,
        appBar: AppBar(
          backgroundColor: AppColors.ivory,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.ink),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            constraints: AppTouchTarget.minConstraints,
          ),
          title: Text(
            _collectionTitle,
            style: AppTypography.headingMedium.copyWith(
              color: AppColors.forest,
            ),
          ),
        ),
        body: SafeArea(
          child: AsyncValueView<Map<String, List<Experience>>>(
            value: homeRailsAsync,
            onRetry: () => ref.refresh(homeRailsProvider),
            isEmpty: (railsMap) =>
                (railsMap[slug.toLowerCase()]?.isEmpty ?? true),
            emptyView: EmptyStateView(
              title: l10n.noExperiencesFound,
              description: 'There are currently no items in this collection.',
              actionLabel: l10n.returnHome,
              onActionPressed: () => context.go('/home'),
            ),
            data: (railsMap) {
              final list = railsMap[slug.toLowerCase()] ?? [];
              return _buildList(context, list, taxonomy);
            },
          ),
        ),
      );
    } else {
      // Fallback filter map for general category / region / tag slug
      final filterMap = <String, String?>{'category_id': slug};
      final experiencesAsync = ref.watch(experiencesProvider(filterMap));

      return Scaffold(
        backgroundColor: AppColors.ivory,
        appBar: AppBar(
          backgroundColor: AppColors.ivory,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.ink),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            constraints: AppTouchTarget.minConstraints,
          ),
          title: Text(
            _collectionTitle,
            style: AppTypography.headingMedium.copyWith(
              color: AppColors.forest,
            ),
          ),
        ),
        body: SafeArea(
          child: AsyncValueView<List<Experience>>(
            value: experiencesAsync,
            onRetry: () => ref.refresh(experiencesProvider(filterMap)),
            isEmpty: (list) => list.isEmpty,
            emptyView: EmptyStateView(
              title: l10n.noExperiencesFound,
              description: 'No experiences found in this collection.',
              actionLabel: l10n.exploreAll,
              onActionPressed: () => context.go('/explore'),
            ),
            data: (experiences) => _buildList(context, experiences, taxonomy),
          ),
        ),
      );
    }
  }

  Widget _buildList(
    BuildContext context,
    List<Experience> experiences,
    ExperienceTaxonomy? taxonomy,
  ) {
    return ListView.separated(
      padding: AppSpacing.screenPadding,
      itemCount: experiences.length + 1,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.lg16),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _collectionSubtitle,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.disabledText,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs4),
                Text(
                  '${experiences.length} ${experiences.length == 1 ? 'experience' : 'experiences'} available',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.forest,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }

        final exp = experiences[index - 1];
        final presentation = ExperiencePresentation.from(exp, taxonomy);
        return ExperienceCard(
          width: double.infinity,
          title: exp.title,
          location: exp.locationName ?? 'Nepal',
          rating: exp.ratingAvg,
          reviewCount: exp.ratingCount,
          priceText: AppFormatters.formatNpr(exp.pricePaisa),
          imageUrl: exp.coverImageUrl,
          familyLabel: presentation.familyLabel,
          typeLabel: presentation.typeLabel,
          detailText: presentation.detailText,
          onTap: () => context.push('/experience/${exp.id}'),
        );
      },
    );
  }
}
