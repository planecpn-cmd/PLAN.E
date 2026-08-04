// RM-01 Sign Up
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/format.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_toast.dart';
import 'auth_repository.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  static const String _titleText = 'Create Your Account';
  static const String _subtitleText = 'Join PLAN E to book authentic experiences across Nepal.';
  static const String _nameLabel = 'Full Name';
  static const String _nameHint = 'Enter your full name';
  static const String _emailPhoneLabel = 'Email or Phone Number';
  static const String _emailPhoneHint = 'e.g. name@example.com or 98XXXXXXXX';
  static const String _passwordLabel = 'Password';
  static const String _passwordHint = 'At least 6 characters';
  static const String _confirmPasswordLabel = 'Confirm Password';
  static const String _confirmPasswordHint = 'Re-enter your password';
  static const String _signUpButtonText = 'Create Account';
  static const String _hasAccountText = 'Already have an account?';
  static const String _loginText = 'Log In';

  @override
  void dispose() {
    _nameController.dispose();
    _emailPhoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final emailOrPhone = _emailPhoneController.text.trim();
    final password = _passwordController.text;

    final isEmail = emailOrPhone.contains('@');
    final email = isEmail ? emailOrPhone : '';
    final phone = isEmail ? null : emailOrPhone;

    final success = await ref.read(authNotifierProvider.notifier).signUp(
          email: email,
          password: password,
          fullName: name,
          phone: phone,
        );

    if (!mounted) return;

    if (success) {
      AppToast.show(context, message: 'Account created successfully!', variant: AppToastVariant.success);
      final deferred = ref.read(deferredActionProvider);
      if (deferred != null) {
        ref.read(deferredActionProvider.notifier).clear();
      }
      context.go('/home');
    } else {
      final state = ref.read(authNotifierProvider);
      AppToast.show(
        context,
        message: state.errorMessage ?? 'Failed to create account. Please try again.',
        variant: AppToastVariant.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authNotifierProvider);
    final deferredAction = ref.watch(deferredActionProvider);

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        backgroundColor: AppColors.ivory,
        elevation: 0,
        title: Text(
          l10n.signUp,
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
                if (deferredAction != null) ...[
                  Container(
                    width: double.infinity,
                    padding: AppSpacing.paddingMd12,
                    decoration: const BoxDecoration(
                      color: AppColors.warningContainer,
                      borderRadius: AppRadii.borderSm8,
                    ),
                    child: Text(
                      'Sign up required to complete: ${deferredAction.action}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg16),
                ],
                Text(
                  _titleText,
                  style: AppTypography.headingLarge.copyWith(color: AppColors.deep),
                ),
                const SizedBox(height: AppSpacing.sm8),
                Text(
                  _subtitleText,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
                ),
                const SizedBox(height: AppSpacing.xxl24),

                // Name input
                AppTextField(
                  label: _nameLabel,
                  hint: _nameHint,
                  controller: _nameController,
                  prefixIcon: const Icon(Icons.person_outline, color: AppColors.forest),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg16),

                // Email / Phone input
                AppTextField(
                  label: _emailPhoneLabel,
                  hint: _emailPhoneHint,
                  controller: _emailPhoneController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.contact_mail_outlined, color: AppColors.forest),
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
                const SizedBox(height: AppSpacing.lg16),

                // Password input
                AppTextField(
                  label: _passwordLabel,
                  hint: _passwordHint,
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.forest),
                  suffixIcon: IconButton(
                    constraints: AppTouchTarget.minConstraints,
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.forest,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (val) {
                    if (val == null || val.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg16),

                // Confirm Password input
                AppTextField(
                  label: _confirmPasswordLabel,
                  hint: _confirmPasswordHint,
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.forest),
                  suffixIcon: IconButton(
                    constraints: AppTouchTarget.minConstraints,
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.forest,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  validator: (val) {
                    if (val != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xxl24),

                // Submit Button
                AppButton(
                  label: _signUpButtonText,
                  onPressed: authState.isLoading ? null : _handleSignUp,
                  isLoading: authState.isLoading,
                  isFullWidth: true,
                  minHeight: AppTouchTarget.minSize,
                ),
                const SizedBox(height: AppSpacing.xxl24),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _hasAccountText,
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: AppTouchTarget.minSize,
                        minHeight: AppTouchTarget.minSize,
                      ),
                      child: TextButton(
                        onPressed: () => context.go('/auth/login'),
                        child: Text(
                          _loginText,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.gold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
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
