// PL-07 Explore Screen
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../l10n/app_localizations.dart';
import '../../models/category.dart';
import '../../models/experience.dart';
import '../../models/region.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../search/filter_sheet.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Map<String, String?> _searchFilters = const {'sort_by': 'relevance'};
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final query = value.trim();
      setState(() {
        _searchQuery = query;
        _searchFilters = Map.unmodifiable({
          if (query.isNotEmpty) 'search_query': query,
          'sort_by': 'relevance',
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(categoriesProvider);
    final regionsAsync = ref.watch(regionsProvider);

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 128),
        child: FloatingActionButton(
          onPressed: () => context.push('/map'),
          backgroundColor: AppColors.forest,
          foregroundColor: AppColors.white,
          shape: const CircleBorder(),
          tooltip: 'Map View',
          child: const Icon(Icons.location_on_outlined),
        ),
      ),
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
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
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
                          icon: const Icon(
                            Icons.notifications_none_rounded,
                            color: AppColors.white,
                            size: 22,
                          ),
                          onPressed: () =>
                              context.push('/profile/notifications'),
                          tooltip: 'Notifications',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search,
                          size: 24,
                          color: AppColors.forest,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            textInputAction: TextInputAction.search,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: l10n.searchHint,
                              hintStyle: const TextStyle(
                                color: AppColors.disabledText,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchDebounce?.cancel();
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _searchFilters = const {'sort_by': 'relevance'};
                              });
                            },
                            icon: const Icon(
                              Icons.close,
                              size: 20,
                              color: AppColors.disabledText,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_searchQuery.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _ExploreSearchResults(filters: _searchFilters),
                  ],
                  const SizedBox(height: 24),

                  // Explore Filters
                  SectionHeader(
                    title: 'Filter Experiences',
                    actionLabel: 'More Filters',
                    onActionTap: () => _openFilters(context),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChipPill(
                          label: 'All Experiences',
                          icon: Icons.explore_outlined,
                          isSelected: false,
                          onSelected: (_) => context.push('/search'),
                        ),
                        const SizedBox(width: 8),
                        FilterChipPill(
                          label: l10n.easy,
                          icon: Icons.directions_walk,
                          isSelected: false,
                          onSelected: (_) =>
                              context.push('/search?difficulty=easy'),
                        ),
                        const SizedBox(width: 8),
                        FilterChipPill(
                          label: l10n.moderate,
                          icon: Icons.hiking,
                          isSelected: false,
                          onSelected: (_) =>
                              context.push('/search?difficulty=moderate'),
                        ),
                        const SizedBox(width: 8),
                        FilterChipPill(
                          label: l10n.challenging,
                          icon: Icons.landscape_outlined,
                          isSelected: false,
                          onSelected: (_) =>
                              context.push('/search?difficulty=challenging'),
                        ),
                        const SizedBox(width: 8),
                        FilterChipPill(
                          label: l10n.strenuous,
                          icon: Icons.terrain,
                          isSelected: false,
                          onSelected: (_) =>
                              context.push('/search?difficulty=strenuous'),
                        ),
                      ],
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
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.35,
                            ),
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          return GestureDetector(
                            onTap: () => context.push(
                              '/search?category_id=${category.id}',
                            ),
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
                    title: 'Popular Regions',
                    subtitle: 'From Annapurna circuits to Everest highlands',
                    actionLabel: l10n.seeAll,
                    onActionTap: () => context.push('/search'),
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
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final region = regions[index];
                            return GestureDetector(
                              onTap: () => context.push(
                                '/search?region_id=${region.id}',
                              ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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

  Future<void> _openFilters(BuildContext context) async {
    final result = await showModalBottomSheet<Map<String, String?>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (context) => const FilterSheet(),
    );

    if (result == null || !context.mounted) return;

    final queryParameters = <String, String>{
      for (final entry in result.entries)
        if (entry.value != null &&
            entry.value!.isNotEmpty &&
            !(entry.key == 'sort_by' && entry.value == 'relevance'))
          entry.key: entry.value!,
    };
    context.push(
      Uri(path: '/search', queryParameters: queryParameters).toString(),
    );
  }
}

class _ExploreSearchResults extends ConsumerWidget {
  final Map<String, String?> filters;

  const _ExploreSearchResults({required this.filters});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(experiencesProvider(filters));
    return AsyncValueView<List<Experience>>(
      value: results,
      onRetry: () => ref.refresh(experiencesProvider(filters)),
      isEmpty: (items) => items.isEmpty,
      emptyView: const EmptyStateView(
        icon: Icons.search_off,
        title: 'No Experiences Found',
        description: 'Try another trail, place, or trek.',
      ),
      data: (items) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${items.length} experiences found',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.forest,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (experience) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: ExperienceCard(
                width: double.infinity,
                title: experience.title,
                location: experience.locationName ?? 'Nepal',
                rating: experience.ratingAvg,
                reviewCount: experience.ratingCount,
                priceText: AppFormatters.formatNpr(experience.pricePaisa),
                imageUrl: experience.coverImageUrl,
                categoryTag: experience.difficulty.name.toUpperCase(),
                onTap: () => context.push('/experience/${experience.id}'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
