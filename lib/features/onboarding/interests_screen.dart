// PL-05 Select Interests
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../models/category.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/filter_chip_pill.dart';

class InterestsScreen extends ConsumerWidget {
  const InterestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(categoriesProvider);
    final guestState = ref.watch(guestProvider);
    final selectedIds = guestState.selectedInterests;
    final bool canContinue = selectedIds.length >= 3;

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        backgroundColor: AppColors.ivory,
        elevation: 0,
        title: Text(
          l10n.selectInterests,
          style: AppTypography.headingMedium.copyWith(color: AppColors.forest),
        ),
        actions: [
          ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: AppTouchTarget.minSize,
              minHeight: AppTouchTarget.minSize,
            ),
            child: TextButton(
              onPressed: () => context.go('/home'),
              child: Text(
                'Skip',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.selectInterests,
                style: AppTypography.headingLarge.copyWith(color: AppColors.deep),
              ),
              const SizedBox(height: AppSpacing.sm8),
              Text(
                l10n.selectMin3,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
              ),
              const SizedBox(height: AppSpacing.md12),

              // Selection Counter Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md12,
                  vertical: AppSpacing.xs4,
                ),
                decoration: BoxDecoration(
                  color: canContinue ? AppColors.successContainer : AppColors.sage,
                  borderRadius: AppRadii.borderPill,
                ),
                child: Text(
                  '${selectedIds.length} / 3 selected',
                  style: AppTypography.caption.copyWith(
                    color: canContinue ? AppColors.success : AppColors.forest,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg16),

              // Structural AsyncValueView over categoriesProvider
              Expanded(
                child: AsyncValueView<List<Category>>(
                  value: categoriesAsync,
                  isEmpty: (data) => data.isEmpty,
                  onRetry: () => ref.refresh(categoriesProvider),
                  data: (categories) {
                    return SingleChildScrollView(
                      child: Wrap(
                        spacing: AppSpacing.md12,
                        runSpacing: AppSpacing.md12,
                        children: categories.map((category) {
                          final isSelected = selectedIds.contains(category.id);
                          return ConstrainedBox(
                            constraints: const BoxConstraints(
                              minHeight: AppTouchTarget.minSize,
                            ),
                            child: FilterChipPill(
                              label: category.nameEn,
                              isSelected: isSelected,
                              icon: _getCategoryIcon(category.slug),
                              onSelected: (_) {
                                ref.read(guestProvider.notifier).toggleInterest(category.id);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: AppSpacing.lg16),

              // Action button - enabled when min 3 selected
              AppButton(
                label: l10n.continueText,
                onPressed: canContinue
                    ? () {
                        context.go('/home');
                      }
                    : null,
                variant: canContinue ? AppButtonVariant.primary : AppButtonVariant.disabled,
                isFullWidth: true,
                minHeight: AppTouchTarget.minSize,
              ),
              const SizedBox(height: AppSpacing.lg16),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String slug) {
    switch (slug) {
      case 'trekking':
        return Icons.hiking;
      case 'culture':
        return Icons.museum;
      case 'wildlife':
        return Icons.pets;
      case 'homestay':
        return Icons.home_work;
      case 'food':
        return Icons.restaurant;
      case 'adventure':
        return Icons.paragliding;
      default:
        return Icons.category;
    }
  }
}
