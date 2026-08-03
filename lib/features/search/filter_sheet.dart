// RM-07 Filter & Sort Sheet
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/category.dart';
import '../../models/region.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

class FilterSheet extends ConsumerStatefulWidget {
  final String? initialDifficulty;
  final String? initialCategoryId;
  final String? initialRegionId;

  const FilterSheet({
    super.key,
    this.initialDifficulty,
    this.initialCategoryId,
    this.initialRegionId,
  });

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  String? _selectedDifficulty;
  String? _selectedCategoryId;
  String? _selectedRegionId;

  @override
  void initState() {
    super.initState();
    _selectedDifficulty = widget.initialDifficulty;
    _selectedCategoryId = widget.initialCategoryId;
    _selectedRegionId = widget.initialRegionId;
  }

  void _resetAll() {
    setState(() {
      _selectedDifficulty = null;
      _selectedCategoryId = null;
      _selectedRegionId = null;
    });
  }

  void _applyFilters() {
    Navigator.of(context).pop<Map<String, String?>>({
      'difficulty': _selectedDifficulty,
      'category_id': _selectedCategoryId,
      'region_id': _selectedRegionId,
    });
  }

  @override
  Widget build(BuildContext context) {
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
                    'Filter & Sort',
                    style: AppTypography.headingMedium.copyWith(color: AppColors.forest),
                  ),
                  TextButton(
                    onPressed: _resetAll,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(AppTouchTarget.minSize, AppTouchTarget.minSize),
                    ),
                    child: Text(
                      'Reset All',
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

              // 1. Difficulty Level
              Text(
                'Difficulty Level',
                style: AppTypography.headingMedium.copyWith(color: AppColors.ink),
              ),
              const SizedBox(height: AppSpacing.sm8),
              Wrap(
                spacing: AppSpacing.sm8,
                runSpacing: AppSpacing.sm8,
                children: [
                  _buildDifficultyChip('easy', 'Easy'),
                  _buildDifficultyChip('moderate', 'Moderate'),
                  _buildDifficultyChip('challenging', 'Challenging'),
                  _buildDifficultyChip('strenuous', 'Strenuous'),
                ],
              ),

              const SizedBox(height: AppSpacing.xxl24),

              // 2. Categories Section
              Text(
                'Category',
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

              // 3. Regions Section
              Text(
                'Region',
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
                label: 'Apply Filters',
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


