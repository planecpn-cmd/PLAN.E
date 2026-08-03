// RM-13 Budget Tracker
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';

class BudgetTrackerScreen extends StatelessWidget {
  final String bookingId;

  const BudgetTrackerScreen({
    super.key,
    required this.bookingId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: Text(
          'Trip Budget Tracker',
          style: AppTypography.headingMedium.copyWith(color: AppColors.ink),
        ),
        backgroundColor: AppColors.ivory,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xl20),
              AppCard(
                child: Padding(
                  padding: AppSpacing.paddingLg16,
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: AppColors.sage,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 36,
                            color: AppColors.forest,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md12,
                          vertical: AppSpacing.xs4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.15),
                          borderRadius: AppRadii.borderPill,
                        ),
                        child: Text(
                          'COMING SOON',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.gold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md12),
                      Text(
                        'Expenses & Group Splitter',
                        style: AppTypography.headingMedium.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm8),
                      Text(
                        'Track on-trail expenses, permits, tips, meals, and share costs with group members for trip #${bookingId.length > 8 ? bookingId.substring(0, 8) : bookingId}. Group expense tracking is coming soon!',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.ink.withValues(alpha: 0.75),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xxl24),
                      AppButton(
                        label: 'Back to Itinerary',
                        variant: AppButtonVariant.primary,
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


