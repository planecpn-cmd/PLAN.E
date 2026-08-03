// RM-25 Delete Draft Dialog
import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../widgets/app_button.dart';

class DeleteDraftDialog extends StatelessWidget {
  final String? planTitle;

  const DeleteDraftDialog({
    super.key,
    this.planTitle,
  });

  static Future<bool?> show(BuildContext context, {String? planTitle}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => DeleteDraftDialog(planTitle: planTitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.borderLg24),
      backgroundColor: AppColors.white,
      child: Padding(
        padding: AppSpacing.paddingXxl24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: AppTouchTarget.minSize,
              height: AppTouchTarget.minSize,
              decoration: const BoxDecoration(
                color: AppColors.errorContainer,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg16),
            Text(
              'Delete Trip Draft',
              style: AppTypography.headingMedium.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm8),
            Text(
              planTitle != null && planTitle!.isNotEmpty
                  ? 'Are you sure you want to delete "$planTitle"? This draft and all saved progress will be permanently removed.'
                  : 'Are you sure you want to delete this trip draft? This action cannot be undone.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.ink.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl24),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Cancel',
                    variant: AppButtonVariant.secondary,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: AppSpacing.md12),
                Expanded(
                  child: AppButton(
                    label: 'Delete',
                    variant: AppButtonVariant.primary,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


