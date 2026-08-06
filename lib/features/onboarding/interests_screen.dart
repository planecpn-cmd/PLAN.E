// PL-05 Select Interests
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../models/category.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

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
      body: PlanEBackground(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.chevron_left,
                    size: 32,
                    color: AppColors.forest,
                  ),
                  onPressed: () => context.go('/onboarding/1'),
                ),
                const Expanded(child: PlanELogo(fontSize: 26)),
                TextButton(
                  onPressed: () => context.go('/home'),
                  child: Text(
                    'Skip',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'What are\nyou into?',
              style:
                  Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontFamily: 'serif',
                    color: AppColors.forest,
                    fontWeight: FontWeight.w600,
                  ) ??
                  AppTypography.headingLarge.copyWith(color: AppColors.deep),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.selectMin3,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
            ),
            const SizedBox(height: 20),

            // Structural AsyncValueView over categoriesProvider
            Expanded(
              child: AsyncValueView<List<Category>>(
                value: categoriesAsync,
                isEmpty: (data) => data.isEmpty,
                onRetry: () => ref.refresh(categoriesProvider),
                error: (_, __) => ErrorStateView(
                  title: 'Unable to load interests',
                  message: 'Check your connection and try again.',
                  onRetry: () => ref.refresh(categoriesProvider),
                ),
                data: (categories) {
                  return GridView.builder(
                    padding: EdgeInsets.zero,
                    physics: const BouncingScrollPhysics(),
                    itemCount: categories.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 1.9,
                        ),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = selectedIds.contains(category.id);
                      return GestureDetector(
                        onTap: () {
                          ref
                              .read(guestProvider.notifier)
                              .toggleInterest(category.id);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.forest
                                : AppColors.cardBackground.withValues(
                                    alpha: .6,
                                  ),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.gold
                                  : AppColors.border,
                              width: 1.3,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getCategoryIcon(category.slug),
                                size: 28,
                                color: isSelected
                                    ? AppColors.white
                                    : AppColors.forest,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  category.nameEn,
                                  style: TextStyle(
                                    fontFamily: 'serif',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? AppColors.white
                                        : AppColors.ink,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    color: AppColors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 15,
                                    color: AppColors.forest,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 12),
            Center(
              child: Text(
                '${selectedIds.length} / 3 selected',
                style: AppTypography.caption.copyWith(
                  color: canContinue ? AppColors.success : AppColors.forest,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: l10n.continueText,
              onPressed: canContinue ? () => context.go('/home') : null,
              variant: canContinue
                  ? AppButtonVariant.primary
                  : AppButtonVariant.disabled,
              isFullWidth: true,
              minHeight: AppTouchTarget.minSize,
            ),
          ],
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
