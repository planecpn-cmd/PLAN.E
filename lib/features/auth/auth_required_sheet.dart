import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/app_button.dart';

class AuthRequiredSheet extends ConsumerWidget {
  const AuthRequiredSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final deferredAction = ref.watch(deferredActionProvider);
    final actionDescription = deferredAction?.action ?? 'proceed with this feature';

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        backgroundColor: AppColors.ivory,
        elevation: 0,
        title: Text(
          l10n.authRequiredTitle,
          style: AppTypography.headingMedium.copyWith(color: AppColors.forest),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 80.0,
                height: 80.0,
                decoration: const BoxDecoration(
                  color: AppColors.sage,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_person_outlined,
                  color: AppColors.forest,
                  size: 44.0,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl24),

              Text(
                l10n.authRequiredTitle,
                style: AppTypography.headingLarge.copyWith(color: AppColors.deep),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md12),

              Text(
                'Please log in or create an account to $actionDescription.',
                style: AppTypography.bodyLarge.copyWith(color: AppColors.ink),
                textAlign: TextAlign.center,
              ),
              const Spacer(),

              AppButton(
                label: l10n.login,
                onPressed: () {
                  context.go('/auth/login');
                },
                isFullWidth: true,
                minHeight: AppTouchTarget.minSize,
              ),
              const SizedBox(height: AppSpacing.md12),

              AppButton.secondary(
                label: l10n.createAccount,
                onPressed: () {
                  context.go('/auth/sign-up');
                },
                isFullWidth: true,
                minHeight: AppTouchTarget.minSize,
              ),
              const SizedBox(height: AppSpacing.md12),

              ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: AppTouchTarget.minSize,
                  minHeight: AppTouchTarget.minSize,
                ),
                child: TextButton(
                  onPressed: () {
                    ref.read(deferredActionProvider.notifier).clear();
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                  child: Text(
                    'Continue as Guest',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.disabledText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg16),
            ],
          ),
        ),
      ),
    );
  }
}
