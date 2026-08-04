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
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      body: PlanEBackground(
        safeArea: false,
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: AppColors.forest,
            onRefresh: () async {
              ref.invalidate(homeRailsProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row with Logo, Location & Points
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PlanELogo(fontSize: 26, centered: false),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 16, color: AppColors.forest),
                                SizedBox(width: 4),
                                Text(
                                  'Kathmandu, Nepal',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.forest,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 12,
                              backgroundColor: AppColors.white,
                              child: Icon(Icons.local_activity, size: 14, color: AppColors.gold),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${profileAsync.value?.points ?? 450} pts',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Hero Featured Banner Card
                  SizedBox(
                    height: 240,
                    child: PlanEPhoto(
                      imageUrl: 'https://images.unsplash.com/photo-1544735716-392fe2489ffa?auto=format&fit=crop&w=1200&q=80',
                      radius: 36,
                      overlay: Container(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              AppColors.black.withValues(alpha: .68),
                              AppColors.transparent,
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.gold,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'FEATURED',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Discover\nNepal Himalayas',
                              style: TextStyle(
                                fontFamily: 'serif',
                                color: AppColors.white,
                                fontSize: 30,
                                height: 1.05,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: 140,
                              child: AppButton(
                                label: 'Search Treks',
                                onPressed: () => context.push('/search'),
                                minHeight: 40,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Content Rails wrapped in AsyncValueView
                  AsyncValueView<Map<String, List<Experience>>>(
                    value: homeRailsAsync,
                    onRetry: () => ref.refresh(homeRailsProvider),
                    isEmpty: (data) => data.values.every((list) => list.isEmpty),
                    emptyView: const Padding(
                      padding: EdgeInsets.all(24),
                      child: EmptyStateView(
                        title: 'No Experiences Available',
                        description: 'Check back soon for new curated Nepal adventures.',
                      ),
                    ),
                    data: (railsMap) {
                      return Column(
                        children: [
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
                            const SizedBox(height: 24),
                          ],
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
                            const SizedBox(height: 24),
                          ],
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
                            const SizedBox(height: 24),
                          ],
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
                            const SizedBox(height: 24),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
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
