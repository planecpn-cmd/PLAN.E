import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/image_cache_manager.dart';
import '../core/image_url.dart';
import '../core/photo_alignment.dart';
import '../theme/tokens.dart';

class PlanEPhoto extends StatelessWidget {
  final String? imageUrl;
  final double? height;
  final double? width;
  final double radius;
  final Widget? overlay;
  final BoxFit fit;
  // Pixels to actually request from the network — independent of [width],
  // which is frequently unbounded (`double.infinity` for a full-bleed
  // banner) or simply not passed at all (many call sites size this widget
  // via an outer SizedBox/Expanded this widget never sees). Defaults to a
  // size that comfortably covers typical card/thumbnail use; pass a larger
  // value for a genuinely full-bleed hero image. See
  // docs/OFFLINE_CACHE_PLAN.md §4.2.
  final int imageRequestWidth;

  const PlanEPhoto({
    super.key,
    this.imageUrl,
    this.height,
    this.width,
    this.radius = 22,
    this.overlay,
    this.fit = BoxFit.cover,
    this.imageRequestWidth = 400,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      imageWidget = CachedNetworkImage(
        imageUrl: resizedImageUrl(imageUrl!, width: imageRequestWidth),
        cacheManager: AppImageCacheManager.instance,
        fit: fit,
        alignment: photoAlignment(imageUrl),
        placeholder: (context, url) => Container(
          color: AppColors.sage,
          child: const Center(
            child: Icon(Icons.landscape, color: AppColors.forest, size: 28),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: AppColors.sage,
          child: const Center(
            child: Icon(
              Icons.broken_image,
              color: AppColors.disabledText,
              size: 28,
            ),
          ),
        ),
      );
    } else {
      imageWidget = Container(
        color: AppColors.sage,
        child: const Center(
          child: Icon(Icons.landscape, color: AppColors.forest, size: 28),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        height: height,
        width: width,
        child: Stack(
          fit: StackFit.expand,
          children: [imageWidget, if (overlay != null) overlay!],
        ),
      ),
    );
  }
}
