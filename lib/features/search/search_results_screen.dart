// PL-08 Search Results
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/experience_presentation.dart';
import '../../l10n/app_localizations.dart';
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
  final Set<String> _saving = {};
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

    if (result != null && mounted) {
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
    _searchDebounce?.cancel();
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

  Future<void> _toggleSaved(String id, bool isSaved) async {
    if (_saving.contains(id)) return;
    if (ref.read(supabaseClientProvider).auth.currentUser == null) {
      ref
          .read(deferredActionProvider.notifier)
          .setPending(
            DeferredAction(screenId: 'PL-09', entityId: id, action: 'save'),
          );
      context.push('/auth/required');
      return;
    }
    _saving.add(id);
    try {
      await ref.read(savedRepositoryProvider).toggleSave(id, isSaved);
      if (mounted) ref.invalidate(savedExperiencesProvider);
    } catch (_) {
      if (mounted) {
        AppToast.show(
          context,
          message: 'Could not update saved experience. Please try again.',
          variant: AppToastVariant.error,
        );
      }
    } finally {
      _saving.remove(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final experiencesAsync = ref.watch(experiencesProvider(_filters));
    final recentSearchesAsync = ref.watch(recentSearchesProvider);
    final savedIds =
        ref
            .watch(savedExperiencesProvider)
            .valueOrNull
            ?.map((exp) => exp.id)
            .toSet() ??
        <String>{};
    final taxonomyAsync = ref.watch(experienceTaxonomyProvider);
    final taxonomy = taxonomyAsync.valueOrNull;
    final familySlug = _familySlug ?? taxonomy?.familyFor(_categoryId)?.slug;
    final familyLabel = _familyLabelFor(familySlug, taxonomy);
    final category = taxonomy?.categoryFor(_categoryId);
    final options =
        taxonomy?.categoriesById.values
            .where((item) => taxonomy.familyFor(item.id)?.slug == familySlug)
            .toList() ??
        [];
    options.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final hasActiveFilters = _filters.entries.any(
      (entry) => entry.key != 'sort_by' || entry.value != 'relevance',
    );
    final contextLabel = [
      if (familyLabel != null) familyLabel,
      if (category != null) category.nameEn,
    ].join(' • ');

    return Scaffold(
      body: PlanEBackground(
        safeArea: false,
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            key: const PageStorageKey('category-results-scroll'),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _ResultsHeader(
                  contextLabel: contextLabel,
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: _onSearchChanged,
                  onSubmitted: _submitSearch,
                  onClear: () {
                    _searchController.clear();
                    _submitSearch('');
                  },
                  onFilter: _openFilterSheet,
                  onBack: () =>
                      context.canPop() ? context.pop() : context.go('/explore'),
                ),
              ),
              if (familySlug != null)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 56,
                    child: taxonomyAsync.when(
                      loading: () =>
                          const Center(child: LinearProgressIndicator()),
                      error: (error, stack) => TextButton(
                        onPressed: () =>
                            ref.invalidate(experienceTaxonomyProvider),
                        child: const Text('Retry activity options'),
                      ),
                      data: (_) => options.isEmpty
                          ? const Center(
                              child: Text('No activity options available yet'),
                            )
                          : ListView.separated(
                              key: ValueKey(familySlug),
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              itemCount: options.length,
                              separatorBuilder: (_, index) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (_, index) {
                                final option = options[index];
                                return FilterChipPill(
                                  label: option.nameEn,
                                  isSelected: option.id == _categoryId,
                                  onSelected: (selected) => setState(() {
                                    _familySlug = familySlug;
                                    _categoryId = selected ? option.id : null;
                                    _filters = _computeFilterMap();
                                  }),
                                );
                              },
                            ),
                    ),
                  ),
                ),
              if (_showRecentSearches)
                SliverToBoxAdapter(
                  child: AsyncValueView<List<String>>(
                    value: recentSearchesAsync,
                    loading: () => const SizedBox.shrink(),
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
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    children: [
                      Text(
                        l10n.searchResults,
                        style: AppTypography.headingMedium,
                      ),
                      if (hasActiveFilters)
                        TextButton(
                          onPressed: _clearAllFilters,
                          style: TextButton.styleFrom(
                            minimumSize: const Size(48, 48),
                          ),
                          child: const Text('Clear All'),
                        ),
                    ],
                  ),
                ),
              ),
              experiencesAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (error, stack) => SliverToBoxAdapter(
                  child: ErrorStateView(
                    message: error.toString(),
                    onRetry: () =>
                        ref.invalidate(experiencesProvider(_filters)),
                  ),
                ),
                data: (experiences) => experiences.isEmpty
                    ? SliverToBoxAdapter(
                        child: EmptyStateView(
                          icon: Icons.search_off,
                          title: l10n.noExperiencesFound,
                          description:
                              'No experiences match the selected criteria.',
                          actionLabel: l10n.resetSearch,
                          onActionPressed: _clearAllFilters,
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList.builder(
                          itemCount: experiences.length,
                          itemBuilder: (context, index) {
                            final exp = experiences[index];
                            final presentation = ExperiencePresentation.from(
                              exp,
                              taxonomy,
                            );
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: ExperienceCard(
                                width: double.infinity,
                                title: exp.title,
                                location: exp.locationName ?? 'Nepal',
                                rating: exp.ratingAvg,
                                reviewCount: exp.ratingCount,
                                priceText: AppFormatters.formatNpr(
                                  exp.pricePaisa,
                                ),
                                imageUrl: exp.coverImageUrl,
                                familyLabel: familySlug == null
                                    ? presentation.familyLabel
                                    : presentation.typeLabel,
                                isSaved: savedIds.contains(exp.id),
                                onBookmarkTap: () => _toggleSaved(
                                  exp.id,
                                  savedIds.contains(exp.id),
                                ),
                                typeLabel: presentation.typeLabel,
                                detailText: presentation.detailText,
                                onTap: () =>
                                    context.push('/experience/${exp.id}'),
                              ),
                            );
                          },
                        ),
                      ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 84 + MediaQuery.paddingOf(context).bottom,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultsHeader extends SliverPersistentHeaderDelegate {
  final String contextLabel;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged, onSubmitted;
  final VoidCallback onClear, onFilter, onBack;

  _ResultsHeader({
    required this.contextLabel,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.onFilter,
    required this.onBack,
  });

  @override
  double get minExtent => contextLabel.isEmpty ? 64 : 92;
  @override
  double get maxExtent => minExtent + 60;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final t = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    return Material(
      color: AppColors.ivory,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            top: 8,
            left: 8,
            child: IconButton(
              tooltip: 'Back to Explore',
              onPressed: onBack,
              icon: const Icon(Icons.chevron_left, color: AppColors.forest),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              tooltip: 'Filter',
              onPressed: onFilter,
              icon: const Icon(Icons.tune, color: AppColors.forest),
            ),
          ),
          Positioned(
            top: 18 - 60 * t,
            left: 64,
            right: 64,
            child: ExcludeSemantics(
              excluding: t > 0.5,
              child: Opacity(
                opacity: 1 - t,
                child: const PlanELogo(fontSize: 24),
              ),
            ),
          ),
          Positioned(
            top: 68 - 60 * t,
            left: 16 + 40 * t,
            right: 16 + 40 * t,
            height: 48,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              style: const TextStyle(fontSize: 14, color: AppColors.ink),
              decoration: InputDecoration(
                hintText: 'Search experiences, places or activities',
                filled: true,
                fillColor: AppColors.white,
                prefixIcon: const Icon(Icons.search, color: AppColors.forest),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: onClear,
                        icon: const Icon(Icons.close),
                      ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
          if (contextLabel.isNotEmpty)
            Positioned(
              bottom: 4,
              left: 16 + 40 * t,
              right: 16,
              child: Text(
                contextLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(color: AppColors.forest),
              ),
            ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ResultsHeader oldDelegate) => true;
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
