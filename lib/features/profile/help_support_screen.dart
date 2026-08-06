// RM-20 Help & Support Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/native_intents.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

const String _kSupportPhone = '+97714000000';
const String _kSupportEmail = 'support@plane.np';

class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: Text(
          'Help & Support',
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
            // Contact Support Hero Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg16),
              decoration: const BoxDecoration(
                color: AppColors.forest,
                borderRadius: AppRadii.borderMd16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.support_agent, color: AppColors.gold, size: 32),
                      const SizedBox(width: AppSpacing.sm8),
                      Text(
                        'Need Immediate Help?',
                        style: AppTypography.headingMedium.copyWith(
                          color: AppColors.ivory,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm8),
                  Text(
                    'Our Kathmandu support team is available 24/7 for trekking safety & booking assistance.',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.sage),
                  ),
                  const SizedBox(height: AppSpacing.md12),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Call Us',
                          icon: Icons.phone,
                          onPressed: () => NativeIntents.call(_kSupportPhone),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md12),
                      Expanded(
                        child: AppButton.secondary(
                          label: 'Live Chat',
                          icon: Icons.chat,
                          onPressed: () {
                            AppStubSheet.show(
                              context,
                              title: 'Live Support Chat',
                              featureName: '24/7 Agent Messenger (Stage B)',
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl24),

            // FAQs Section
            Text(
              'Frequently Asked Questions',
              style: AppTypography.headingMedium.copyWith(fontSize: 18),
            ),
            const SizedBox(height: AppSpacing.md12),
            const AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _FaqTile(
                    question: 'How do payments work for local homestays?',
                    answer:
                        'All prices are listed in NPR (stored in paisa). You can pay via Khalti, eSewa, or Cash on Arrival depending on the host preference.',
                  ),
                  Divider(height: 1, color: AppColors.borderSubtle),
                  _FaqTile(
                    question: 'What is the cancellation & refund policy?',
                    answer:
                        'Free cancellation up to 48 hours before the trip start time. Cancellations within 24 hours incur a 20% host preparation fee.',
                  ),
                  Divider(height: 1, color: AppColors.borderSubtle),
                  _FaqTile(
                    question: 'How are local hosts verified?',
                    answer:
                        'Every host undergoes citizenship ID verification, local background checks, and safety standard reviews by the PLAN E team.',
                  ),
                  Divider(height: 1, color: AppColors.borderSubtle),
                  _FaqTile(
                    question: 'What emergency support is available during treks?',
                    answer:
                        'PLAN E provides 24/7 mountain emergency response coordination with local rescue teams in Everest, Annapurna, and Langtang regions.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl24),

            // Email Support Action
            AppCard(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.sage,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.email_outlined, color: AppColors.forest),
                  ),
                  const SizedBox(width: AppSpacing.md12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Email Support',
                          style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'support@plane.np',
                          style: AppTypography.caption.copyWith(color: AppColors.disabledText),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.forest),
                    onPressed: () => NativeIntents.emailSupport(
                      to: _kSupportEmail,
                      subject: 'PLAN E Support Request',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqTile({
    required this.question,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        question,
        style: AppTypography.bodyLarge.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg16,
        0,
        AppSpacing.lg16,
        AppSpacing.md12,
      ),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      iconColor: AppColors.forest,
      collapsedIconColor: AppColors.disabledText,
      children: [
        Text(
          answer,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.ink,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
