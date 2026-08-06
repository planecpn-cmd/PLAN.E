// RM-27 My Reviews Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/rating_stars.dart';

class UserReviewItem {
  final String id;
  final String experienceTitle;
  final String location;
  final double rating;
  final String comment;
  final DateTime createdAt;

  const UserReviewItem({
    required this.id,
    required this.experienceTitle,
    required this.location,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });
}

final userReviewsProvider = FutureProvider.autoDispose<List<UserReviewItem>>((
  ref,
) async {
  final reviews = await ref.watch(reviewRepositoryProvider).getMyReviews();
  return reviews.map((item) {
    final review = item.review;
    final comment = review.body?.trim();
    final title = review.title?.trim();
    return UserReviewItem(
      id: review.id,
      experienceTitle: item.experienceTitle,
      location: item.location,
      rating: review.rating.toDouble(),
      comment: comment?.isNotEmpty == true
          ? comment!
          : title?.isNotEmpty == true
          ? title!
          : 'Star rating only',
      createdAt: review.createdAt,
    );
  }).toList();
});

class MyReviewsScreen extends ConsumerWidget {
  const MyReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(userReviewsProvider);

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: Text(
          'My Reviews',
          style: AppTypography.headingMedium.copyWith(color: AppColors.ink),
        ),
        backgroundColor: AppColors.ivory,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          constraints: AppTouchTarget.minConstraints,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: AsyncValueView<List<UserReviewItem>>(
        value: reviewsAsync,
        onRetry: () => ref.refresh(userReviewsProvider),
        isEmpty: (list) => list.isEmpty,
        emptyView: const EmptyStateView(
          title: 'No Reviews Yet',
          description:
              'Complete a local experience trip to leave ratings and share feedback.',
        ),
        data: (reviews) {
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg16),
            itemCount: reviews.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.md12),
            itemBuilder: (context, index) {
              final review = reviews[index];
              final String formattedDate = AppFormatters.formatTripDate(
                review.createdAt,
                pattern: 'd MMM yyyy',
              );

              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                review.experienceTitle,
                                style: AppTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: AppColors.disabledText,
                                  ),
                                  const SizedBox(width: AppSpacing.xs4),
                                  Text(
                                    review.location,
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.disabledText,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formattedDate,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.disabledText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md12),
                    RatingStars(rating: review.rating),
                    const SizedBox(height: AppSpacing.sm8),
                    Text(
                      review.comment,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.ink,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
