// PL-12 Saved Experiences
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/experience_presentation.dart';
import '../../l10n/app_localizations.dart';
import '../../models/experience.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final taxonomy = ref.watch(experienceTaxonomyProvider).valueOrNull;
    final client = ref.watch(supabaseClientProvider);
    final user = client.auth.currentUser;

    if (user == null) {
      return Scaffold(
        body: PlanEBackground(
          child: EmptyStateView(
            icon: Icons.bookmark_border_rounded,
            title: l10n.noSavedExperiences,
            actionLabel: l10n.login,
            onActionPressed: () => context.push('/auth/login'),
          ),
        ),
      );
    }

    final savedExperiencesAsync = ref.watch(savedExperiencesProvider);

    return Scaffold(
      body: PlanEBackground(
        safeArea: false,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OfflineBanner(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  l10n.savedExperiences,
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.forest,
                  ),
                ),
              ),
              Expanded(
                child: AsyncValueView<List<Experience>>(
                  value: savedExperiencesAsync,
                  onRetry: () => ref.refresh(savedExperiencesProvider),
                  isEmpty: (data) => data.isEmpty,
                  emptyView: EmptyStateView(
                    icon: Icons.bookmark_border_rounded,
                    title: l10n.noSavedExperiences,
                    description:
                        'Save your favorite Nepal experiences to view them anytime offline.',
                    actionLabel: l10n.exploreExperiences,
                    onActionPressed: () => context.go('/explore'),
                  ),
                  data: (experiences) {
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: .68,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: experiences.length,
                      itemBuilder: (context, index) {
                        final exp = experiences[index];
                        final presentation = ExperiencePresentation.from(
                          exp,
                          taxonomy,
                        );
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.black.withValues(alpha: .06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      context.push('/experience/${exp.id}'),
                                  child: PlanEPhoto(
                                    imageUrl: exp.coverImageUrl,
                                    radius: 20,
                                    overlay: Align(
                                      alignment: Alignment.topRight,
                                      child: GestureDetector(
                                        onTap: () async {
                                          final savedRepo = ref.read(
                                            savedRepositoryProvider,
                                          );
                                          await savedRepo.toggleSave(
                                            exp.id,
                                            true,
                                          );
                                          ref.invalidate(
                                            savedExperiencesProvider,
                                          );
                                          if (context.mounted) {
                                            AppToast.show(
                                              context,
                                              message: l10n.removedFromSaved,
                                              variant: AppToastVariant.info,
                                            );
                                          }
                                        },
                                        child: Container(
                                          width: 36,
                                          height: 36,
                                          margin: const EdgeInsets.all(8),
                                          decoration: const BoxDecoration(
                                            color: AppColors.forest,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.favorite,
                                            color: AppColors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  10,
                                  8,
                                  10,
                                  10,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (presentation.familyLabel != null) ...[
                                      Text(
                                        presentation.familyLabel!.toUpperCase(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.gold,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: .5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                    ],
                                    Text(
                                      exp.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'serif',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.forest,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      [
                                        if (presentation.typeLabel != null)
                                          presentation.typeLabel!,
                                        presentation.detailText,
                                      ].join(' • '),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.disabledText,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: AppColors.gold,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${exp.ratingAvg}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.disabledText,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          AppFormatters.formatNpr(
                                            exp.pricePaisa,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.forest,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
}
