import 'package:flutter/material.dart';
import '../theme/theme.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final int maxStars;
  final double starSize;
  final bool showLabel;
  final int? reviewCount;
  final ValueChanged<double>? onRatingChanged;

  const RatingStars({
    super.key,
    required this.rating,
    this.maxStars = 5,
    this.starSize = 18.0,
    this.showLabel = true,
    this.reviewCount,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool isInteractive = onRatingChanged != null;

    final List<Widget> stars = List.generate(maxStars, (index) {
      final double starValue = index + 1.0;
      IconData iconData;
      if (rating >= starValue) {
        iconData = Icons.star;
      } else if (rating >= starValue - 0.5) {
        iconData = Icons.star_half;
      } else {
        iconData = Icons.star_border;
      }

      final Widget starIcon = Icon(
        iconData,
        size: starSize,
        color: rating >= (index + 0.5) ? AppColors.gold : AppColors.disabledText,
      );

      if (isInteractive) {
        return SizedBox(
          width: AppTouchTarget.minSize,
          height: AppTouchTarget.minSize,
          child: IconButton(
            onPressed: () => onRatingChanged!(starValue),
            icon: starIcon,
            padding: EdgeInsets.zero,
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.only(right: 2.0),
        child: starIcon,
      );
    });

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: stars),
        if (showLabel) ...[
          const SizedBox(width: AppSpacing.xs4),
          Text(
            rating.toStringAsFixed(1),
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          if (reviewCount != null) ...[
            const SizedBox(width: AppSpacing.xs4),
            Text(
              '($reviewCount)',
              style: AppTypography.caption.copyWith(color: AppColors.disabledText),
            ),
          ],
        ],
      ],
    );
  }
}
