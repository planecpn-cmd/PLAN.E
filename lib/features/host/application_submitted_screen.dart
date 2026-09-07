import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/host_application.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

class ApplicationSubmittedScreen extends ConsumerWidget {
  const ApplicationSubmittedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: SafeArea(
        child: AsyncValueView<HostApplication?>(
          value: ref.watch(myHostApplicationProvider),
          onRetry: () => ref.invalidate(myHostApplicationProvider),
          data: (application) => Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xxl24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.sage,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 38,
                        color: AppColors.forest,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl24),
                    Text(
                      'Application submitted',
                      textAlign: TextAlign.center,
                      style: AppTypography.displayMedium.copyWith(
                        fontFamily: 'serif',
                        color: AppColors.forest,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md12),
                    const Text(
                      'Your host application has been sent to Plan E for review.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.xxl24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg16,
                        vertical: AppSpacing.sm8,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.sage,
                        borderRadius: AppRadii.borderPill,
                      ),
                      child: Text(
                        _statusLabel(application?.status),
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.forest,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .8,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg16),
                    const Text(
                      'We’ll let you know if we need any additional information.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxxl32),
                    AppButton(
                      label: 'Back to My Account',
                      isFullWidth: true,
                      onPressed: () => context.go('/profile'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _statusLabel(HostAppStatus? status) {
    switch (status) {
      case HostAppStatus.actionRequired:
        return 'ACTION REQUIRED';
      case HostAppStatus.approved:
        return 'APPROVED';
      case HostAppStatus.rejected:
        return 'REJECTED';
      case HostAppStatus.draft:
        return 'DRAFT';
      case HostAppStatus.verification:
      case HostAppStatus.submitted:
      case HostAppStatus.underReview:
      case null:
        return 'UNDER REVIEW';
    }
  }
}
