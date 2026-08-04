// PL-07 Explore Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../models/category.dart';
import '../../models/region.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(categoriesProvider);
    final regionsAsync = ref.watch(regionsProvider);

    return Scaffold(
      body: PlanEBackground(
        safeArea: false,
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: AppColors.forest,
            onRefresh: () async {
              ref.invalidate(categoriesProvider);
              ref.invalidate(regionsProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.explore,
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.forest,
                          ),
                        ),
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: AppColors.forest,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.map_outlined, color: AppColors.white, size: 22),
                          onPressed: () => context.push('/map'),
                          tooltip: 'Map View',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Search Bar Input Trigger
                  GestureDetector(
                    onTap: () => context.push('/search'),
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, size: 24, color: AppColors.forest),
                          const SizedBox(width: 12),
                          Text(
                            l10n.searchHint,
                            style: const TextStyle(color: AppColors.disabledText, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section 1: Categories
                  Text(
                    l10n.categories,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.forest,
                    ),
                  ),
                  const SizedBox(height: 12),

                  AsyncValueView<List<Category>>(
                    value: categoriesAsync,
                    onRetry: () => ref.refresh(categoriesProvider),
                    isEmpty: (list) => list.isEmpty,
                    emptyView: const EmptyStateView(
                      title: 'No Categories Available',
                      description: 'Explore categories will be loaded soon.',
                    ),
                    data: (categories) {
                      return GridView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: categories.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.35,
                        ),
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          return GestureDetector(
                            onTap: () => context.push('/search?category_id=${category.id}'),
                            child: PlanEPhoto(
                              imageUrl: category.coverImageUrl,
                              radius: 22,
                              overlay: Container(
                                padding: const EdgeInsets.all(12),
                                alignment: Alignment.bottomLeft,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppColors.transparent,
                                      AppColors.black.withValues(alpha: .65),
                                    ],
                                  ),
                                ),
                                child: Text(
                                  category.nameEn,
                                  style: const TextStyle(
                                    fontFamily: 'serif',
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Section 2: Popular Regions
                  SectionHeader(
                    title: l10n.regions,
                    subtitle: 'From Annapurna circuits to Everest highlands',
                  ),
                  const SizedBox(height: 12),

                  AsyncValueView<List<Region>>(
                    value: regionsAsync,
                    onRetry: () => ref.refresh(regionsProvider),
                    isEmpty: (list) => list.isEmpty,
                    emptyView: const EmptyStateView(
                      title: 'No Regions Found',
                      description: 'Regions will appear here shortly.',
                    ),
                    data: (regions) {
                      return SizedBox(
                        height: 120,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: regions.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final region = regions[index];
                            return GestureDetector(
                              onTap: () => context.push('/search?region_id=${region.id}'),
                              child: SizedBox(
                                width: 150,
                                child: PlanEPhoto(
                                  imageUrl: region.coverImageUrl,
                                  radius: 20,
                                  overlay: Container(
                                    padding: const EdgeInsets.all(10),
                                    alignment: Alignment.bottomLeft,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          AppColors.transparent,
                                          AppColors.black.withValues(alpha: .6),
                                        ],
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          region.nameEn,
                                          style: const TextStyle(
                                            fontFamily: 'serif',
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          region.nameNe,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.sage,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
