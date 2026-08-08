import 'package:flutter/material.dart';
import '../theme/theme.dart';

enum AppButtonVariant { primary, secondary, text, disabled }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  // Takes precedence over [icon] when set — for leading graphics that
  // aren't a single-color IconData, e.g. a multi-color brand mark.
  final Widget? iconWidget;
  final bool isFullWidth;
  final double minHeight;
  final double? fontSize;
  // Overrides the variant's default corner radius (16px rect, 8px for
  // .text) — e.g. AppRadii.borderPill for a stadium-shaped button.
  final BorderRadius? borderRadius;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.iconWidget,
    this.isFullWidth = false,
    this.minHeight = AppTouchTarget.minSize,
    this.fontSize,
    this.borderRadius,
  });

  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.iconWidget,
    this.isFullWidth = false,
    this.minHeight = AppTouchTarget.minSize,
    this.fontSize,
    this.borderRadius,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.text({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.iconWidget,
    this.isFullWidth = false,
    this.minHeight = AppTouchTarget.minSize,
    this.fontSize,
    this.borderRadius,
  }) : variant = AppButtonVariant.text;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled =
        variant == AppButtonVariant.disabled || onPressed == null || isLoading;

    final Widget content = isLoading
        ? SizedBox(
            width: 20.0,
            height: 20.0,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                variant == AppButtonVariant.primary
                    ? AppColors.ivory
                    : AppColors.forest,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (iconWidget != null) ...[
                iconWidget!,
                const SizedBox(width: AppSpacing.sm8),
              ] else if (icon != null) ...[
                Icon(icon, size: 20.0, color: _getTextColor(isDisabled)),
                const SizedBox(width: AppSpacing.sm8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyLarge.copyWith(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: _getTextColor(isDisabled),
                  ),
                ),
              ),
            ],
          );

    final BoxConstraints constraints = BoxConstraints(
      minHeight: minHeight,
      minWidth: isFullWidth ? double.infinity : minHeight,
    );

    Widget buttonWidget;

    switch (variant) {
      case AppButtonVariant.primary:
        buttonWidget = ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.forest,
            foregroundColor: AppColors.ivory,
            disabledBackgroundColor: AppColors.disabledBackground,
            disabledForegroundColor: AppColors.disabledText,
            minimumSize: Size(
              isFullWidth ? double.infinity : AppTouchTarget.minSize,
              minHeight,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxl24,
              vertical: AppSpacing.md12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius ?? AppRadii.borderMd16,
            ),
          ),
          child: content,
        );
        break;

      case AppButtonVariant.secondary:
        buttonWidget = OutlinedButton(
          onPressed: isDisabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.forest,
            disabledForegroundColor: AppColors.disabledText,
            backgroundColor: AppColors.white,
            minimumSize: Size(
              isFullWidth ? double.infinity : AppTouchTarget.minSize,
              minHeight,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxl24,
              vertical: AppSpacing.md12,
            ),
            side: BorderSide(
              color: isDisabled ? AppColors.borderSubtle : AppColors.forest,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius ?? AppRadii.borderMd16,
            ),
          ),
          child: content,
        );
        break;

      case AppButtonVariant.text:
        buttonWidget = TextButton(
          onPressed: isDisabled ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.forest,
            disabledForegroundColor: AppColors.disabledText,
            minimumSize: Size(
              isFullWidth ? double.infinity : AppTouchTarget.minSize,
              minHeight,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg16,
              vertical: AppSpacing.sm8,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius ?? AppRadii.borderSm8,
            ),
          ),
          child: content,
        );
        break;

      case AppButtonVariant.disabled:
        buttonWidget = ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.disabledBackground,
            foregroundColor: AppColors.disabledText,
            minimumSize: Size(
              isFullWidth ? double.infinity : AppTouchTarget.minSize,
              minHeight,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxl24,
              vertical: AppSpacing.md12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius ?? AppRadii.borderMd16,
            ),
          ),
          child: content,
        );
        break;
    }

    return Semantics(
      button: true,
      enabled: !isDisabled,
      label: label,
      child: ConstrainedBox(
        constraints: constraints,
        child: isFullWidth
            ? SizedBox(width: double.infinity, child: buttonWidget)
            : buttonWidget,
      ),
    );
  }

  Color _getTextColor(bool isDisabled) {
    if (isDisabled) return AppColors.disabledText;
    switch (variant) {
      case AppButtonVariant.primary:
        return AppColors.ivory;
      case AppButtonVariant.secondary:
      case AppButtonVariant.text:
        return AppColors.forest;
      case AppButtonVariant.disabled:
        return AppColors.disabledText;
    }
  }
}
