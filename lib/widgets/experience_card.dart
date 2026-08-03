import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/theme.dart';
import 'rating_stars.dart';

class ExperienceCard extends StatelessWidget {
  final String title;
  final String location;
  final double rating;
  final int? reviewCount;
  final String priceText;
  final String? imageUrl;
  final String? categoryTag;
  final bool isSaved;
  final VoidCallback? onTap;
  final VoidCallback? onBookmarkTap;
  final double width;

  const ExperienceCard({
    super.key,
    required this.title,
    required this.location,
    required this.rating,
    this.reviewCount,
    required this.priceText,
    this.imageUrl,
    this.categoryTag,
    this.isSaved = false,
    this.onTap,
    this.onBookmarkTap,
    this.width = 260.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadii.borderMd16,
        border: Border.all(color: AppColors.borderSubtle, width: 1.0),
      ),
      child: Material(
        color: AppColors.transparent,
        borderRadius: AppRadii.borderMd16,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.borderMd16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image Header Stack
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadii.md16),
                    ),
                    child: Container(
                      height: 140.0,
                      width: double.infinity,
                      color: AppColors.sage,
                      child: imageUrl != null && imageUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppColors.skeletonBase,
                                child: const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.forest),
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => const Center(
                                child: Icon(Icons.terrain, size: 40, color: AppColors.forest),
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.landscape, size: 48, color: AppColors.forest),
                            ),
                    ),
                  ),

                  // Category Badge
                  if (categoryTag != null)
                    Positioned(
                      top: AppSpacing.sm8,
                      left: AppSpacing.sm8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm8,
                          vertical: AppSpacing.xs4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.deep.withValues(alpha: 0.85),
                          borderRadius: AppRadii.borderSm8,
                        ),
                        child: Text(
                          categoryTag!,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.ivory,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                  // Bookmark Button (min touch target >= 48dp)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: SizedBox(
                      width: AppTouchTarget.minSize,
                      height: AppTouchTarget.minSize,
                      child: IconButton(
                        onPressed: onBookmarkTap,
                        icon: Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color: isSaved ? AppColors.gold : AppColors.deep,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Content Details
              Padding(
                padding: AppSpacing.paddingMd12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: AppColors.disabledText),
                        const SizedBox(width: AppSpacing.xs4),
                        Expanded(
                          child: Text(
                            location,
                            style: AppTypography.caption.copyWith(color: AppColors.disabledText),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RatingStars(
                          rating: rating,
                          reviewCount: reviewCount,
                          starSize: 14.0,
                        ),
                        Text(
                          priceText,
                          style: AppTypography.bodyMedium.copyWith(
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
        ),
      ),
    );
  }
}
