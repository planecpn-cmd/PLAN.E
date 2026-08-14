import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_toast.dart';
import 'auth_repository.dart';

/// Shared six-digit OTP screen for signup confirmation and password recovery.
/// Hosted email templates must include `{{ .Token }}` so users can enter the
/// token here; recovery links remain supported as a fallback.
class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String email;
  final bool isRecovery;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.isRecovery,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  Timer? _cooldownTimer;
  int _resendCooldown = 30;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _resendCooldown = 30;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendCooldown--;
        if (_resendCooldown <= 0) timer.cancel();
      });
    });
  }

  Future<void> _handleVerify() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(authNotifierProvider.notifier)
        .verifyOtp(
          email: widget.email,
          token: _codeController.text.trim(),
          isRecovery: widget.isRecovery,
        );

    if (!mounted) return;

    if (!success) {
      final state = ref.read(authNotifierProvider);
      AppToast.show(
        context,
        message:
            state.errorMessage ?? 'Invalid or expired code. Please try again.',
        variant: AppToastVariant.error,
      );
      return;
    }

    if (widget.isRecovery) {
      context.go('/auth/set-new-password');
      return;
    }

    AppToast.show(
      context,
      message: 'Email verified!',
      variant: AppToastVariant.success,
    );
    final deferred = ref.read(deferredActionProvider);
    final destination = deferredActionDestination(deferred);
    if (deferred != null) {
      ref.read(deferredActionProvider.notifier).clear();
    }
    context.go(destination);
  }

  Future<void> _handleResend() async {
    if (_resendCooldown > 0) return;
    final success = await ref
        .read(authNotifierProvider.notifier)
        .resendOtp(email: widget.email, isRecovery: widget.isRecovery);

    if (!mounted) return;

    if (success) {
      AppToast.show(
        context,
        message: 'Code resent to ${widget.email}',
        variant: AppToastVariant.success,
      );
      _startCooldown();
    } else {
      final state = ref.read(authNotifierProvider);
      AppToast.show(
        context,
        message: state.errorMessage ?? 'Failed to resend code.',
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
          'Verify Code',
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
                  widget.isRecovery
                      ? 'Reset Your Password'
                      : 'Verify Your Email',
                  style: AppTypography.headingLarge.copyWith(
                    color: AppColors.deep,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm8),
                Text(
                  'Enter the 6-digit code we sent to ${widget.email}.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl24),

                AppTextField(
                  label: 'Verification Code',
                  hint: '6-digit code',
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleVerify(),
                  prefixIcon: const Icon(
                    Icons.password_outlined,
                    color: AppColors.forest,
                  ),
                  validator: (val) {
                    final code = val?.trim() ?? '';
                    if (code.length != 6 || int.tryParse(code) == null) {
                      return 'Enter the 6-digit code from your email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg16),

                Align(
                  alignment: Alignment.centerRight,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: AppTouchTarget.minSize,
                      minHeight: AppTouchTarget.minSize,
                    ),
                    child: TextButton(
                      onPressed: _resendCooldown > 0 ? null : _handleResend,
                      child: Text(
                        _resendCooldown > 0
                            ? 'Resend code in ${_resendCooldown}s'
                            : 'Resend code',
                        style: AppTypography.bodyMedium.copyWith(
                          color: _resendCooldown > 0
                              ? AppColors.disabledText
                              : AppColors.gold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg16),

                AppButton(
                  label: 'Verify',
                  onPressed: authState.isLoading ? null : _handleVerify,
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
