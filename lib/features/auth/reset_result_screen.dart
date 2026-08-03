// RM-04 Reset Result
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../widgets/app_button.dart';

class ResetResultScreen extends StatelessWidget {
  const ResetResultScreen({super.key});

  static const String _screenTitle = 'Check Your Inbox';
  static const String _screenSubtitle =
      'We have sent password reset instructions to your email address or mobile phone. Please follow the instructions to set a new password.';
  static const String _backToLoginText = 'Return to Login';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        backgroundColor: AppColors.ivory,
        elevation: 0,
        title: Text(
          'RM-04 Reset Result',
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
                width: 96.0,
                height: 96.0,
                decoration: BoxDecoration(
                  color: AppColors.successContainer,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.success, width: 2.0),
                ),
                child: const Icon(
                  Icons.mark_email_read_rounded,
                  color: AppColors.success,
                  size: 48.0,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl32),

              Text(
                _screenTitle,
                style: AppTypography.headingLarge.copyWith(color: AppColors.deep),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md12),

              Text(
                _screenSubtitle,
                style: AppTypography.bodyLarge.copyWith(color: AppColors.ink),
                textAlign: TextAlign.center,
              ),
              const Spacer(),

              AppButton(
                label: _backToLoginText,
                onPressed: () => context.go('/auth/login'),
                isFullWidth: true,
                minHeight: AppTouchTarget.minSize,
              ),
              const SizedBox(height: AppSpacing.lg16),
            ],
          ),
        ),
      ),
    );
  }
}
