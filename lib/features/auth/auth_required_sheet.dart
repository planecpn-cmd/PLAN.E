// RM-05 Authentication Required
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'auth_repository.dart';

/// Mirrors WelcomeScreen's full-bleed photo + floating card + every sign-in
/// method, rather than the old plain Login/Create Account pair — a user
/// blocked mid-action (e.g. saving a favorite as a guest) should see the same
/// sign-in surface they'd see at first launch, not a visually different one.
class AuthRequiredSheet extends ConsumerStatefulWidget {
  const AuthRequiredSheet({super.key});

  @override
  ConsumerState<AuthRequiredSheet> createState() => _AuthRequiredSheetState();
}

class _AuthRequiredSheetState extends ConsumerState<AuthRequiredSheet> {
  static const String _heroImagePath = 'assets/images/welcome_hero.jpg';

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

  void _dismiss() {
    ref.read(deferredActionProvider.notifier).clear();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final deferredAction = ref.watch(deferredActionProvider);
    final actionDescription = deferredAction?.action ?? 'proceed with this feature';

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(_heroImagePath, fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66FFFFFF),
                  Color(0x00FFFFFF),
                  Color(0x00FFFFFF),
                  Color(0x4DFFFFFF),
                ],
                stops: [0.0, 0.18, 0.75, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppColors.forest),
                        onPressed: _dismiss,
                      ),
                      const Expanded(
                        child: PlanELogo(fontSize: 22, color: AppColors.deep),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Sign In\nRequired',
                            style: AppTypography.headingLarge.copyWith(
                              fontFamily: 'serif',
                              color: AppColors.white,
                              height: 1.1,
                              fontSize: 30,
                              shadows: const [
                                Shadow(color: Color(0x99000000), blurRadius: 12, offset: Offset(0, 2)),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs4),
                          Container(width: 36, height: 3, color: AppColors.gold),
                          const SizedBox(height: AppSpacing.sm8),
                          Text(
                            'Create a free account or log in to $actionDescription.',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.white,
                              shadows: const [
                                Shadow(color: Color(0x99000000), blurRadius: 8, offset: Offset(0, 1)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppRadii.borderLg24,
                    boxShadow: [
                      BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 8)),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(32, 24, 32, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppButton(
                        label: 'Continue with Phone',
                        icon: Icons.call_outlined,
                        isFullWidth: true,
                        minHeight: 47,
                        borderRadius: AppRadii.borderPill,
                        onPressed: () => context.push('/auth/sign-up'),
                      ),
                      const SizedBox(height: 7),
                      AppButton.secondary(
                        label: 'Continue with Google',
                        iconWidget: const GoogleMark(),
                        isFullWidth: true,
                        minHeight: 47,
                        borderRadius: AppRadii.borderPill,
                        onPressed: () => _handleOAuthSignIn(OAuthProvider.google),
                      ),
                      if (isApplePlatform) ...[
                        const SizedBox(height: 7),
                        AppButton.secondary(
                          label: 'Continue with Apple',
                          iconWidget: const Icon(Icons.apple, size: 20.0, color: Colors.black),
                          isFullWidth: true,
                          minHeight: 47,
                          borderRadius: AppRadii.borderPill,
                          onPressed: () => _handleOAuthSignIn(OAuthProvider.apple),
                        ),
                      ],
                      const SizedBox(height: 11),
                      Row(
                        children: [
                          const Expanded(child: Divider(color: AppColors.borderSubtle)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md12),
                            child: Text(
                              'or continue with email',
                              style: AppTypography.bodyMedium.copyWith(
                                fontSize: 12,
                                color: AppColors.disabledText,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider(color: AppColors.borderSubtle)),
                        ],
                      ),
                      const SizedBox(height: 11),
                      AppButton.secondary(
                        label: 'Continue with Email',
                        icon: Icons.mail_outline,
                        isFullWidth: true,
                        minHeight: 47,
                        borderRadius: AppRadii.borderPill,
                        onPressed: () => context.push('/auth/sign-up'),
                      ),
                      const SizedBox(height: 7),
                      AppButton.text(
                        label: 'Not Now',
                        isFullWidth: true,
                        minHeight: 42,
                        onPressed: _dismiss,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
