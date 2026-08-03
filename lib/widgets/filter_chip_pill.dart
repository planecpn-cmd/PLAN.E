import 'package:flutter/material.dart';
import '../theme/theme.dart';

class FilterChipPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool>? onSelected;
  final IconData? icon;

  const FilterChipPill({
    super.key,
    required this.label,
    required this.isSelected,
    this.onSelected,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppTouchTarget.minSize),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: onSelected != null ? () => onSelected!(!isSelected) : null,
          borderRadius: AppRadii.borderPill,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg16,
              vertical: AppSpacing.sm8,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.forest : AppColors.sage,
              borderRadius: AppRadii.borderPill,
              border: Border.all(
                color: isSelected ? AppColors.forest : AppColors.border,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isSelected) ...[
                  const Icon(
                    Icons.check,
                    size: 16.0,
                    color: AppColors.ivory,
                  ),
                  const SizedBox(width: AppSpacing.xs4),
                ] else if (icon != null) ...[
                  Icon(
                    icon,
                    size: 16.0,
                    color: AppColors.ink,
                  ),
                  const SizedBox(width: AppSpacing.xs4),
                ],
                Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isSelected ? AppColors.ivory : AppColors.ink,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
