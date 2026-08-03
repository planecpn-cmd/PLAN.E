// PL-07 Explore Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/category.dart';
import '../../models/region.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final regionsAsync = ref.watch(regionsProvider);

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        backgroundColor: AppColors.ivory,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Explore Nepal',
          style: AppTypography.headingMedium.copyWith(color: AppColors.forest),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md12),
            child: TextButton.icon(
              onPressed: () => context.push('/map'),
              icon: const Icon(Icons.map_outlined, color: AppColors.forest, size: 20),
              label: Text(
                'Map View',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.forest,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                minimumSize: const Size(AppTouchTarget.minSize, AppTouchTarget.minSize),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.forest,
          onRefresh: () async {
            ref.invalidate(categoriesProvider);
            ref.invalidate(regionsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Search Bar
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
                              'Search destinations, categories...',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.disabledText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl24),

                // Section 1: Regions
                const SectionHeader(
                  title: 'Regions of Nepal',
                  subtitle: 'From Annapurna circuits to Everest highlands',
                ),
                const SizedBox(height: AppSpacing.md12),

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
                        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.md12),
                        itemBuilder: (context, index) {
                          final region = regions[index];
                          return _buildRegionCard(context, region);
                        },
                      ),
                    );
                  },
                ),

                const SizedBox(height: AppSpacing.xxl24),

                // Section 2: Categories Grid
                const SectionHeader(
                  title: 'Categories',
                  subtitle: 'Find journeys tailored to your adventure style',
                ),
                const SizedBox(height: AppSpacing.md12),

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
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.3,
                        crossAxisSpacing: AppSpacing.md12,
                        mainAxisSpacing: AppSpacing.md12,
                      ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return _buildCategoryCard(context, category);
                      },
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

  Widget _buildRegionCard(BuildContext context, Region region) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadii.borderMd16,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Material(
        color: AppColors.transparent,
        borderRadius: AppRadii.borderMd16,
        child: InkWell(
          onTap: () => context.push('/search?region_id=${region.id}'),
          borderRadius: AppRadii.borderMd16,
          child: Stack(
            children: [
              if (region.coverImageUrl != null && region.coverImageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: AppRadii.borderMd16,
                  child: CachedNetworkImage(
                    imageUrl: region.coverImageUrl!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(color: AppColors.forest),
                  ),
                )
              else
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.forest,
                    borderRadius: AppRadii.borderMd16,
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: AppRadii.borderMd16,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.transparent,
                      AppColors.deep.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Positioned(
                bottom: AppSpacing.md12,
                left: AppSpacing.md12,
                right: AppSpacing.md12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      region.nameEn,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.ivory,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      region.nameNe,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.sage,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, Category category) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadii.borderMd16,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Material(
        color: AppColors.transparent,
        borderRadius: AppRadii.borderMd16,
        child: InkWell(
          onTap: () => context.push('/search?category_id=${category.id}'),
          borderRadius: AppRadii.borderMd16,
          child: Padding(
            padding: AppSpacing.paddingMd12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.sage,
                    borderRadius: AppRadii.borderSm8,
                  ),
                  child: Center(
                    child: Icon(
                      _getCategoryIcon(category.slug),
                      color: AppColors.forest,
                      size: 24,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.nameEn,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      category.nameNe,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.disabledText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String slug) {
    switch (slug.toLowerCase()) {
      case 'trekking':
      case 'treks':
        return Icons.hiking;
      case 'homestays':
      case 'homestay':
        return Icons.home_work_outlined;
      case 'culture':
      case 'cultural':
        return Icons.museum_outlined;
      case 'wildlife':
      case 'safari':
        return Icons.pets_outlined;
      case 'expeditions':
      case 'climbing':
        return Icons.landscape_outlined;
      case 'food':
      case 'culinary':
        return Icons.restaurant_outlined;
      default:
        return Icons.explore_outlined;
    }
  }
}

