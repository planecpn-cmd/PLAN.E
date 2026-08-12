import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/image_cache_manager.dart';
import '../core/image_url.dart';
import '../theme/theme.dart';
import 'rating_stars.dart';

/// .horizontal: the original landscape-image card (search results, saved,
/// explore grids). .poster: a taller, portrait-image card for home-screen
/// rails — same idea as Netflix's title rows, where a tall consistent poster
/// shape reads as curated rather than a generic list-item thumbnail.
enum ExperienceCardVariant { horizontal, poster }

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
  final ExperienceCardVariant variant;

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
    this.variant = ExperienceCardVariant.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPoster = variant == ExperienceCardVariant.poster;
    final double imageHeight = isPoster ? width * 1.07 : 140.0;

    return Semantics(
      container: true,
      button: true,
      label: '$title experience in $location, price $priceText',
      child: Container(
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
                      child: Semantics(
                        image: true,
                        label: '$title photo',
                        child: Container(
                          height: imageHeight,
                          width: double.infinity,
                          color: AppColors.sage,
                          child: imageUrl != null && imageUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  // 2x width for retina crispness — `width`
                                  // here is this card's own real, always-
                                  // finite render width (never unbounded),
                                  // so this is the exact size actually
                                  // needed, not a guess. See
                                  // docs/OFFLINE_CACHE_PLAN.md §4.2.
                                  imageUrl: resizedImageUrl(
                                    imageUrl!,
                                    width: (width * 2).round(),
                                  ),
                                  cacheManager: AppImageCacheManager.instance,
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

                    // Bookmark button — top offset matches the category
                    // badge's exactly (both AppSpacing.sm8) so the two sit
                    // on the same plane instead of the badge sitting lower
                    // than the bookmark's larger tap-target box did.
                    Positioned(
                      top: AppSpacing.sm8,
                      right: AppSpacing.sm8,
                      child: Semantics(
                        button: true,
                        label: isSaved ? 'Remove $title from saved' : 'Save $title',
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: onBookmarkTap,
                            icon: Icon(
                              isSaved ? Icons.bookmark : Icons.bookmark_border,
                              color: isSaved ? AppColors.gold : AppColors.deep,
                              size: 22,
                            ),
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
                      if (isPoster)
                        // Stacked, not shared on one row — a poster card is
                        // narrow enough that cramming a 5-star rating, a
                        // review count, and a price onto one line was
                        // truncating the price. Each gets the card's full
                        // width on its own line instead.
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star, size: 14, color: AppColors.gold),
                                const SizedBox(width: 2),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: AppTypography.caption.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              priceText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.forest,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: RatingStars(
                                rating: rating,
                                reviewCount: reviewCount,
                                starSize: 14.0,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs4),
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
      ),
    );
  }
}
