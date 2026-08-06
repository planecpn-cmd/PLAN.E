// RM-07 Filter & Sort Sheet
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../models/category.dart';
import '../../models/region.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

class FilterSheet extends ConsumerStatefulWidget {
  final String? initialDifficulty;
  final String? initialCategoryId;
  final String? initialRegionId;
  final int? initialMinPricePaisa;
  final int? initialMaxPricePaisa;
  final String? initialSortBy;

  const FilterSheet({
    super.key,
    this.initialDifficulty,
    this.initialCategoryId,
    this.initialRegionId,
    this.initialMinPricePaisa,
    this.initialMaxPricePaisa,
    this.initialSortBy,
  });

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  String? _selectedDifficulty;
  String? _selectedCategoryId;
  String? _selectedRegionId;
  String? _selectedSortBy;
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;

  @override
  void initState() {
    super.initState();
    _selectedDifficulty = widget.initialDifficulty;
    _selectedCategoryId = widget.initialCategoryId;
    _selectedRegionId = widget.initialRegionId;
    _selectedSortBy = widget.initialSortBy ?? 'relevance';
    _minPriceController = TextEditingController(
      text: widget.initialMinPricePaisa != null
          ? (widget.initialMinPricePaisa! ~/ 100).toString()
          : '',
    );
    _maxPriceController = TextEditingController(
      text: widget.initialMaxPricePaisa != null
          ? (widget.initialMaxPricePaisa! ~/ 100).toString()
          : '',
    );
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _resetAll() {
    setState(() {
      _selectedDifficulty = null;
      _selectedCategoryId = null;
      _selectedRegionId = null;
      _selectedSortBy = 'relevance';
      _minPriceController.clear();
      _maxPriceController.clear();
    });
  }

  void _applyFilters() {
    final minNpr = int.tryParse(_minPriceController.text.trim());
    final maxNpr = int.tryParse(_maxPriceController.text.trim());
    final minPaisa = minNpr != null ? minNpr * 100 : null;
    final maxPaisa = maxNpr != null ? maxNpr * 100 : null;

    Navigator.of(context).pop<Map<String, String?>>({
      'difficulty': _selectedDifficulty,
      'category_id': _selectedCategoryId,
      'region_id': _selectedRegionId,
      'min_price': minPaisa?.toString(),
      'max_price': maxPaisa?.toString(),
      'sort_by': _selectedSortBy,
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(categoriesProvider);
    final regionsAsync = ref.watch(regionsProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.ivory,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg24)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg16,
        AppSpacing.md12,
        AppSpacing.lg16,
        AppSpacing.xxl24,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bottom Sheet Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.border,
                    borderRadius: AppRadii.borderPill,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md12),

              // Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.filterAndSort,
                    style: AppTypography.headingMedium.copyWith(color: AppColors.forest),
                  ),
                  TextButton(
                    onPressed: _resetAll,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(AppTouchTarget.minSize, AppTouchTarget.minSize),
                    ),
                    child: Text(
                      l10n.resetAll,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const Divider(color: AppColors.borderSubtle),
              const SizedBox(height: AppSpacing.md12),

              // 1. Sort By Options
              Text(
                l10n.sortBy,
                style: AppTypography.headingMedium.copyWith(color: AppColors.ink),
              ),
              const SizedBox(height: AppSpacing.sm8),
              Wrap(
                spacing: AppSpacing.sm8,
                runSpacing: AppSpacing.sm8,
                children: [
                  _buildSortChip('relevance', 'Relevance'),
                  _buildSortChip('rating', 'Highest Rated'),
                  _buildSortChip('popular', 'Most Popular'),
                  _buildSortChip('price_asc', 'Price: Low to High'),
                  _buildSortChip('price_desc', 'Price: High to Low'),
                  _buildSortChip('duration', 'Duration: Shortest'),
                  _buildSortChip('newest', 'Newest'),
                ],
              ),

              const SizedBox(height: AppSpacing.xxl24),

              // 2. Difficulty Level
              Text(
                l10n.difficultyLevel,
                style: AppTypography.headingMedium.copyWith(color: AppColors.ink),
              ),
              const SizedBox(height: AppSpacing.sm8),
              Wrap(
                spacing: AppSpacing.sm8,
                runSpacing: AppSpacing.sm8,
                children: [
                  _buildDifficultyChip('easy', l10n.easy),
                  _buildDifficultyChip('moderate', l10n.moderate),
                  _buildDifficultyChip('challenging', l10n.challenging),
                  _buildDifficultyChip('strenuous', l10n.strenuous),
                ],
              ),

              const SizedBox(height: AppSpacing.xxl24),

              // 3. Price Range (NPR)
              Text(
                'Price Range (NPR)',
                style: AppTypography.headingMedium.copyWith(color: AppColors.ink),
              ),
              const SizedBox(height: AppSpacing.sm8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minPriceController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 14, color: AppColors.ink),
                      decoration: InputDecoration(
                        labelText: 'Min Price (Rs.)',
                        labelStyle: const TextStyle(color: AppColors.disabledText),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadii.md16),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md12),
                  Expanded(
                    child: TextField(
                      controller: _maxPriceController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 14, color: AppColors.ink),
                      decoration: InputDecoration(
                        labelText: 'Max Price (Rs.)',
                        labelStyle: const TextStyle(color: AppColors.disabledText),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadii.md16),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xxl24),

              // 4. Categories Section
              Text(
                l10n.category,
                style: AppTypography.headingMedium.copyWith(color: AppColors.ink),
              ),
              const SizedBox(height: AppSpacing.sm8),

              AsyncValueView<List<Category>>(
                value: categoriesAsync,
                onRetry: () => ref.refresh(categoriesProvider),
                isEmpty: (categories) => categories.isEmpty,
                emptyView: Text(
                  'No categories loaded',
                  style: AppTypography.caption.copyWith(color: AppColors.disabledText),
                ),
                data: (categories) {
                  return Wrap(
                    spacing: AppSpacing.sm8,
                    runSpacing: AppSpacing.sm8,
                    children: categories.map((cat) {
                      final isSelected = _selectedCategoryId == cat.id;
                      return FilterChipPill(
                        label: cat.nameEn,
                        isSelected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategoryId = selected ? cat.id : null;
                          });
                        },
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.xxl24),

              // 5. Regions Section
              Text(
                l10n.region,
                style: AppTypography.headingMedium.copyWith(color: AppColors.ink),
              ),
              const SizedBox(height: AppSpacing.sm8),

              AsyncValueView<List<Region>>(
                value: regionsAsync,
                onRetry: () => ref.refresh(regionsProvider),
                isEmpty: (regions) => regions.isEmpty,
                emptyView: Text(
                  'No regions loaded',
                  style: AppTypography.caption.copyWith(color: AppColors.disabledText),
                ),
                data: (regions) {
                  return Wrap(
                    spacing: AppSpacing.sm8,
                    runSpacing: AppSpacing.sm8,
                    children: regions.map((reg) {
                      final isSelected = _selectedRegionId == reg.id;
                      return FilterChipPill(
                        label: reg.nameEn,
                        isSelected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedRegionId = selected ? reg.id : null;
                          });
                        },
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.xxxl32),

              // Bottom Action Button
              AppButton(
                label: l10n.applyFilters,
                onPressed: _applyFilters,
                variant: AppButtonVariant.primary,
                isFullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortChip(String value, String label) {
    final isSelected = _selectedSortBy == value;
    return FilterChipPill(
      label: label,
      isSelected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedSortBy = selected ? value : 'relevance';
        });
      },
    );
  }

  Widget _buildDifficultyChip(String value, String label) {
    final isSelected = _selectedDifficulty == value;
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
