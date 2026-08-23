// PL-05 Select Interests
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/onboarding_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../models/category.dart';
import '../../models/experience_family.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

Map<ExperienceFamily, List<Category>> groupInterestsByFamily(
  ExperienceTaxonomy taxonomy,
) {
  final categories = taxonomy.categoriesById.values.toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  final families = taxonomy.familiesById.values.toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return {
    for (final family in families)
      family: categories
          .where(
            (category) => taxonomy.familyFor(category.id)?.slug == family.slug,
          )
          .toList(),
  }..removeWhere((_, categories) => categories.isEmpty);
}

class InterestsScreen extends ConsumerWidget {
  const InterestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final taxonomyAsync = ref.watch(experienceTaxonomyProvider);
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
                  onPressed: () async {
                    await OnboardingPreferences.markCompleted();
                    if (context.mounted) context.go('/home');
                  },
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

            // Group specific interests beneath the six experience families.
            Expanded(
              child: AsyncValueView<ExperienceTaxonomy>(
                value: taxonomyAsync,
                isEmpty: (data) => data.categoriesById.isEmpty,
                onRetry: () => ref.refresh(experienceTaxonomyProvider),
                error: (_, __) => ErrorStateView(
                  title: 'Unable to load interests',
                  message: 'Check your connection and try again.',
                  onRetry: () => ref.refresh(experienceTaxonomyProvider),
                ),
                data: (taxonomy) {
                  final groupedInterests = groupInterestsByFamily(taxonomy);

                  return ListView(
                    padding: EdgeInsets.zero,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      for (final entry in groupedInterests.entries) ...[
                        Text(
                          entry.key.nameEn,
                          style: AppTypography.headingMedium.copyWith(
                            color: AppColors.forest,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.key.description,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.disabledText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final category in entry.value)
                              _buildInterestChip(
                                ref,
                                category,
                                selectedIds.contains(category.id),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ],
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
              onPressed: canContinue
                  ? () async {
                      await OnboardingPreferences.markCompleted();
                      if (context.mounted) context.go('/home');
                    }
                  : null,
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

  Widget _buildInterestChip(WidgetRef ref, Category category, bool isSelected) {
    return FilterChip(
      selected: isSelected,
      showCheckmark: true,
      avatar: Icon(
        _getCategoryIcon(category.slug),
        size: 20,
        color: isSelected ? AppColors.white : AppColors.forest,
      ),
      label: Text(category.nameEn),
      labelStyle: AppTypography.bodyMedium.copyWith(
        color: isSelected ? AppColors.white : AppColors.ink,
        fontWeight: FontWeight.w600,
      ),
      selectedColor: AppColors.forest,
      backgroundColor: AppColors.cardBackground.withValues(alpha: .72),
      checkmarkColor: AppColors.white,
      side: BorderSide(color: isSelected ? AppColors.gold : AppColors.border),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      onSelected: (_) {
        ref.read(guestProvider.notifier).toggleInterest(category.id);
      },
    );
  }

  IconData _getCategoryIcon(String slug) {
    switch (slug) {
      case 'trekking':
      case 'hiking':
        return Icons.hiking;
      case 'culture':
        return Icons.museum;
      case 'wildlife':
        return Icons.pets;
      case 'homestay':
      case 'village-stay':
        return Icons.home_work;
      case 'food':
      case 'food-experience':
        return Icons.restaurant;
      case 'adventure':
        return Icons.paragliding;
      case 'yoga':
      case 'meditation':
      case 'wellness':
      case 'wellness-retreat':
        return Icons.self_improvement;
      case 'craft-workshop':
      case 'creative-workshop':
        return Icons.palette_outlined;
      case 'meetup':
      case 'group-activity':
      case 'community-event':
        return Icons.groups_outlined;
      case 'volunteering':
      case 'volunteer-project':
      case 'skill-sharing':
        return Icons.volunteer_activism_outlined;
      case 'conservation-project':
        return Icons.eco_outlined;
      case 'day-trip':
      case 'guided-tour':
      case 'multi-day-tour':
      case 'travel-package':
        return Icons.route_outlined;
      default:
        return Icons.interests_outlined;
    }
  }
}
