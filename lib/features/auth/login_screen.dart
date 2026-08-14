// RM-02 Login
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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    final emailOrPhone = _emailPhoneController.text.trim();
    final password = _passwordController.text;

    final success = await ref
        .read(authNotifierProvider.notifier)
        .signIn(emailOrPhone: emailOrPhone, password: password);

    if (!mounted) return;

    if (success) {
      AppToast.show(
        context,
        message: l10n.loggedInSuccess,
        variant: AppToastVariant.success,
      );
      final deferred = ref.read(deferredActionProvider);
      final destination = deferredActionDestination(deferred);
      if (deferred != null) {
        ref.read(deferredActionProvider.notifier).clear();
      }
      context.go(destination);
    } else {
      final state = ref.read(authNotifierProvider);
      AppToast.show(
        context,
        message:
            state.errorMessage ??
            'Invalid email/phone or password. Please try again.',
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
      AppToast.show(
        context,
        message: 'Could not open sign-in. Please try again.',
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
          l10n.login,
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
                      'Log in required to complete: ${deferredAction.action}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg16),
                ],
                Text(
                  l10n.welcomeBack,
                  style: AppTypography.headingLarge.copyWith(
                    color: AppColors.deep,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm8),
                Text(
                  l10n.loginSubtitle,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl24),

                // Email or Phone field
                AppTextField(
                  label: l10n.emailOrPhoneLabel,
                  hint: 'e.g. name@example.com or 98XXXXXXXX',
                  controller: _emailPhoneController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(
                    Icons.contact_mail_outlined,
                    color: AppColors.forest,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter an email or phone number';
                    }
                    final input = val.trim();
                    if (!input.contains('@') &&
                        !AppFormatters.isNepaliPhone(input)) {
                      return 'Enter a valid email or Nepali phone number (98XXXXXXXX)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg16),

                // Password field
                AppTextField(
                  label: l10n.passwordLabel,
                  hint: 'Enter your password',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: AppColors.forest,
                  ),
                  suffixIcon: IconButton(
                    constraints: AppTouchTarget.minConstraints,
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.forest,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.sm8),

                // Forgot Password link
                Align(
                  alignment: Alignment.centerRight,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: AppTouchTarget.minSize,
                      minHeight: AppTouchTarget.minSize,
                    ),
                    child: TextButton(
                      onPressed: () => context.go('/auth/forgot-password'),
                      child: Text(
                        l10n.forgotPassword,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg16),

                // Submit Button
                AppButton(
                  label: l10n.login,
                  onPressed: authState.isLoading ? null : _handleLogin,
                  isLoading: authState.isLoading,
                  isFullWidth: true,
                  minHeight: AppTouchTarget.minSize,
                ),
                const SizedBox(height: AppSpacing.xxl24),

                Row(
                  children: [
                    const Expanded(
                      child: Divider(color: AppColors.borderSubtle),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md12,
                      ),
                      child: Text(
                        'OR',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Divider(color: AppColors.borderSubtle),
                    ),
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
                if (isApplePlatform) ...[
                  AppButton.secondary(
                    label: 'Continue with Apple',
                    // iconWidget, not icon: Apple's mark must stay black
                    // regardless of button variant, not tinted to match text.
                    iconWidget: const Icon(
                      Icons.apple,
                      size: 20.0,
                      color: Colors.black,
                    ),
                    isFullWidth: true,
                    minHeight: AppTouchTarget.minSize,
                    onPressed: () => _handleOAuthSignIn(OAuthProvider.apple),
                  ),
                ],
                const SizedBox(height: AppSpacing.xxl24),

                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.dontHaveAccount,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.ink,
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: AppTouchTarget.minSize,
                        minHeight: AppTouchTarget.minSize,
                      ),
                      child: TextButton(
                        onPressed: () => context.go('/auth/sign-up'),
                        child: Text(
                          l10n.signUp,
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
