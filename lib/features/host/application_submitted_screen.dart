// PL-20 Host Application Submitted Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../theme/theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/progress_steps.dart';
import 'host_provider.dart';

class ApplicationSubmittedScreen extends ConsumerWidget {
  const ApplicationSubmittedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hostData = ref.watch(hostApplicationProvider);

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: Text(
          'Application Status',
          style: AppTypography.headingMedium.copyWith(color: AppColors.ink),
        ),
        backgroundColor: AppColors.ivory,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          constraints: AppTouchTarget.minConstraints,
          onPressed: () => context.go('/profile'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Hero Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl20),
              decoration: const BoxDecoration(
                color: AppColors.forest,
                borderRadius: AppRadii.borderMd16,
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md12),
                    decoration: const BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_read_outlined,
                      color: AppColors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md12),
                  Text(
                    'Application Under Review',
                    style: AppTypography.headingMedium.copyWith(
                      color: AppColors.ivory,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs4),
                  Text(
                    'Reference ID: PL-HOST-${DateTime.now().year}-9841',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.sage,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl24),

            // Status Progress Tracker
            Text(
              'Application Tracker',
              style: AppTypography.headingMedium.copyWith(fontSize: 18),
            ),
            const SizedBox(height: AppSpacing.sm8),
            const ProgressSteps(
              steps: ['Submitted', 'Under Review', 'ID Verified', 'Approved'],
              currentStep: 1,
            ),
            const SizedBox(height: AppSpacing.xxl24),

            // Summary Card of Application
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                      const SizedBox(width: AppSpacing.xs4),
                      Text(
                        'Submitted Details',
                        style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: AppColors.borderSubtle),

                  _DetailRow(
                    label: 'Host Name',
                    value: hostData.fullName.isNotEmpty ? hostData.fullName : 'Siddharth Gurung',
                  ),
                  _DetailRow(
                    label: 'District',
                    value: hostData.district,
                  ),
                  _DetailRow(
                    label: 'Listing Title',
                    value: hostData.experienceTitle.isNotEmpty
                        ? hostData.experienceTitle
                        : 'Kathmandu Valley Heritage Village Walk',
                  ),
                  _DetailRow(
                    label: 'Listing Price',
                    value: AppFormatters.formatNpr(hostData.pricePaisa),
                  ),
                  _DetailRow(
                    label: 'ID Verification',
                    value: '${hostData.idType} (${hostData.idNumber})',
                  ),
                  _DetailRow(
                    label: 'Payout Account',
                    value: '${hostData.bankName} (${hostData.accountNumber})',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl20),

            // Notice Box
            Container(
              padding: const EdgeInsets.all(AppSpacing.md12),
              decoration: const BoxDecoration(
                color: AppColors.cardBackgroundAlt,
                borderRadius: AppRadii.borderMd16,
                border: Border.fromBorderSide(BorderSide(color: AppColors.borderSubtle)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.forest, size: 22),
                  const SizedBox(width: AppSpacing.md12),
                  Expanded(
                    child: Text(
                      'Applications are reviewed within 24-48 hours. Our verification team in Kathmandu may reach out to verify details.',
                      style: AppTypography.caption.copyWith(color: AppColors.ink, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: AppButton.secondary(
                    label: 'View Profile',
                    onPressed: () => context.go('/profile'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md12),
                Expanded(
                  child: AppButton(
                    label: 'Return Home',
                    onPressed: () => context.go('/home'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg16),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs4 + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.disabledText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
