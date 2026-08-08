import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_toast.dart';
import 'auth_repository.dart';

/// Reached after a successful recovery OTP verification, which already
/// leaves the user signed in on a recovery session — this screen only sets
/// the new password on it.
class SetNewPasswordScreen extends ConsumerStatefulWidget {
  const SetNewPasswordScreen({super.key});

  @override
  ConsumerState<SetNewPasswordScreen> createState() =>
      _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends ConsumerState<SetNewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(authNotifierProvider.notifier)
        .updatePassword(_passwordController.text);

    if (!mounted) return;

    if (success) {
      AppToast.show(context, message: 'Password updated!', variant: AppToastVariant.success);
      context.go('/home');
    } else {
      final state = ref.read(authNotifierProvider);
      AppToast.show(
        context,
        message: state.errorMessage ?? 'Failed to update password. Please try again.',
        variant: AppToastVariant.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        backgroundColor: AppColors.ivory,
        elevation: 0,
        title: Text(
          'New Password',
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
                  'Set a New Password',
                  style: AppTypography.headingLarge.copyWith(color: AppColors.deep),
                ),
                const SizedBox(height: AppSpacing.sm8),
                Text(
                  'Your new password must be different from your previous one.',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
                ),
                const SizedBox(height: AppSpacing.xxl24),

                AppTextField(
                  label: 'New Password',
                  hint: 'At least 6 characters',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.forest),
                  suffixIcon: IconButton(
                    constraints: AppTouchTarget.minConstraints,
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.forest,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (val) {
                    if (val == null || val.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg16),

                AppTextField(
                  label: 'Confirm New Password',
                  hint: 'Re-enter your password',
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.forest),
                  suffixIcon: IconButton(
                    constraints: AppTouchTarget.minConstraints,
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.forest,
                    ),
                    onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                  ),
                  validator: (val) {
                    if (val != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xxl24),

                AppButton(
                  label: 'Update Password',
                  onPressed: authState.isLoading ? null : _handleSubmit,
                  isLoading: authState.isLoading,
                  isFullWidth: true,
                  minHeight: AppTouchTarget.minSize,
                ),
                const SizedBox(height: AppSpacing.lg16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
