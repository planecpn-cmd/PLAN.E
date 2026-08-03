import 'package:flutter/material.dart';
import '../theme/theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color borderColor;
  final double borderRadius;
  final double elevation;

  const AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.paddingLg16,
    this.onTap,
    this.backgroundColor = AppColors.white,
    this.borderColor = AppColors.borderSubtle,
    this.borderRadius = AppRadii.md16,
    this.elevation = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.05 * elevation),
                  blurRadius: 4.0 * elevation,
                  offset: Offset(0, 2.0 * elevation),
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return ConstrainedBox(
        constraints: AppTouchTarget.minConstraints,
        child: Material(
          color: AppColors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            child: cardContent,
          ),
        ),
      );
    }

    return cardContent;
  }
}
