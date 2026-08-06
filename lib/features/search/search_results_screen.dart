// PL-08 Search Results
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../models/experience.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'filter_sheet.dart';

class SearchResultsScreen extends ConsumerStatefulWidget {
  final String? initialQuery;
  final String? initialCategoryId;
  final String? initialRegionId;
  final String? initialDifficulty;
  final String? initialSortBy;

  const SearchResultsScreen({
    super.key,
    this.initialQuery,
    this.initialCategoryId,
    this.initialRegionId,
    this.initialDifficulty,
    this.initialSortBy,
  });

  @override
  ConsumerState<SearchResultsScreen> createState() =>
      _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  late final TextEditingController _searchController;
  String _searchQuery = '';
  String? _difficulty;
  String? _categoryId;
  String? _regionId;
  String _sortBy = 'relevance';
  late Map<String, String?> _filters;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.initialQuery ?? '';
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    _difficulty = widget.initialDifficulty;
    _categoryId = widget.initialCategoryId;
    _regionId = widget.initialRegionId;
    _sortBy = widget.initialSortBy ?? 'relevance';
    _filters = _buildFilters();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Map<String, String?> _buildFilters() => Map.unmodifiable({
    if (_searchQuery.isNotEmpty) 'search_query': _searchQuery,
    if (_difficulty != null && _difficulty != 'all') 'difficulty': _difficulty,
    if (_categoryId != null) 'category_id': _categoryId,
    if (_regionId != null) 'region_id': _regionId,
    'sort_by': _sortBy,
  });

  void _search(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = value.trim();
        _filters = _buildFilters();
      });
    });
  }

  void _submitSearch(String value) {
    _debounce?.cancel();
    final query = value.trim();
    setState(() {
      _searchQuery = query;
      _filters = _buildFilters();
    });
    FocusScope.of(context).unfocus();
    if (query.isNotEmpty) {
      ref.read(recentSearchesRepositoryProvider).addSearchQuery(query);
      ref.invalidate(recentSearchesProvider);
    }
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<Map<String, String?>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (context) => FilterSheet(
        initialDifficulty: _difficulty,
        initialCategoryId: _categoryId,
        initialRegionId: _regionId,
        initialSortBy: _sortBy,
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _difficulty = result['difficulty'];
      _categoryId = result['category_id'];
      _regionId = result['region_id'];
      _sortBy = result['sort_by'] ?? 'relevance';
      _filters = _buildFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final experiencesAsync = ref.watch(experiencesProvider(_filters));

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: PlanEBackground(
        safeArea: false,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      constraints: AppTouchTarget.minConstraints,
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go('/explore'),
                      icon: const Icon(
                        Icons.chevron_left,
                        size: 32,
                        color: AppColors.forest,
                      ),
                    ),
                    const Expanded(child: PlanELogo(fontSize: 24)),
                    const SizedBox(width: AppTouchTarget.minSize),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppRadii.borderPill,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: AppColors.forest),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          onChanged: _search,
                          onSubmitted: _submitSearch,
                          style: AppTypography.bodyMedium,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            hintText: 'Search trails, places, treks...',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _ActionPill(
                      icon: Icons.tune,
                      label: 'Filter',
                      onTap: _openFilters,
                    ),
                    const SizedBox(width: 10),
                    _ActionPill(
                      icon: Icons.swap_vert,
                      label: 'Sort',
                      onTap: _openFilters,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: AsyncValueView<List<Experience>>(
                  value: experiencesAsync,
                  onRetry: () => ref.refresh(experiencesProvider(_filters)),
                  isEmpty: (items) => items.isEmpty,
                  emptyView: const EmptyStateView(
                    icon: Icons.search_off,
                    title: 'No Experiences Found',
                    description:
                        'Try another destination or adjust your filters.',
                  ),
                  data: (experiences) => ListView.separated(
                    key: const PageStorageKey('search-results'),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                    itemCount: experiences.length + 1,
                    separatorBuilder: (_, index) =>
                        SizedBox(height: index == 0 ? 14 : 16),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Search Results',
                              style: AppTypography.headingLarge.copyWith(
                                color: AppColors.forest,
                              ),
                            ),
                            Text(
                              '${experiences.length} experiences found',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.disabledText,
                              ),
                            ),
                          ],
                        );
                      }
                      return _SearchExperienceCard(
                        experience: experiences[index - 1],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.sage,
      shape: const StadiumBorder(side: BorderSide(color: AppColors.border)),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppColors.forest),
              const SizedBox(width: 7),
              Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.forest,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchExperienceCard extends StatelessWidget {
  final Experience experience;

  const _SearchExperienceCard({required this.experience});

  String get _duration {
    if (experience.durationHours >= 24 && experience.durationHours % 24 == 0) {
      final days = experience.durationHours ~/ 24;
      return '$days ${days == 1 ? 'day' : 'days'}';
    }
    return '${experience.durationHours} hours';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadii.borderLg24,
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              PlanEPhoto(
                imageUrl: experience.coverImageUrl,
                height: 170,
                width: double.infinity,
                radius: AppRadii.lg24,
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Material(
                  color: AppColors.white,
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'Save experience',
                    onPressed: () {},
                    icon: const Icon(
                      Icons.bookmark_border,
                      color: AppColors.forest,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  experience.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.headingMedium.copyWith(
                    fontFamily: 'serif',
                    color: AppColors.forest,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    _Meta(icon: Icons.schedule, text: _duration),
                    _Meta(
                      icon: Icons.terrain,
                      text: experience.difficulty.name.toUpperCase(),
                    ),
                    _Meta(
                      icon: Icons.star,
                      text:
                          '${experience.ratingAvg} (${experience.ratingCount})',
                      iconColor: AppColors.gold,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppFormatters.formatNpr(experience.pricePaisa),
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.forest,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'per person',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.disabledText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppButton(
                      label: 'Book Now',
                      minHeight: 42,
                      fontSize: 13,
                      onPressed: () =>
                          context.push('/booking/${experience.id}'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color iconColor;

  const _Meta({
    required this.icon,
    required this.text,
    this.iconColor = AppColors.forest,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 4),
        Text(text, style: AppTypography.caption.copyWith(color: AppColors.ink)),
      ],
    );
  }
}
