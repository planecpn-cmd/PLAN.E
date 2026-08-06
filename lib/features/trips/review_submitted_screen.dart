// RM-15 Review Submitted
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

class ReviewSubmittedScreen extends StatelessWidget {
  const ReviewSubmittedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        backgroundColor: AppColors.ivory,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.forest),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.reviewSubmitted,
          style: AppTypography.headingMedium.copyWith(color: AppColors.forest),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.forest,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: AppColors.white, size: 40),
              ),
              const SizedBox(height: AppSpacing.lg16),
              Text(
                l10n.reviewSubmitted,
                style: AppTypography.headingLarge.copyWith(color: AppColors.forest),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm8),
              Text(
                'Thank you for your feedback! Your review helps build trust across Nepal.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.disabledText,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl24),
              AppButton(
                label: 'BACK TO TRIPS',
                isFullWidth: true,
                onPressed: () => context.go('/trips'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
