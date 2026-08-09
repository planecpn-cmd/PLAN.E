// PL-07 Explore Screen
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

// Header image content height (excludes the status bar inset, which each
// user adds on top). Shared by _ScrollableExploreHeader's own sizing and
// _ExploreScreenState's scroll-based pin detection so they can't drift.
const double _kExploreHeaderContentHeight = 112;

class ExploreScreen extends ConsumerStatefulWidget {
  final String? initialQuery;

  const ExploreScreen({super.key, this.initialQuery});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  late final TextEditingController _searchController = TextEditingController(
    text: widget.initialQuery ?? '',
  );
  late String _searchQuery = widget.initialQuery ?? '';
  late Map<String, String?> _searchFilters = Map.unmodifiable({
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty)
      'search_query': widget.initialQuery,
    'sort_by': 'relevance',
  });
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
    final navigationClearance =
        MediaQuery.viewPaddingOf(context).bottom + 128.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: Padding(
          padding: EdgeInsets.only(bottom: navigationClearance),
          child: FloatingActionButton(
            onPressed: () => context.push('/map'),
            backgroundColor: AppColors.sage,
            foregroundColor: AppColors.ink,
            shape: const CircleBorder(),
            tooltip: 'Map View',
            child: const Icon(Icons.location_on_outlined),
          ),
        ),
        body: PlanEBackground(
          safeArea: false,
          child: RefreshIndicator(
            color: AppColors.forest,
            onRefresh: () async {
              ref.invalidate(categoriesProvider);
              ref.invalidate(regionsProvider);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // One collapsing header owning both the photo and the search
                // bar, rather than two stacked slivers. Two sequential slivers
                // can never overlap, so the search bar was always forced to
                // start below the photo's bottom edge — it could not sit
                // centered on the fade seam no matter how the heights were
                // tuned. Sharing one box lets the search bar be positioned
                // relative to that edge directly.
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _ExploreHeaderDelegate(
                    statusBarInset: MediaQuery.paddingOf(context).top,
                    title: l10n.explore,
                    onNotificationsTap: () => context.push('/notifications'),
                    searchBar: _ExploreSearchBar(
                      controller: _searchController,
                      hintText: l10n.searchHint,
                      onChanged: _onSearchChanged,
                      onClear: () {
                        _searchDebounce?.cancel();
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _searchFilters = const {'sort_by': 'relevance'};
                        });
                      },
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_searchQuery.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _ExploreSearchResults(filters: _searchFilters),
                        ],
                        const SizedBox(height: 16),

                        // Explore Filters
                        SectionHeader(
                          title: 'Filter Experiences',
                          actionLabel: 'More Filters',
                          onActionTap: () => _openFilters(context),
                        ),
                        const SizedBox(height: 8),
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
                                onSelected: (_) => context.push(
                                  '/search?difficulty=challenging',
                                ),
                              ),
                              const SizedBox(width: 8),
                              FilterChipPill(
                                label: l10n.strenuous,
                                icon: Icons.terrain,
                                isSelected: false,
                                onSelected: (_) => context.push(
                                  '/search?difficulty=strenuous',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

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
                        const SizedBox(height: 8),

                        AsyncValueView<List<Category>>(
                          value: categoriesAsync,
                          onRetry: () => ref.refresh(categoriesProvider),
                          isEmpty: (list) => list.isEmpty,
                          emptyView: const EmptyStateView(
                            title: 'No Categories Available',
                            description:
                                'Explore categories will be loaded soon.',
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
                                    mainAxisSpacing: 10,
                                    crossAxisSpacing: 10,
                                    childAspectRatio: 1.85,
                                  ),
                              itemBuilder: (context, index) {
                                final category = categories[index];
                                // No real cover photos are seeded for categories
                                // yet (all null) — a bespoke icon-on-gradient card
                                // reads as an intentional brand pattern, where the
                                // old PlanEPhoto fallback (flat sage + centered
                                // icon + dark wash) read as a broken/loading image.
                                return _CategoryCard(
                                  title: category.nameEn,
                                  icon: _categoryIcon(category.slug),
                                  onTap: () => context.push(
                                    '/search?category_id=${category.id}',
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Section 2: Popular Regions
                        SectionHeader(
                          title: 'Popular Regions',
                          subtitle:
                              'From Annapurna circuits to Everest highlands',
                          actionLabel: l10n.seeAll,
                          onActionTap: () => context.push('/search'),
                        ),
                        const SizedBox(height: 8),

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
                                  return SizedBox(
                                    width: 150,
                                    child: _RegionCard(
                                      title: region.nameEn,
                                      subtitle: region.nameNe,
                                      icon: _regionIcon(region.slug),
                                      onTap: () => context.push(
                                        '/search?region_id=${region.id}',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
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

  IconData _categoryIcon(String slug) {
    switch (slug) {
      case 'trekking':
        return Icons.hiking;
      case 'hiking':
        return Icons.directions_walk;
      case 'camping':
        return Icons.cabin_outlined;
      case 'climbing':
        return Icons.terrain;
      case 'homestay':
        return Icons.home_outlined;
      case 'culture':
        return Icons.temple_buddhist_outlined;
      case 'wildlife':
        return Icons.pets;
      case 'wellness':
        return Icons.self_improvement;
      case 'volunteering':
        return Icons.volunteer_activism;
      default:
        return Icons.landscape_outlined;
    }
  }

  IconData _regionIcon(String slug) {
    switch (slug) {
      case 'everest':
      case 'manaslu':
      case 'kanchenjunga':
        return Icons.terrain;
      case 'annapurna':
      case 'langtang':
        return Icons.landscape_outlined;
      case 'mustang':
        return Icons.account_balance_outlined;
      case 'chitwan':
        return Icons.forest_outlined;
      case 'pokhara':
      case 'rara':
        return Icons.water_outlined;
      case 'kathmandu':
        return Icons.temple_buddhist_outlined;
      default:
        return Icons.map_outlined;
    }
  }
}

/// Collapsing Explore header: photo + title on top, search bar straddling
/// the photo's bottom edge, collapsing to just the search bar when scrolled.
///
/// Driven entirely by `shrinkOffset`, which the sliver system updates every
/// frame — no ScrollController listener and no setState-per-scroll-frame,
/// which is what made the previous version stutter.
class _ExploreHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double statusBarInset;
  final String title;
  final VoidCallback onNotificationsTap;
  final Widget searchBar;

  const _ExploreHeaderDelegate({
    required this.statusBarInset,
    required this.title,
    required this.onNotificationsTap,
    required this.searchBar,
  });

  static const double _searchBarHeight = 50;
  static const double _bottomPad = 8;
  // Clearance between the status bar and the search bar once collapsed.
  static const double _pinnedTopGap = 12;

  /// Height of the photo area (below the status bar).
  double get _imageHeight => statusBarInset + _kExploreHeaderContentHeight;

  // Expanded: photo, plus enough room below its bottom edge for the search
  // bar's lower half. The search bar is bottom-anchored, so this is exactly
  // what centers it on the photo's bottom edge.
  @override
  double get maxExtent => _imageHeight + _searchBarHeight / 2 + _bottomPad;

  // Collapsed: status bar + gap + search bar + pad, and nothing else. The
  // old delegate always reserved statusBarInset even while expanded, which
  // is where the dead space under the search bar came from.
  @override
  double get minExtent =>
      statusBarInset + _pinnedTopGap + _searchBarHeight + _bottomPad;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final collapseRange = maxExtent - minExtent;
    final t = collapseRange <= 0
        ? 1.0
        : (shrinkOffset / collapseRange).clamp(0.0, 1.0);

    return Stack(
      clipBehavior: Clip.hardEdge,
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.ivory),
        // Slides up and fades as the header collapses, so it clears out
        // from behind the search bar rather than being abruptly clipped.
        Positioned(
          top: -shrinkOffset,
          left: 0,
          right: 0,
          height: _imageHeight,
          child: Opacity(
            opacity: 1 - t,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // topCenter, so the crop takes from the bottom (lake and
                // reflection) and keeps the peaks — they're the subject of
                // the app, and cropping from the top decapitated them.
                // BoxFit.cover, not fill, so the photo keeps its aspect
                // ratio instead of being squashed to the box.
                Image.asset(
                  'assets/images/explore_header_mountains.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
                // The photo's own fade-to-pale tail sits in its bottom rows,
                // which cropping from below now discards — so the seam is
                // painted explicitly here instead. Without it the photo
                // would end on a hard horizontal edge mid-search-bar.
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 46,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00FFFFFF), AppColors.ivory],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: statusBarInset + 14,
                  left: 32,
                  right: 32,
                  height: 56,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: AppColors.forest,
                          ),
                        ),
                      ),
                      _HeaderActionButton(
                        icon: Icons.notifications_none_rounded,
                        tooltip: 'Notifications',
                        onPressed: onNotificationsTap,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Bottom-anchored: expanded, its centre lands exactly on the photo's
        // bottom edge (maxExtent is defined from that); collapsed, it sits
        // statusBarInset + 12 below the top. Both fall out of one rule, so
        // the transition between them is continuous instead of a jump.
        Positioned(
          left: 18,
          right: 18,
          bottom: _bottomPad,
          height: _searchBarHeight,
          child: searchBar,
        ),
      ],
    );
  }

  @override
  bool shouldRebuild(covariant _ExploreHeaderDelegate oldDelegate) {
    return searchBar != oldDelegate.searchBar ||
        title != oldDelegate.title ||
        statusBarInset != oldDelegate.statusBarInset;
  }
}

class _ExploreSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _ExploreSearchBar({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: const TextStyle(color: AppColors.ink, fontSize: 14),
              decoration: InputDecoration(
                hintText: hintText,
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
          if (controller.text.isNotEmpty)
            IconButton(
              tooltip: 'Clear search',
              onPressed: onClear,
              icon: const Icon(
                Icons.close,
                size: 20,
                color: AppColors.disabledText,
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _HeaderActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.ivory.withValues(alpha: 0.88),
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon, size: 21, color: AppColors.forest),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.forest, AppColors.deep],
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Oversized, low-opacity icon as background texture — fills the
            // card with brand-relevant visual interest in place of a photo.
            Positioned(
              right: -12,
              bottom: -12,
              child: Icon(
                icon,
                size: 78,
                color: AppColors.white.withValues(alpha: 0.10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 16, color: AppColors.white),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
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
    );
  }
}

class _RegionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _RegionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.forest, AppColors.deep],
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: -12,
              bottom: -12,
              child: Icon(
                icon,
                size: 76,
                color: AppColors.white.withValues(alpha: 0.10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
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
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.sage),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
