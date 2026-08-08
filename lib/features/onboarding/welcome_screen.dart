// PL-01b Welcome
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/onboarding_preferences.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../auth/auth_repository.dart';

/// Client-supplied redesign: one full-bleed composition (photo behind logo,
/// heading and card, no boxed sections, no scrolling), direct auth entry
/// points replacing the old "Get Started" → onboarding-slides gate. Both
/// routes are still wired up elsewhere (/onboarding/1, /interests) — only
/// this screen's entry points changed.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  // Bundled as an asset, not fetched over network: it's a fixed hero image
  // (not per-user or dynamic content), so there's no reason to pay a
  // network round-trip for it on every install. Light, cloud-wrapped peak,
  // chosen so dark text reads directly on the photo without a dark scrim.
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

  Future<void> _handleGuest() async {
    await OnboardingPreferences.markCompleted();
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      // Stack, not a Column with the photo in one Expanded slot: the photo
      // is the background for the *entire* screen — behind the status bar,
      // behind the logo — not a boxed region with its own edges. Everything
      // else layers on top of this one continuous image.
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(_heroImagePath, fit: BoxFit.cover),
          // Light wash only where text needs it (logo top, trust-badge
          // bottom) — the card has its own opaque white background, so the
          // gradient doesn't need to go opaque before reaching it, keeping
          // the photo visible behind the trust-badges row too.
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
                  child: Column(
                    children: [
                      const Icon(Icons.landscape_outlined, size: 38, color: AppColors.forest),
                      const SizedBox(height: 2),
                      const PlanELogo(fontSize: 24, color: AppColors.deep),
                      const SizedBox(height: 2),
                      Text(
                        'PLAN YOUR EXPERIENCE',
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 11,
                          color: AppColors.forest,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
                          // White with a dark drop shadow, not the earlier
                          // dark navy — dark text disappeared against the
                          // photo's dark rock patches. White+shadow reads
                          // reliably against both the light clouds and the
                          // dark rock.
                          Text(
                            'Experience\nNepal 🇳🇵',
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
                            'Curated journeys, authentic experiences and '
                            'memories that last a lifetime.',
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
                  // Rounded on every side and inset with margin, not flush
                  // to the screen edges with only top corners rounded — a
                  // true floating card, not a bottom sheet.
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
                        onPressed: () => context.go('/auth/sign-up'),
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
                        onPressed: () => context.go('/auth/sign-up'),
                      ),
                      const SizedBox(height: 7),
                      AppButton.text(
                        label: 'Continue as Guest',
                        isFullWidth: true,
                        minHeight: 42,
                        onPressed: _handleGuest,
                      ),
                    ],
                  ),
                ),
                Container(
                  // Transparent — the photo shows through the trust-badges
                  // row instead of sitting on its own white band.
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg16, vertical: AppSpacing.sm8),
                  child: const Row(
                    children: [
                      Expanded(
                        child: _TrustBadge(
                          icon: Icons.verified_user_outlined,
                          title: 'Secure & Safe',
                          subtitle: 'Your data is protected',
                        ),
                      ),
                      Expanded(
                        child: _TrustBadge(
                          icon: Icons.groups_outlined,
                          title: 'Local Experts',
                          subtitle: 'Curated by locals',
                        ),
                      ),
                      Expanded(
                        child: _TrustBadge(
                          icon: Icons.headset_mic_outlined,
                          title: '24/7 Support',
                          subtitle: "We're here anytime",
                        ),
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

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _TrustBadge({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.forest, size: 20),
        const SizedBox(height: 2),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.deep,
          ),
        ),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            fontSize: 11,
            color: AppColors.disabledText,
          ),
        ),
      ],
    );
  }
}
