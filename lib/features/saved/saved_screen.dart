// PL-12 Saved Experiences
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../models/experience.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'saved_strings.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(supabaseClientProvider);
    final user = client.auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            SavedStrings.pageTitle,
            style: AppTypography.headingMedium,
          ),
          backgroundColor: AppColors.white,
          elevation: 0,
        ),
        body: EmptyStateView(
          icon: Icons.bookmark_border_rounded,
          title: SavedStrings.loginRequired,
          actionLabel: SavedStrings.loginButton,
          onActionPressed: () => context.push('/auth/login'),
        ),
      );
    }

    final savedExperiencesAsync = ref.watch(savedExperiencesProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text(
          SavedStrings.pageTitle,
          style: AppTypography.headingMedium,
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: AsyncValueView<List<Experience>>(
        value: savedExperiencesAsync,
        onRetry: () => ref.refresh(savedExperiencesProvider),
        isEmpty: (data) => data.isEmpty,
        emptyView: EmptyStateView(
          icon: Icons.bookmark_border_rounded,
          title: SavedStrings.emptyTitle,
          description: SavedStrings.emptyDescription,
          actionLabel: SavedStrings.exploreButton,
          onActionPressed: () => context.go('/explore'),
        ),
        data: (experiences) {
          return Padding(
            padding: AppSpacing.screenPadding,
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.64,
                crossAxisSpacing: AppSpacing.md12,
                mainAxisSpacing: AppSpacing.md12,
              ),
              itemCount: experiences.length,
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
                  isSaved: true,
                  onTap: () {
                    context.push('/experience/${exp.id}');
                  },
                  onBookmarkTap: () async {
                    final savedRepo = ref.read(savedRepositoryProvider);
                    await savedRepo.toggleSave(exp.id, true);
                    ref.invalidate(savedExperiencesProvider);
                    if (context.mounted) {
                      AppToast.show(
                        context,
                        message: 'Removed from saved experiences',
                        variant: AppToastVariant.info,
                      );
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
