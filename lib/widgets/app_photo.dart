import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class PlanEPhoto extends StatelessWidget {
  final String? imageUrl;
  final double? height;
  final double? width;
  final double radius;
  final Widget? overlay;
  final BoxFit fit;

  const PlanEPhoto({
    super.key,
    this.imageUrl,
    this.height,
    this.width,
    this.radius = 22,
    this.overlay,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: fit,
        placeholder: (context, url) => Container(
          color: AppColors.sage,
          child: const Center(
            child: Icon(Icons.landscape, color: AppColors.forest, size: 28),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: AppColors.sage,
          child: const Center(
            child: Icon(Icons.broken_image, color: AppColors.disabledText, size: 28),
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
          children: [
            imageWidget,
            if (overlay != null) overlay!,
          ],
        ),
      ),
    );
  }
}
