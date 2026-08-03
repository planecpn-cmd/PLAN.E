// PL-18 Become a Host Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import 'host_provider.dart';

class BecomeHostScreen extends ConsumerWidget {
  const BecomeHostScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).asData?.value;
    final hostData = ref.watch(hostApplicationProvider);

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: Text(
          'Become a Host',
          style: AppTypography.headingMedium.copyWith(color: AppColors.ink),
        ),
        backgroundColor: AppColors.ivory,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          constraints: AppTouchTarget.minConstraints,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xxl24),
              decoration: BoxDecoration(
                color: AppColors.forest,
                borderRadius: AppRadii.borderLg24,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md12,
                      vertical: AppSpacing.xs4,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: AppRadii.borderPill,
                    ),
                    child: Text(
                      'HOST IN NEPAL',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md12),
                  Text(
                    'Turn your local culture & home into an experience.',
                    style: AppTypography.displayMedium.copyWith(
                      color: AppColors.ivory,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm8),
                  Text(
                    'Welcome travelers from around the world to your homestay, cooking class, or guided trail in Nepal.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.sage,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl24),

            Text(
              'Why Host on PLAN E?',
              style: AppTypography.headingMedium.copyWith(fontSize: 20),
            ),
            const SizedBox(height: AppSpacing.md12),

            // Benefits Grid
            const Row(
              children: [
                Expanded(
                  child: _BenefitCard(
                    icon: Icons.payments_outlined,
                    title: 'Direct NPR Payouts',
                    description: 'Receive fast payouts via Khalti, eSewa or direct bank transfer.',
                  ),
                ),
                SizedBox(width: AppSpacing.md12),
                Expanded(
                  child: _BenefitCard(
                    icon: Icons.holiday_village_outlined,
                    title: 'Homestay Support',
                    description: 'List your rooms, organic meals & village activities with ease.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md12),
            const Row(
              children: [
                Expanded(
                  child: _BenefitCard(
                    icon: Icons.people_outline,
                    title: 'Community Impact',
                    description: '100% of booking revenue directly empowers your local community.',
                  ),
                ),
                SizedBox(width: AppSpacing.md12),
                Expanded(
                  child: _BenefitCard(
                    icon: Icons.security_outlined,
                    title: 'Verified Safety',
                    description: 'Host with peace of mind through mandatory traveler ID verification.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl24),

            // Process steps preview
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Application Process (4 Steps)',
                    style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.sm8),
                  const _StepPreviewRow(number: '1', text: 'Basic Profile & Host Information'),
                  const _StepPreviewRow(number: '2', text: 'First Experience or Homestay Listing'),
                  const _StepPreviewRow(number: '3', text: 'Citizenship / Government ID Verification'),
                  const _StepPreviewRow(number: '4', text: 'Bank & Payout Setup'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl24),

            // Start / Continue Application Button
            AppButton(
              label: hostData.status == 'under_review'
                  ? 'View Submitted Status'
                  : 'Start Host Application',
              icon: Icons.arrow_forward,
              isFullWidth: true,
              onPressed: () {
                if (profile?.role.name == 'hostApplicant' || hostData.status == 'under_review') {
                  context.push('/host/submitted');
                } else {
                  context.push('/host/step-1');
                }
              },
            ),
            const SizedBox(height: AppSpacing.lg16),
          ],
        ),
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _BenefitCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm8),
            decoration: const BoxDecoration(
              color: AppColors.sage,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.forest, size: 22),
          ),
          const SizedBox(height: AppSpacing.sm8),
          Text(
            title,
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.xs4),
          Text(
            description,
            style: AppTypography.caption.copyWith(
              color: AppColors.disabledText,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepPreviewRow extends StatelessWidget {
  final String number;
  final String text;

  const _StepPreviewRow({
    required this.number,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs4),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.forest,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: AppTypography.caption.copyWith(
                color: AppColors.ivory,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm8),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}
