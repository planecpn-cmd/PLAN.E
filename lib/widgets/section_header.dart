import 'package:flutter/material.dart';
import '../theme/theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppTypography.headingMedium,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs4),
                Text(
                  subtitle!,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.disabledText),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onActionTap != null)
          Semantics(
            button: true,
            label: actionLabel!,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppTouchTarget.minSize),
              child: TextButton(
                onPressed: onActionTap,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md12,
                    vertical: AppSpacing.sm8,
                  ),
                ),
                child: Text(
                  actionLabel!,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.forest,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
