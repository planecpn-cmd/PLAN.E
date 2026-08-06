import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/theme.dart';
import 'app_button.dart';

class AppStubSheet extends StatelessWidget {
  final String title;
  final String? featureName;
  final String? description;

  const AppStubSheet({
    super.key,
    required this.title,
    this.featureName,
    this.description,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    String? featureName,
    String? description,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AppStubSheet(
        title: title,
        featureName: featureName,
        description: description,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl20),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg16),
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.sage,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.construction_outlined,
                color: AppColors.forest,
                size: 28,
              ),
            ),
            const SizedBox(height: AppSpacing.md12),
            Text(
              title,
              style: AppTypography.headingMedium.copyWith(color: AppColors.forest),
              textAlign: TextAlign.center,
            ),
            if (featureName != null) ...[
              const SizedBox(height: AppSpacing.xs4),
              Text(
                featureName!,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AppSpacing.sm8),
            Text(
              description ??
                  'This Stage B feature is coming soon in future releases of PLAN E.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.disabledText,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl20),
            AppButton(
              label: 'CLOSE',
              isFullWidth: true,
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }
}
