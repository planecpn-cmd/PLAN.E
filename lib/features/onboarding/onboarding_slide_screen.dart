// PL-02 Onboarding Slide 1 / PL-03 Slide 2 / PL-04 Slide 3
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

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

/// Overrides title/description from `remote_content.onboarding_slides` (a
/// JSON array in the same order as [defaults]) when present. Icon and slide
/// count stay fixed — only the copy is remote-editable, per
/// docs/OTA_UPDATES_PLAN.md §1.5 (icons aren't a CMS-friendly slot; the page
/// dots/pager logic assumes a fixed slide count). A missing entry, a short
/// array, or a non-string field all fall back to the local default for that
/// field individually — never blank, never a crash. Pulled out of the widget
/// so this branching is testable without pumping a widget tree.
List<OnboardingSlideData> resolveOnboardingSlides(
  List<OnboardingSlideData> defaults,
  dynamic remote,
) {
  if (remote is! List) return defaults;

  return List.generate(defaults.length, (i) {
    final base = defaults[i];
    if (i >= remote.length || remote[i] is! Map) return base;
    final entry = Map<String, dynamic>.from(remote[i] as Map);
    final title = entry['title'] as String?;
    final description = entry['description'] as String?;
    return OnboardingSlideData(
      screenId: base.screenId,
      title: (title != null && title.isNotEmpty) ? title : base.title,
      description: (description != null && description.isNotEmpty)
          ? description
          : base.description,
      icon: base.icon,
    );
  });
}

class OnboardingSlideScreen extends ConsumerStatefulWidget {
  final int step;

  const OnboardingSlideScreen({
    super.key,
    required this.step,
  });

  @override
  ConsumerState<OnboardingSlideScreen> createState() => _OnboardingSlideScreenState();
}

class _OnboardingSlideScreenState extends ConsumerState<OnboardingSlideScreen> {
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

  List<OnboardingSlideData> _effectiveSlides() {
    return resolveOnboardingSlides(
      _slides,
      ref.watch(remoteContentProvider('onboarding_slides')),
    );
  }

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
    final slides = _effectiveSlides();
    final currentIndex = (widget.step - 1).clamp(0, slides.length - 1);
    final isLastStep = currentIndex == slides.length - 1;

    return Scaffold(
      body: PlanEBackground(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 48), // Spacer to balance Skip button
                const PlanELogo(fontSize: 28),
                TextButton(
                  onPressed: _onSkipPressed,
                  child: Text(
                    _skipText,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: slides.length,
                itemBuilder: (context, index) {
                  final slide = slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 180.0,
                          height: 180.0,
                          decoration: BoxDecoration(
                            color: AppColors.sage.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.gold,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            slide.icon,
                            size: 80.0,
                            color: AppColors.forest,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          slide.title,
                          style: AppTypography.headingLarge.copyWith(
                            color: AppColors.deep,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                slides.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: index == currentIndex ? 24.0 : 8.0,
                  height: 8.0,
                  decoration: BoxDecoration(
                    color: index == currentIndex ? AppColors.forest : AppColors.border,
                    borderRadius: AppRadii.borderPill,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: isLastStep ? _getStartedText : _nextText,
              onPressed: _onNextPressed,
              isFullWidth: true,
              minHeight: AppTouchTarget.minSize,
            ),
          ],
        ),
      ),
    );
  }
}
