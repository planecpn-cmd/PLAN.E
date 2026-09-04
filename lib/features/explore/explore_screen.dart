// PL-07 Explore Screen
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/experience_presentation.dart';
import '../../l10n/app_localizations.dart';
import '../../models/experience.dart';
import '../../models/experience_family.dart';
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
    final familiesAsync = ref.watch(experienceFamiliesProvider);
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
              ref.invalidate(experienceFamiliesProvider);
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

                        // Intent comes before terrain or geography: the six
                        // families explain the breadth of PLAN E at a glance.
                        SectionHeader(
                          title: 'Browse by experience',
                          subtitle: 'Choose the kind of day you want to have',
                          actionLabel: 'All filters',
                          onActionTap: () => _openFilters(context),
                        ),
                        const SizedBox(height: 8),
                        AsyncValueView<List<ExperienceFamily>>(
                          value: familiesAsync,
                          onRetry: () =>
                              ref.refresh(experienceFamiliesProvider),
                          isEmpty: (list) => list.isEmpty,
                          emptyView: const EmptyStateView(
                            title: 'No Experience Families Available',
                            description:
                                'Experience families will be loaded soon.',
                          ),
                          data: (families) {
                            return GridView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: families.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 1.42,
                                  ),
                              itemBuilder: (context, index) {
                                final family = families[index];
                                return ExperienceFamilyCard(
                                  family: family,
                                  onTap: () => context.push(
                                    '/search?family=${family.slug}',
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        const SectionHeader(
                          title: 'Explore by mood',
                          subtitle: 'Start with how you want to feel',
                        ),
                        const SizedBox(height: 8),
                        ExperienceMoodGrid(
                          onSelected: (mood) =>
                              context.push('/search?family=${mood.familySlug}'),
                        ),
                        const SizedBox(height: 24),

                        // Location supports intent; it no longer defines it.
                        SectionHeader(
                          title: 'Explore by location',
                          subtitle:
                              'Cities, villages, valleys, and wild places',
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
                Image.asset(
                  'assets/images/photo_29306578.webp',
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.4),
                  semanticLabel:
                      'Traveller exploring a stupa in Ghandruk, Nepal',
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(color: AppColors.overlay),
                ),
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
                            color: AppColors.white,
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
    final taxonomy = ref.watch(experienceTaxonomyProvider).valueOrNull;
    return AsyncValueView<List<Experience>>(
      value: results,
      onRetry: () => ref.refresh(experiencesProvider(filters)),
      isEmpty: (items) => items.isEmpty,
      emptyView: const EmptyStateView(
        icon: Icons.search_off,
        title: 'No Experiences Found',
        description: 'Try another experience, place, or activity.',
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
          ...items.map((experience) {
            final presentation = ExperiencePresentation.from(
              experience,
              taxonomy,
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: ExperienceCard(
                width: double.infinity,
                title: experience.title,
                location: experience.locationName ?? 'Nepal',
                rating: experience.ratingAvg,
                reviewCount: experience.ratingCount,
                priceText: AppFormatters.formatNpr(experience.pricePaisa),
                imageUrl: experience.coverImageUrl,
                familyLabel: presentation.familyLabel,
                typeLabel: presentation.typeLabel,
                detailText: presentation.detailText,
                onTap: () => context.push('/experience/${experience.id}'),
              ),
            );
          }),
        ],
      ),
    );
  }
}
