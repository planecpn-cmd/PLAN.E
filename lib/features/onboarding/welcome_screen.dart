// PL-01b Welcome
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/onboarding_preferences.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const String _heroImageUrl =
      'https://images.unsplash.com/photo-1544198365-f5d60b6d8190?auto=format&fit=crop&w=1200&q=80';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: Column(
        children: [
          Expanded(
            flex: 6,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(_heroImageUrl, fit: BoxFit.cover),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x59000000),
                        Color(0x0D000000),
                        Color(0x66000000),
                      ],
                    ),
                  ),
                ),
                const SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: PlanELogo(fontSize: 26, color: AppColors.white),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 5,
            child: PlanEBackground(
              safeArea: true,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Text(
                        'WELCOME TO PLAN E',
                        textAlign: TextAlign.center,
                        style: AppTypography.headingLarge.copyWith(
                          fontFamily: 'serif',
                          color: AppColors.deep,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm8),
                      Text(
                        'Plan your adventures. Experience Nepal.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl20),
                      const _DotsIndicator(activeIndex: 0, count: 3),
                    ],
                  ),
                  Column(
                    children: [
                      AppButton(
                        label: 'Get Started',
                        isFullWidth: true,
                        minHeight: AppTouchTarget.minSize,
                        onPressed: () => context.go('/onboarding/1'),
                      ),
                      const SizedBox(height: AppSpacing.md12),
                      TextButton(
                        onPressed: () => context.go('/auth/login'),
                        child: Text(
                          'I already have an account',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.forest,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await OnboardingPreferences.markCompleted();
                          if (context.mounted) context.go('/home');
                        },
                        child: Text(
                          'Continue as Guest',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.disabledText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  final int activeIndex;
  final int count;

  const _DotsIndicator({required this.activeIndex, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == activeIndex;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? AppColors.gold : AppColors.border,
            borderRadius: AppRadii.borderPill,
          ),
        );
      }),
    );
  }
}
