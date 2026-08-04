// PL-06 Home Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../l10n/app_localizations.dart';
import '../../models/experience.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final homeRailsAsync = ref.watch(homeRailsProvider);

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.forest,
          onRefresh: () async {
            ref.invalidate(homeRailsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header / Search Bar Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg16,
                    AppSpacing.md12,
                    AppSpacing.lg16,
                    AppSpacing.sm8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PLAN E',
                              style: AppTypography.bodyLarge.copyWith(
                                color: AppColors.forest,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              'Explore Authentic Nepal',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.disabledText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.bookmark_outline, color: AppColors.ink),
                        onPressed: () => context.push('/saved'),
                        constraints: AppTouchTarget.minConstraints,
                        tooltip: 'Saved Experiences',
                      ),
                    ],
                  ),
                ),

                // Hero Banner
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg16, vertical: AppSpacing.sm8),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.deep, AppColors.forest],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: AppRadii.borderLg24,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.deep.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: AppSpacing.paddingXxl24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md12,
                            vertical: AppSpacing.xs4,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: AppRadii.borderPill,
                          ),
                          child: Text(
                            'NEPAL EXPEDITIONS',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.ivory,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md12),
                        Text(
                          'Unforgettable Adventures & Local Stays',
                          style: AppTypography.headingLarge.copyWith(
                            color: AppColors.ivory,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm8),
                        Text(
                          'Connect with verified local guides and authentic village homestays across Nepal.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.sage,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl20),

                        // Search Trigger Input Box
                        Material(
                          color: AppColors.white,
                          borderRadius: AppRadii.borderMd16,
                          child: InkWell(
                            onTap: () => context.push('/search'),
                            borderRadius: AppRadii.borderMd16,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg16,
                                vertical: AppSpacing.md12,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.search, color: AppColors.forest),
                                  const SizedBox(width: AppSpacing.md12),
                                  Expanded(
                                    child: Text(
                                      l10n.searchHint,
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: AppColors.disabledText,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: AppSpacing.paddingSm8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.sage,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.tune, size: 18, color: AppColors.forest),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl20),

                // Content Rails wrapped in AsyncValueView
                AsyncValueView<Map<String, List<Experience>>>(
                  value: homeRailsAsync,
                  onRetry: () => ref.refresh(homeRailsProvider),
                  isEmpty: (data) => data.values.every((list) => list.isEmpty),
                  emptyView: const Padding(
                    padding: AppSpacing.paddingXxl24,
                    child: EmptyStateView(
                      title: 'No Experiences Available',
                      description: 'Check back soon for new curated Nepal adventures.',
                    ),
                  ),
                  data: (railsMap) {
                    return Column(
                      children: [
                        // Rail 1: Recommended
                        if (railsMap['recommended']?.isNotEmpty ?? false) ...[
                          ContentRail(
                            title: l10n.recommendedForYou,
                            subtitle: 'Handpicked experiences based on popular journeys',
                            actionLabel: l10n.seeAll,
                            onActionTap: () => context.push('/collection/recommended'),
                            items: railsMap['recommended']!
                                .map((exp) => _buildExperienceCard(context, exp))
                                .toList(),
                          ),
                          const SizedBox(height: AppSpacing.xxl24),
                        ],

                        // Rail 2: Trending
                        if (railsMap['trending']?.isNotEmpty ?? false) ...[
                          ContentRail(
                            title: l10n.trendingNow,
                            subtitle: 'Most booked trips this season in Nepal',
                            actionLabel: l10n.seeAll,
                            onActionTap: () => context.push('/collection/trending'),
                            items: railsMap['trending']!
                                .map((exp) => _buildExperienceCard(context, exp))
                                .toList(),
                          ),
                          const SizedBox(height: AppSpacing.xxl24),
                        ],

                        // Rail 3: Homestays
                        if (railsMap['homestays']?.isNotEmpty ?? false) ...[
                          ContentRail(
                            title: l10n.authenticHomestays,
                            subtitle: 'Immerse in local village hospitality',
                            actionLabel: l10n.seeAll,
                            onActionTap: () => context.push('/collection/homestays'),
                            items: railsMap['homestays']!
                                .map((exp) => _buildExperienceCard(context, exp))
                                .toList(),
                          ),
                          const SizedBox(height: AppSpacing.xxl24),
                        ],

                        // Rail 4: Community
                        if (railsMap['community']?.isNotEmpty ?? false) ...[
                          ContentRail(
                            title: l10n.communityLedTours,
                            subtitle: 'Direct impact travel supporting local communities',
                            actionLabel: l10n.seeAll,
                            onActionTap: () => context.push('/collection/community'),
                            items: railsMap['community']!
                                .map((exp) => _buildExperienceCard(context, exp))
                                .toList(),
                          ),
                          const SizedBox(height: AppSpacing.xxl24),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xxxl32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExperienceCard(BuildContext context, Experience exp) {
    return ExperienceCard(
      title: exp.title,
      location: exp.locationName ?? 'Nepal',
      rating: exp.ratingAvg,
      reviewCount: exp.ratingCount,
      priceText: AppFormatters.formatNpr(exp.pricePaisa),
      imageUrl: exp.coverImageUrl,
      categoryTag: exp.difficulty.name.toUpperCase(),
      onTap: () => context.push('/experience/${exp.id}'),
    );
  }
}

