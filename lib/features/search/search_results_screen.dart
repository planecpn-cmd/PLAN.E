// PL-08 Search Results
import 'dart:async';

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
  late TextEditingController _searchController;
  String? _selectedDifficulty;
  String? _categoryId;
  String? _regionId;
  String? _sortBy = 'relevance';
  String _searchQuery = '';
  bool _showRecentSearches = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.initialQuery ?? '';
    _searchController = TextEditingController(text: _searchQuery);
    _selectedDifficulty = widget.initialDifficulty;
    _categoryId = widget.initialCategoryId;
    _regionId = widget.initialRegionId;
    _sortBy = widget.initialSortBy ?? 'relevance';
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Map<String, String?> get _filterMap {
    return {
      if (_searchQuery.trim().isNotEmpty) 'search_query': _searchQuery.trim(),
      if (_selectedDifficulty != null && _selectedDifficulty != 'all')
        'difficulty': _selectedDifficulty,
      if (_categoryId != null && _categoryId!.isNotEmpty)
        'category_id': _categoryId,
      if (_regionId != null && _regionId!.isNotEmpty) 'region_id': _regionId,
      if (_sortBy != null && _sortBy!.isNotEmpty) 'sort_by': _sortBy,
    };
  }

  void _submitSearch(String query) {
    _searchDebounce?.cancel();
    final trimmedQuery = query.trim();
    setState(() {
      _searchQuery = trimmedQuery;
      _showRecentSearches = false;
    });
    FocusScope.of(context).unfocus();
    if (trimmedQuery.isNotEmpty) {
      ref.read(recentSearchesRepositoryProvider).addSearchQuery(trimmedQuery);
      ref.invalidate(recentSearchesProvider);
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    setState(() {
      _showRecentSearches = value.trim().isEmpty;
    });
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = value.trim();
      });
    });
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
      body: PlanEBackground(
        safeArea: false,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Header Row with Back Button & Logo
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_left,
                        size: 32,
                        color: AppColors.forest,
                      ),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/home');
                        }
                      },
                    ),
                    const Expanded(child: PlanELogo(fontSize: 24)),
                    IconButton(
                      icon: const Icon(Icons.tune, color: AppColors.forest),
                      onPressed: _openFilterSheet,
                      tooltip: 'Filter',
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search,
                        size: 22,
                        color: AppColors.forest,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.ink,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Search trails, places, treks...',
                            hintStyle: TextStyle(
                              color: AppColors.disabledText,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                          ),
                          textInputAction: TextInputAction.search,
                          onTap: () {
                            setState(() {
                              _showRecentSearches = _searchController.text
                                  .trim()
                                  .isEmpty;
                            });
                          },
                          onSubmitted: _submitSearch,
                          onChanged: _onSearchChanged,
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _showRecentSearches = true;
                            });
                          },
                          child: const Icon(
                            Icons.close,
                            size: 20,
                            color: AppColors.disabledText,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Recent Searches if active
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
                        horizontal: 16,
                        vertical: 6,
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
                          const SizedBox(height: 4),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: recentList.map((term) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ActionChip(
                                    label: Text(
                                      term,
                                      style: AppTypography.caption,
                                    ),
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
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    _buildDifficultyChip('all', l10n.allLevels),
                    const SizedBox(width: 8),
                    _buildDifficultyChip('easy', l10n.easy),
                    const SizedBox(width: 8),
                    _buildDifficultyChip('moderate', l10n.moderate),
                    const SizedBox(width: 8),
                    _buildDifficultyChip('challenging', l10n.challenging),
                    const SizedBox(width: 8),
                    _buildDifficultyChip('strenuous', l10n.strenuous),
                  ],
                ),
              ),

              // Results Count Banner
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.searchResults,
                      style: AppTypography.headingMedium.copyWith(
                        color: AppColors.ink,
                      ),
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
                          'Clear All',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // Async Experience Results View
              Expanded(
                child: AsyncValueView<List<Experience>>(
                  value: experiencesAsync,
                  onRetry: () => ref.refresh(experiencesProvider(_filterMap)),
                  isEmpty: (list) => list.isEmpty,
                  emptyView: EmptyStateView(
                    icon: Icons.search_off,
                    title: l10n.noExperiencesFound,
                    description: _searchQuery.isNotEmpty
                        ? 'No results for "$_searchQuery". Try searching for "Everest", "Annapurna", or "Pokhara".'
                        : 'No experiences match the selected criteria.',
                    actionLabel: l10n.resetSearch,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: experiences.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 14),
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
      ),
    );
  }

  Widget _buildDifficultyChip(String value, String label) {
    final isSelected =
        (_selectedDifficulty == value) ||
        (value == 'all' &&
            (_selectedDifficulty == null || _selectedDifficulty == 'all'));

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
