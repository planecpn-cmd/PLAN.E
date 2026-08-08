// RM-01 Sign Up
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/format.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/brand_icons.dart';
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailPhoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    final l10n = AppLocalizations.of(context)!;
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
      // Email confirmation is required (supabase/config.toml auth.email
      // .enable_confirmations), so signUp() succeeding does not yet mean a
      // session exists — verify the OTP that was just emailed before
      // treating the account as usable. Phone-only signups have no email to
      // send a code to, so they go straight through as before.
      final hasSession =
          ref.read(supabaseClientProvider).auth.currentSession != null;
      if (isEmail && !hasSession) {
        context.go('/auth/otp-verify', extra: {'email': email, 'purpose': 'signup'});
        return;
      }
      AppToast.show(context, message: l10n.accountCreatedSuccess, variant: AppToastVariant.success);
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

  Future<void> _handleOAuthSignIn(OAuthProvider provider) async {
    ref.read(oauthInFlightProvider.notifier).state = true;
    try {
      await ref.read(authNotifierProvider.notifier).signInWithOAuth(provider);
    } catch (e) {
      ref.read(oauthInFlightProvider.notifier).state = false;
      if (!mounted) return;
      AppToast.show(context, message: 'Could not open sign-in. Please try again.', variant: AppToastVariant.error);
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
                  'Create Your Account',
                  style: AppTypography.headingLarge.copyWith(color: AppColors.deep),
                ),
                const SizedBox(height: AppSpacing.sm8),
                Text(
                  l10n.signUpSubtitle,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
                ),
                const SizedBox(height: AppSpacing.xxl24),

                // Name input
                AppTextField(
                  label: l10n.fullName,
                  hint: 'Enter your full name',
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
                  label: l10n.emailOrPhoneLabel,
                  hint: 'e.g. name@example.com or 98XXXXXXXX',
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
                  label: l10n.passwordLabel,
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
                  label: l10n.confirmPasswordLabel,
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
                  label: l10n.createAccount,
                  onPressed: authState.isLoading ? null : _handleSignUp,
                  isLoading: authState.isLoading,
                  isFullWidth: true,
                  minHeight: AppTouchTarget.minSize,
                ),
                const SizedBox(height: AppSpacing.xxl24),

                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.borderSubtle)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md12),
                      child: Text(
                        'OR',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.borderSubtle)),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg16),

                AppButton.secondary(
                  label: 'Continue with Google',
                  iconWidget: const GoogleMark(),
                  isFullWidth: true,
                  minHeight: AppTouchTarget.minSize,
                  onPressed: () => _handleOAuthSignIn(OAuthProvider.google),
                ),
                const SizedBox(height: AppSpacing.sm8),
                if (isApplePlatform)
                  AppButton.secondary(
                    label: 'Continue with Apple',
                    // iconWidget, not icon: Apple's mark must stay black
                    // regardless of button variant, not tinted to match text.
                    iconWidget: const Icon(Icons.apple, size: 20.0, color: Colors.black),
                    isFullWidth: true,
                    minHeight: AppTouchTarget.minSize,
                    onPressed: () => _handleOAuthSignIn(OAuthProvider.apple),
                  ),
                const SizedBox(height: AppSpacing.xxl24),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
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
                          l10n.login,
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
