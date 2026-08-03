// PL-02 Onboarding Slide 1 / PL-03 Slide 2 / PL-04 Slide 3
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../widgets/app_button.dart';

class OnboardingSlideData {
  final String screenId;
  final String title;
  final String description;
  final IconData icon;

  const OnboardingSlideData({
    required this.screenId,
    required this.title,
    required this.description,
    required this.icon,
  });
}

class OnboardingSlideScreen extends StatefulWidget {
  final int step;

  const OnboardingSlideScreen({
    super.key,
    required this.step,
  });

  @override
  State<OnboardingSlideScreen> createState() => _OnboardingSlideScreenState();
}

class _OnboardingSlideScreenState extends State<OnboardingSlideScreen> {
  late PageController _pageController;

  static const List<OnboardingSlideData> _slides = [
    OnboardingSlideData(
      screenId: 'PL-02',
      title: 'Discover Authentic Nepal',
      description:
          'Explore hidden mountain villages, homestays, and community-led eco treks curated by local experts.',
      icon: Icons.explore_outlined,
    ),
    OnboardingSlideData(
      screenId: 'PL-03',
      title: 'Transparent & Local Pricing',
      description:
          'Clear NPR pricing in paisa, instant reservations, and offline-ready trip itineraries built for mountain connectivity.',
      icon: Icons.payments_outlined,
    ),
    OnboardingSlideData(
      screenId: 'PL-04',
      title: 'Empower Local Hosts',
      description:
          'Every booking directly supports indigenous hosts, homestay families, and sustainable high-altitude conservation.',
      icon: Icons.volunteer_activism_outlined,
    ),
  ];

  static const String _skipText = 'Skip';
  static const String _nextText = 'Next';
  static const String _getStartedText = 'Select Interests';

  @override
  void initState() {
    super.initState();
    final initialIndex = (widget.step - 1).clamp(0, _slides.length - 1);
    _pageController = PageController(initialPage: initialIndex);
  }

  @override
  void didUpdateWidget(covariant OnboardingSlideScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step != widget.step) {
      final targetPage = (widget.step - 1).clamp(0, _slides.length - 1);
      if (_pageController.hasClients && _pageController.page?.round() != targetPage) {
        _pageController.animateToPage(
          targetPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    final newStep = index + 1;
    if (newStep != widget.step) {
      context.go('/onboarding/$newStep');
    }
  }

  void _onNextPressed() {
    final currentStep = widget.step;
    if (currentStep < _slides.length) {
      context.go('/onboarding/${currentStep + 1}');
    } else {
      context.go('/interests');
    }
  }

  void _onSkipPressed() {
    context.go('/interests');
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = (widget.step - 1).clamp(0, _slides.length - 1);
    final isLastStep = currentIndex == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        backgroundColor: AppColors.ivory,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: AppTouchTarget.minSize, minHeight: AppTouchTarget.minSize),
            child: TextButton(
              onPressed: _onSkipPressed,
              child: Text(
                _skipText,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: AppSpacing.screenPadding,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Card container for illustration / icon
                        Container(
                          width: 200.0,
                          height: 200.0,
                          decoration: BoxDecoration(
                            color: AppColors.sage,
                            borderRadius: AppRadii.borderLg24,
                            border: Border.all(
                              color: AppColors.borderSubtle,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            slide.icon,
                            size: 96.0,
                            color: AppColors.forest,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxxl32),
                        Text(
                          slide.title,
                          style: AppTypography.headingLarge.copyWith(
                            color: AppColors.deep,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md12),
                        Text(
                          slide.description,
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.ink,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom control section with page dots & action button
            Padding(
              padding: AppSpacing.screenPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 3 Slide Page Dots Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs4),
                        width: index == currentIndex ? 24.0 : 8.0,
                        height: 8.0,
                        decoration: BoxDecoration(
                          color: index == currentIndex ? AppColors.forest : AppColors.border,
                          borderRadius: AppRadii.borderPill,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl24),

                  // Primary Next / Select Interests Button with min height 48dp
                  AppButton(
                    label: isLastStep ? _getStartedText : _nextText,
                    onPressed: _onNextPressed,
                    isFullWidth: true,
                    minHeight: AppTouchTarget.minSize,
                  ),
                  const SizedBox(height: AppSpacing.lg16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
