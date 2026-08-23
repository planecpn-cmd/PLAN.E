// PL-08 Search Results
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/experience_presentation.dart';
import '../../l10n/app_localizations.dart';
import '../../models/experience.dart';
import '../../models/experience_family.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'filter_sheet.dart';

class SearchResultsScreen extends ConsumerStatefulWidget {
  final String? initialQuery;
  final String? initialCategoryId;
  final String? initialFamilySlug;
  final String? initialRegionId;
  final String? initialDifficulty;
  final int? initialMaxDurationHours;
  final String? initialSortBy;

  const SearchResultsScreen({
    super.key,
    this.initialQuery,
    this.initialCategoryId,
    this.initialFamilySlug,
    this.initialRegionId,
    this.initialDifficulty,
    this.initialMaxDurationHours,
    this.initialSortBy,
  });

  @override
  ConsumerState<SearchResultsScreen> createState() =>
      _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  String? _selectedDifficulty;
  String? _categoryId;
  String? _familySlug;
  String? _regionId;
  int? _minPricePaisa;
  int? _maxPricePaisa;
  int? _maxDurationHours;
  String? _sortBy = 'relevance';
  String _searchQuery = '';
  bool _showRecentSearches = false;
  Timer? _searchDebounce;
  // Stored, not recomputed inline in build() — experiencesProvider is a
  // .family provider keyed on this map's `==`, and a plain Dart Map has
  // identity equality. A getter that rebuilds a fresh Map every build() call
  // (including rebuilds triggered by totally unrelated state) made every
  // watch() key a "new" provider, restarting the fetch from loading each
  // time and never letting a completed one actually render.
  late Map<String, String?> _filters;

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.initialQuery ?? '';
    _searchController = TextEditingController(text: _searchQuery);
    _selectedDifficulty = widget.initialDifficulty;
    _categoryId = widget.initialCategoryId;
    _familySlug = widget.initialFamilySlug;
    _regionId = widget.initialRegionId;
    _sortBy = widget.initialSortBy ?? 'relevance';
    _maxDurationHours = widget.initialMaxDurationHours;
    _searchFocusNode = FocusNode();
    _searchFocusNode.addListener(_onFocusChange);
    _filters = _computeFilterMap();
  }

  void _onFocusChange() {
    if (_searchFocusNode.hasFocus) {
      setState(() {
        _showRecentSearches = true;
      });
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchFocusNode.removeListener(_onFocusChange);
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Map<String, String?> _computeFilterMap() {
    return {
      if (_searchQuery.trim().isNotEmpty) 'search_query': _searchQuery.trim(),
      if (_selectedDifficulty != null && _selectedDifficulty != 'all')
        'difficulty': _selectedDifficulty,
      if (_categoryId != null && _categoryId!.isNotEmpty)
        'category_id': _categoryId,
      if (_familySlug != null && _familySlug!.isNotEmpty) 'family': _familySlug,
      if (_regionId != null && _regionId!.isNotEmpty) 'region_id': _regionId,
      if (_minPricePaisa != null) 'min_price': _minPricePaisa.toString(),
      if (_maxPricePaisa != null) 'max_price': _maxPricePaisa.toString(),
      if (_maxDurationHours != null)
        'max_duration_hours': _maxDurationHours.toString(),
      if (_sortBy != null && _sortBy!.isNotEmpty) 'sort_by': _sortBy,
    };
  }

  void _submitSearch(String query) {
    _searchDebounce?.cancel();
    final trimmedQuery = query.trim();
    setState(() {
      _searchQuery = trimmedQuery;
      _showRecentSearches = false;
      _filters = _computeFilterMap();
    });
    _searchFocusNode.unfocus();
    if (trimmedQuery.isNotEmpty) {
      ref.read(recentSearchesRepositoryProvider).addSearchQuery(trimmedQuery);
      ref.invalidate(recentSearchesProvider);
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    setState(() {
      _showRecentSearches = _searchFocusNode.hasFocus || value.trim().isEmpty;
    });
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = value.trim();
        _filters = _computeFilterMap();
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
        initialFamilySlug: _familySlug,
        initialRegionId: _regionId,
        initialMinPricePaisa: _minPricePaisa,
        initialMaxPricePaisa: _maxPricePaisa,
        initialMaxDurationHours: _maxDurationHours,
        initialSortBy: _sortBy,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedDifficulty = result['difficulty'];
        _categoryId = result['category_id'];
        _familySlug = result['family'];
        _regionId = result['region_id'];
        _minPricePaisa = result['min_price'] != null
            ? int.tryParse(result['min_price']!)
            : null;
        _maxPricePaisa = result['max_price'] != null
            ? int.tryParse(result['max_price']!)
            : null;
        _maxDurationHours = result['max_duration_hours'] != null
            ? int.tryParse(result['max_duration_hours']!)
            : null;
        _sortBy = result['sort_by'] ?? 'relevance';
        _filters = _computeFilterMap();
      });
    }
  }

  void _clearAllFilters() {
    setState(() {
      _selectedDifficulty = null;
      _categoryId = null;
      _familySlug = null;
      _regionId = null;
      _minPricePaisa = null;
      _maxPricePaisa = null;
      _maxDurationHours = null;
      _sortBy = 'relevance';
      _searchQuery = '';
      _searchController.clear();
      _showRecentSearches = false;
      _filters = _computeFilterMap();
    });
    _searchFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final experiencesAsync = ref.watch(experiencesProvider(_filters));
    final recentSearchesAsync = ref.watch(recentSearchesProvider);
    final taxonomy = ref.watch(experienceTaxonomyProvider).valueOrNull;
    final activeFamilyLabel = _familyLabelFor(_familySlug, taxonomy);

    final bool hasActiveFilters =
        _categoryId != null ||
        _regionId != null ||
        _selectedDifficulty != null ||
        _familySlug != null ||
        _minPricePaisa != null ||
        _maxPricePaisa != null ||
        _maxDurationHours != null ||
        (_sortBy != null && _sortBy != 'relevance') ||
        _searchQuery.isNotEmpty;

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
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.tune, color: AppColors.forest),
                          if (_familySlug != null ||
                              _categoryId != null ||
                              _regionId != null ||
                              _minPricePaisa != null ||
                              _maxPricePaisa != null ||
                              _maxDurationHours != null ||
                              _selectedDifficulty != null ||
                              (_sortBy != null && _sortBy != 'relevance'))
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.gold,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
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
                    border: Border.all(
                      color: _searchFocusNode.hasFocus
                          ? AppColors.forest
                          : AppColors.border,
                      width: _searchFocusNode.hasFocus ? 1.5 : 1.0,
                    ),
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
                          focusNode: _searchFocusNode,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.ink,
                          ),
                          decoration: const InputDecoration(
                            hintText:
                                'Search experiences, places or activities',
                            hintStyle: TextStyle(
                              color: AppColors.disabledText,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          textInputAction: TextInputAction.search,
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

              // Recent Searches view when focused or empty
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
                        vertical: 8,
                      ),
                      color: AppColors.sage.withValues(alpha: 0.25),
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
                          const SizedBox(height: 6),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: recentList.map((term) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: InputChip(
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
                                    onDeleted: () async {
                                      await ref
                                          .read(
                                            recentSearchesRepositoryProvider,
                                          )
                                          .removeSearchQuery(term);
                                      ref.invalidate(recentSearchesProvider);
                                    },
                                    deleteIcon: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: AppColors.disabledText,
                                    ),
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

              if (activeFamilyLabel != null ||
                  familySupportsDifficulty(_familySlug) ||
                  _selectedDifficulty != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (activeFamilyLabel != null)
                        FilterChipPill(
                          label: activeFamilyLabel,
                          isSelected: true,
                          onSelected: (_) {
                            setState(() {
                              _familySlug = null;
                              _categoryId = null;
                              _selectedDifficulty = null;
                              _filters = _computeFilterMap();
                            });
                          },
                        ),
                      if (familySupportsDifficulty(_familySlug) ||
                          _selectedDifficulty != null) ...[
                        _buildDifficultyChip('all', l10n.allLevels),
                        _buildDifficultyChip('easy', l10n.easy),
                        _buildDifficultyChip('moderate', l10n.moderate),
                        _buildDifficultyChip('challenging', l10n.challenging),
                        _buildDifficultyChip('strenuous', l10n.strenuous),
                      ],
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
                    if (hasActiveFilters)
                      GestureDetector(
                        onTap: _clearAllFilters,
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
                  onRetry: () => ref.refresh(experiencesProvider(_filters)),
                  isEmpty: (list) => list.isEmpty,
                  emptyView: EmptyStateView(
                    icon: Icons.search_off,
                    title: l10n.noExperiencesFound,
                    description: _searchQuery.isNotEmpty
                        ? 'No results for "$_searchQuery". Try pottery, yoga, food, trekking, or volunteering.'
                        : 'No experiences match the selected criteria.',
                    actionLabel: l10n.resetSearch,
                    onActionPressed: _clearAllFilters,
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
                        final presentation = ExperiencePresentation.from(
                          exp,
                          taxonomy,
                        );
                        return ExperienceCard(
                          width: double.infinity,
                          title: exp.title,
                          location: exp.locationName ?? 'Nepal',
                          rating: exp.ratingAvg,
                          reviewCount: exp.ratingCount,
                          priceText: AppFormatters.formatNpr(exp.pricePaisa),
                          imageUrl: exp.coverImageUrl,
                          familyLabel: presentation.familyLabel,
                          typeLabel: presentation.typeLabel,
                          detailText: presentation.detailText,
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
          _filters = _computeFilterMap();
        });
      },
    );
  }
}

String? _familyLabelFor(String? slug, ExperienceTaxonomy? taxonomy) {
  if (slug == null) return null;
  final configured = taxonomy?.familiesBySlug[slug];
  if (configured != null) return configured.nameEn;
  for (final family in defaultExperienceFamilies) {
    if (family.slug == slug) return family.nameEn;
  }
  return null;
}
