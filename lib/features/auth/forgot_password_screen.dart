// RM-03 Forgot Password
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/format.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_toast.dart';
import 'auth_repository.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailPhoneController = TextEditingController();

  @override
  void dispose() {
    _emailPhoneController.dispose();
    super.dispose();
  }

  Future<void> _handleResetRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final input = _emailPhoneController.text.trim();
    final success = await ref.read(authNotifierProvider.notifier).resetPassword(input);

    if (!mounted) return;

    if (success) {
      context.go('/auth/reset-result');
    } else {
      final state = ref.read(authNotifierProvider);
      AppToast.show(
        context,
        message: state.errorMessage ?? 'Failed to send reset link. Please verify your email/phone.',
        variant: AppToastVariant.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        backgroundColor: AppColors.ivory,
        elevation: 0,
        title: Text(
          l10n.forgotPassword,
          style: AppTypography.headingMedium.copyWith(color: AppColors.forest),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.forgotPassword,
                  style: AppTypography.headingLarge.copyWith(color: AppColors.deep),
                ),
                const SizedBox(height: AppSpacing.sm8),
                Text(
                  l10n.forgotPasswordSubtitle,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
                ),
                const SizedBox(height: AppSpacing.xxl24),

                AppTextField(
                  label: l10n.emailOrPhoneLabel,
                  hint: 'e.g. name@example.com or 98XXXXXXXX',
                  controller: _emailPhoneController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.mark_email_read_outlined, color: AppColors.forest),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter an email or phone number';
                    }
                    final input = val.trim();
                    if (!input.contains('@') && !AppFormatters.isNepaliPhone(input)) {
                      return 'Enter a valid email or Nepali phone number (98XXXXXXXX)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xxl24),

                AppButton(
                  label: l10n.sendResetLink,
                  onPressed: authState.isLoading ? null : _handleResetRequest,
                  isLoading: authState.isLoading,
                  isFullWidth: true,
                  minHeight: AppTouchTarget.minSize,
                ),
                const SizedBox(height: AppSpacing.lg16),

                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: AppTouchTarget.minSize,
                      minHeight: AppTouchTarget.minSize,
                    ),
                    child: TextButton(
                      onPressed: () => context.go('/auth/login'),
                      child: Text(
                        'Back to Login',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.forest,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
