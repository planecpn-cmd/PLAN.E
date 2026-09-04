import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/image_cache_manager.dart';
import '../core/image_url.dart';
import '../core/photo_alignment.dart';
import '../theme/theme.dart';
import 'rating_stars.dart';

/// .horizontal: the original landscape-image card (search results, saved,
/// explore grids). .poster: a taller, portrait-image card for home-screen
/// rails — same idea as Netflix's title rows, where a tall consistent poster
/// shape reads as curated rather than a generic list-item thumbnail.
enum ExperienceCardVariant { horizontal, poster, square }

class ExperienceCard extends StatelessWidget {
  final String title;
  final String location;
  final double rating;
  final int? reviewCount;
  final String priceText;
  final String? imageUrl;
  final Alignment? imageAlignment;
  final String? familyLabel;
  final String? typeLabel;
  final String? detailText;
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
    this.imageAlignment,
    this.familyLabel,
    this.typeLabel,
    this.detailText,
    this.isSaved = false,
    this.onTap,
    this.onBookmarkTap,
    this.width = 260.0,
    this.variant = ExperienceCardVariant.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    if (variant == ExperienceCardVariant.square) return _buildSquare(context);
    final bool isPoster = variant == ExperienceCardVariant.poster;
    final resolvedWidth = width.isFinite
        ? width
        : MediaQuery.sizeOf(context).width;
    final double imageHeight = isPoster
        ? resolvedWidth * 1.07
        : resolvedWidth * 0.56;
    final imageRequestWidth = (resolvedWidth * 2).round();

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
                              ? imageUrl!.startsWith('assets/')
                                    ? Image.asset(
                                        imageUrl!,
                                        fit: BoxFit.cover,
                                        alignment:
                                            imageAlignment ??
                                            photoAlignment(imageUrl),
                                      )
                                    : CachedNetworkImage(
                                        // 2x the resolved card width for retina
                                        // crispness. Full-width list cards pass
                                        // infinity, so they resolve against the
                                        // current viewport first. See
                                        // docs/OFFLINE_CACHE_PLAN.md §4.2.
                                        imageUrl: resizedImageUrl(
                                          imageUrl!,
                                          width: imageRequestWidth,
                                        ),
                                        cacheManager:
                                            AppImageCacheManager.instance,
                                        fit: BoxFit.cover,
                                        alignment:
                                            imageAlignment ??
                                            photoAlignment(imageUrl),
                                        placeholder: (context, url) => Container(
                                          color: AppColors.skeletonBase,
                                          child: const Center(
                                            child: SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(AppColors.forest),
                                              ),
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            const Center(
                                              child: Icon(
                                                Icons.image_outlined,
                                                size: 40,
                                                color: AppColors.forest,
                                              ),
                                            ),
                                      )
                              : const Center(
                                  child: Icon(
                                    Icons.image_outlined,
                                    size: 48,
                                    color: AppColors.forest,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    // The primary badge communicates what family this is.
                    // Physical difficulty belongs in contextual metadata and
                    // is only supplied for adventure experiences.
                    if (familyLabel != null && familyLabel!.isNotEmpty)
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
                            familyLabel!.toUpperCase(),
                            style: AppTypography.caption.copyWith(
                              color: AppColors.ivory,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                    // Keep the full Android touch target inside the image.
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Semantics(
                        button: true,
                        label: isSaved
                            ? 'Remove $title from saved'
                            : 'Save $title',
                        child: SizedBox(
                          width: AppTouchTarget.minSize,
                          height: AppTouchTarget.minSize,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: onBookmarkTap,
                            icon: Icon(
                              isSaved ? Icons.bookmark : Icons.bookmark_border,
                              color: isSaved
                                  ? AppColors.forest
                                  : AppColors.deep,
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
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                          Expanded(
                            child: Text(
                              location,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.disabledText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if ((typeLabel?.isNotEmpty ?? false) ||
                          (detailText?.isNotEmpty ?? false)) ...[
                        const SizedBox(height: AppSpacing.xs4),
                        Text(
                          [
                            if (typeLabel?.isNotEmpty ?? false) typeLabel!,
                            if (detailText?.isNotEmpty ?? false) detailText!,
                          ].join(' • '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.forest,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
                                const Icon(
                                  Icons.star,
                                  size: 14,
                                  color: AppColors.gold,
                                ),
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
                        Wrap(
                          spacing: AppSpacing.sm8,
                          runSpacing: AppSpacing.xs4,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
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
      ),
    );
  }

  Widget _buildSquare(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label: '$title experience in $location, price $priceText',
      child: SizedBox.square(
        dimension: width,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: AppRadii.borderMd16,
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Material(
            color: AppColors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          color: AppColors.sage,
                          child: imageUrl?.isNotEmpty ?? false
                              ? imageUrl!.startsWith('assets/')
                                    ? Image.asset(
                                        imageUrl!,
                                        fit: BoxFit.cover,
                                        alignment:
                                            imageAlignment ??
                                            photoAlignment(imageUrl),
                                      )
                                    : CachedNetworkImage(
                                        imageUrl: resizedImageUrl(
                                          imageUrl!,
                                          width: (width * 2).round(),
                                        ),
                                        cacheManager:
                                            AppImageCacheManager.instance,
                                        fit: BoxFit.cover,
                                        alignment:
                                            imageAlignment ??
                                            photoAlignment(imageUrl),
                                        errorWidget: (_, _, _) => const Icon(
                                          Icons.image_outlined,
                                          color: AppColors.forest,
                                        ),
                                      )
                              : const Icon(
                                  Icons.image_outlined,
                                  color: AppColors.forest,
                                ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: SizedBox.square(
                            dimension: AppTouchTarget.minSize,
                            child: IconButton(
                              tooltip: isSaved
                                  ? 'Remove $title from saved'
                                  : 'Save $title',
                              onPressed: onBookmarkTap,
                              icon: Icon(
                                isSaved
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: isSaved
                                    ? AppColors.forest
                                    : AppColors.deep,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: AppSpacing.paddingMd12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height:
                              MediaQuery.textScalerOf(context).scale(16) * 3,
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: AppColors.disabledText,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.disabledText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: AppColors.gold,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              rating.toStringAsFixed(1),
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                priceText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.forest,
                                  fontSize: 13,
                                ),
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
      ),
    );
  }
}
