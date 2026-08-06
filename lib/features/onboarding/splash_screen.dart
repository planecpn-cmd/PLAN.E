// PL-01 Splash Screen
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../widgets/app_button.dart';
import '../../core/onboarding_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _nepalFadeAnimation;
  late Animation<double> _planEFadeAnimation;
  late Animation<double> _scaleAnimation;

  static const String _nepalText = 'NEPAL';
  static const String _taglineText = 'Authentic Nepal Experiences';
  static const String _getStartedText = 'Get Started';
  static const String _exploreAsGuestText = 'Explore as Guest';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _nepalFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _planEFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.8, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.9, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onGetStarted() {
    context.go('/onboarding/1');
  }

  Future<void> _onExploreAsGuest() async {
    await OnboardingPreferences.markCompleted();
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deep,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            children: [
              const Spacer(),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Transition badge/icon
                      Container(
                        width: 72.0,
                        height: 72.0,
                        decoration: BoxDecoration(
                          color: AppColors.forest,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.gold, width: 2.0),
                        ),
                        child: const Icon(
                          Icons.landscape_rounded,
                          color: AppColors.ivory,
                          size: 36.0,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl24),

                      // Brand Transition display
                      if (_controller.value < 0.45)
                        Opacity(
                          opacity: _nepalFadeAnimation.value,
                          child: Text(
                            _nepalText,
                            style: AppTypography.displayLarge.copyWith(
                              color: AppColors.gold,
                              letterSpacing: 4.0,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      else
                        Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Opacity(
                            opacity: _planEFadeAnimation.value,
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'PLAN ',
                                      style: AppTypography.displayLarge
                                          .copyWith(
                                            color: AppColors.ivory,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 2.0,
                                          ),
                                    ),
                                    Text(
                                      'E',
                                      style: AppTypography.displayLarge
                                          .copyWith(
                                            color: AppColors.gold,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 2.0,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm8),
                                Text(
                                  _taglineText,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.sage,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const Spacer(),

              // Action buttons with >= 48dp touch targets
              AppButton(
                label: _getStartedText,
                onPressed: _onGetStarted,
                isFullWidth: true,
                minHeight: AppTouchTarget.minSize,
              ),
              const SizedBox(height: AppSpacing.md12),
              AppButton.secondary(
                label: _exploreAsGuestText,
                onPressed: _onExploreAsGuest,
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
