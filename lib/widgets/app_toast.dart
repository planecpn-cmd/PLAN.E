import 'package:flutter/material.dart';
import '../theme/theme.dart';

enum AppToastVariant { success, error, info }

class AppToast extends StatelessWidget {
  final String message;
  final AppToastVariant variant;
  final VoidCallback? onDismiss;

  const AppToast({
    super.key,
    required this.message,
    this.variant = AppToastVariant.info,
    this.onDismiss,
  });

  static void show(
    BuildContext context, {
    required String message,
    AppToastVariant variant = AppToastVariant.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    final snackBar = SnackBar(
      elevation: 0,
      backgroundColor: AppColors.transparent,
      duration: duration,
      content: AppToast(
        message: message,
        variant: variant,
        onDismiss: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    final Color bgColor = _getBackgroundColor();
    final Color textColor = _getTextColor();
    final IconData iconData = _getIcon();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg16,
        vertical: AppSpacing.md12,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadii.borderMd16,
        boxShadow: const [
          BoxShadow(
            color: AppColors.overlay,
            blurRadius: 8.0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(iconData, color: textColor, size: 24),
          const SizedBox(width: AppSpacing.md12),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onDismiss != null)
            SizedBox(
              width: AppTouchTarget.minSize,
              height: AppTouchTarget.minSize,
              child: IconButton(
                onPressed: onDismiss,
                icon: Icon(Icons.close, color: textColor, size: 20),
                padding: EdgeInsets.zero,
              ),
            ),
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (variant) {
      case AppToastVariant.success:
        return AppColors.successContainer;
      case AppToastVariant.error:
        return AppColors.errorContainer;
      case AppToastVariant.info:
        return AppColors.deep;
    }
  }

  Color _getTextColor() {
    switch (variant) {
      case AppToastVariant.success:
        return AppColors.success;
      case AppToastVariant.error:
        return AppColors.error;
      case AppToastVariant.info:
        return AppColors.ivory;
    }
  }

  IconData _getIcon() {
    switch (variant) {
      case AppToastVariant.success:
        return Icons.check_circle_outline;
      case AppToastVariant.error:
        return Icons.error_outline;
      case AppToastVariant.info:
        return Icons.info_outline;
    }
  }
}
