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
      body: PlanEBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: AppColors.successContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.success,
                    size: 52,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.reviewSubmittedTitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.headingLarge.copyWith(
                    color: AppColors.forest,
                    fontFamily: 'serif',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your feedback has been published and will help future travelers.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.disabledText,
                  ),
                ),
                const SizedBox(height: 28),
                AppButton(
                  label: 'Back to My Trips',
                  onPressed: () => context.go('/trips'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
