// PL-08 Search Results
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../l10n/app_localizations.dart';
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

  const SearchResultsScreen({
    super.key,
    this.initialQuery,
    this.initialCategoryId,
    this.initialRegionId,
    this.initialDifficulty,
  });

  @override
  ConsumerState<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  late TextEditingController _searchController;
  String? _selectedDifficulty;
  String? _categoryId;
  String? _regionId;
  String? _sortBy = 'relevance';
  String _searchQuery = '';
  bool _showRecentSearches = false;

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.initialQuery ?? '';
    _searchController = TextEditingController(text: _searchQuery);
    _selectedDifficulty = widget.initialDifficulty;
    _categoryId = widget.initialCategoryId;
    _regionId = widget.initialRegionId;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, String?> get _filterMap {
    return {
      if (_searchQuery.trim().isNotEmpty) 'search_query': _searchQuery.trim(),
      if (_selectedDifficulty != null && _selectedDifficulty != 'all')
        'difficulty': _selectedDifficulty,
      if (_categoryId != null && _categoryId!.isNotEmpty) 'category_id': _categoryId,
      if (_regionId != null && _regionId!.isNotEmpty) 'region_id': _regionId,
      if (_sortBy != null && _sortBy!.isNotEmpty) 'sort_by': _sortBy,
    };
  }

  void _submitSearch(String query) {
    setState(() {
      _searchQuery = query;
      _showRecentSearches = false;
    });
    if (query.trim().isNotEmpty) {
      ref.read(recentSearchesRepositoryProvider).addSearchQuery(query);
      ref.invalidate(recentSearchesProvider);
    }
  }

  void _openFilterSheet() async {
    final result = await showModalBottomSheet<Map<String, String?>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (context) => FilterSheet(
        initialDifficulty: _selectedDifficulty,
        initialCategoryId: _categoryId,
        initialRegionId: _regionId,
        initialSortBy: _sortBy,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedDifficulty = result['difficulty'];
        _categoryId = result['category_id'];
        _regionId = result['region_id'];
        _sortBy = result['sort_by'] ?? 'relevance';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final experiencesAsync = ref.watch(experiencesProvider(_filterMap));
    final recentSearchesAsync = ref.watch(recentSearchesProvider);

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
          l10n.searchResults,
          style: AppTypography.headingMedium.copyWith(color: AppColors.forest),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: AppColors.forest),
            onPressed: _openFilterSheet,
            constraints: AppTouchTarget.minConstraints,
            tooltip: 'Filter & Sort',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg16,
                vertical: AppSpacing.sm8,
              ),
              child: TextField(
                controller: _searchController,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
                decoration: InputDecoration(
                  hintText: 'Search by keyword, location, trek...',
                  hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.disabledText),
                  prefixIcon: const Icon(Icons.search, color: AppColors.forest),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20, color: AppColors.disabledText),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _showRecentSearches = true;
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg16,
                    vertical: AppSpacing.md12,
                  ),
                  border: const OutlineInputBorder(
                    borderRadius: AppRadii.borderMd16,
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: AppRadii.borderMd16,
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: AppRadii.borderMd16,
                    borderSide: BorderSide(color: AppColors.forest, width: 2),
                  ),
                ),
                onTap: () {
                  setState(() {
                    _showRecentSearches = true;
                  });
                },
                onSubmitted: _submitSearch,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),

            // Recent Searches Overlay / Chips if active
            if (_showRecentSearches)
              AsyncValueView<List<String>>(
                value: recentSearchesAsync,
                onRetry: () => ref.refresh(recentSearchesProvider),
                isEmpty: (list) => list.isEmpty,
                emptyView: const SizedBox.shrink(),
                data: (recentList) {
                  if (recentList.isEmpty) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg16,
                      vertical: AppSpacing.sm8,
                    ),
                    color: AppColors.sage.withValues(alpha: 0.3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Searches',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.forest,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                await ref
                                    .read(recentSearchesRepositoryProvider)
                                    .clearRecentSearches();
                                ref.invalidate(recentSearchesProvider);
                              },
                              child: Text(
                                'Clear',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.disabledText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs4),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: recentList.map((term) {
                              return Padding(
                                padding: const EdgeInsets.only(right: AppSpacing.sm8),
                                child: ActionChip(
                                  label: Text(term, style: AppTypography.caption),
                                  backgroundColor: AppColors.white,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: AppRadii.borderPill,
                                  ),
                                  onPressed: () {
                                    _searchController.text = term;
                                    _submitSearch(term);
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

            // Difficulty Chips Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg16,
                vertical: AppSpacing.sm8,
              ),
              child: Row(
                children: [
                  _buildDifficultyChip('all', 'All Levels'),
                  const SizedBox(width: AppSpacing.sm8),
                  _buildDifficultyChip('easy', 'Easy'),
                  const SizedBox(width: AppSpacing.sm8),
                  _buildDifficultyChip('moderate', 'Moderate'),
                  const SizedBox(width: AppSpacing.sm8),
                  _buildDifficultyChip('challenging', 'Challenging'),
                  const SizedBox(width: AppSpacing.sm8),
                  _buildDifficultyChip('strenuous', 'Strenuous'),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.sm8),

            // Results Counter & Active Filter Indicators
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Search Results',
                    style: AppTypography.headingMedium.copyWith(color: AppColors.ink),
                  ),
                  if (_categoryId != null ||
                      _regionId != null ||
                      _selectedDifficulty != null ||
                      _searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDifficulty = null;
                          _categoryId = null;
                          _regionId = null;
                          _sortBy = 'relevance';
                          _searchQuery = '';
                          _searchController.clear();
                          _showRecentSearches = false;
                        });
                      },
                      child: Text(
                        'Clear All Filters',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md12),

            // Async Results View (with PageStorageKey to preserve scroll position on back navigation)
            Expanded(
              child: AsyncValueView<List<Experience>>(
                value: experiencesAsync,
                onRetry: () => ref.refresh(experiencesProvider(_filterMap)),
                isEmpty: (list) => list.isEmpty,
                emptyView: EmptyStateView(
                  icon: Icons.search_off,
                  title: 'No Experiences Found',
                  description: _searchQuery.isNotEmpty
                      ? 'No results for "$_searchQuery". Try searching for "Everest", "Annapurna", or "Pokhara".'
                      : 'No experiences match the selected criteria.',
                  actionLabel: 'Reset Search',
                  onActionPressed: () {
                    setState(() {
                      _selectedDifficulty = null;
                      _categoryId = null;
                      _regionId = null;
                      _sortBy = 'relevance';
                      _searchQuery = '';
                      _searchController.clear();
                      _showRecentSearches = false;
                    });
                  },
                ),
                data: (experiences) {
                  return ListView.separated(
                    key: const PageStorageKey<String>('search_results_list'),
                    padding: AppSpacing.screenPadding,
                    itemCount: experiences.length,
                    separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.lg16),
                    itemBuilder: (context, index) {
                      final exp = experiences[index];
                      return ExperienceCard(
                        width: double.infinity,
                        title: exp.title,
                        location: exp.locationName ?? 'Nepal',
                        rating: exp.ratingAvg,
                        reviewCount: exp.ratingCount,
                        priceText: AppFormatters.formatNpr(exp.pricePaisa),
                        imageUrl: exp.coverImageUrl,
                        categoryTag: exp.difficulty.name.toUpperCase(),
                        onTap: () => context.push('/experience/${exp.id}'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyChip(String value, String label) {
    final isSelected = (_selectedDifficulty == value) ||
        (value == 'all' && (_selectedDifficulty == null || _selectedDifficulty == 'all'));

    return FilterChipPill(
      label: label,
      isSelected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedDifficulty = selected ? value : null;
        });
      },
    );
  }
}
