// PL-18 Become a Host landing screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/host_application.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

class BecomeHostScreen extends ConsumerWidget {
  const BecomeHostScreen({super.key});

  static const _categories = [
    (Icons.hiking_outlined, 'Adventure'),
    (Icons.home_outlined, 'Stay'),
    (Icons.auto_awesome_outlined, 'Experience'),
    (Icons.map_outlined, 'Tours'),
    (Icons.groups_outlined, 'Community'),
  ];
  static const _benefits = [
    (
      Icons.travel_explore_outlined,
      'Reach travellers',
      'Get discovered by people looking for meaningful experiences.',
    ),
    (
      Icons.calendar_month_outlined,
      'Manage bookings',
      'Keep requests and availability organised.',
    ),
    (
      Icons.trending_up_outlined,
      'Grow with Plan E',
      'Build trust through quality experiences and reviews.',
    ),
  ];
  static const _steps = [
    ('01', 'Apply', 'Tell us about yourself and what you want to host.'),
    ('02', 'Get verified', 'Plan E reviews your host application.'),
    (
      '03',
      'Start hosting',
      'Create listings after your host profile is approved.',
    ),
  ];

  void _continue(BuildContext context, WidgetRef ref, _HostCta cta) {
    if (ref.read(supabaseClientProvider).auth.currentUser == null) {
      ref
          .read(deferredActionProvider.notifier)
          .setPending(
            const DeferredAction(
              screenId: 'HOST_APPLICATION',
              action: 'register as a PLAN E host',
            ),
          );
      context.push('/auth/required');
      return;
    }
    context.push(cta.route);
  }

  _HostCta _cta(HostApplication? application, String? role) {
    if (role == 'host' || application?.status == HostAppStatus.approved) {
      return const _HostCta('Go to Host Dashboard', '/host/dashboard');
    }
    switch (application?.status) {
      case HostAppStatus.submitted:
      case HostAppStatus.underReview:
      case HostAppStatus.verification:
        return const _HostCta('View Application Status', '/host/submitted');
      case HostAppStatus.draft:
      case HostAppStatus.actionRequired:
      case HostAppStatus.rejected:
        return _HostCta(
          'Continue Application',
          '/host/application/${application?.currentStep ?? 1}',
        );
      case HostAppStatus.approved:
        return const _HostCta('Go to Host Dashboard', '/host/dashboard');
      case null:
        return const _HostCta('Start Host Application', '/host/application/1');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).asData?.value;
    final application = ref.watch(myHostApplicationProvider);
    final cta = _cta(application.asData?.value, profile?.role.name);

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Hero(onBack: () => context.pop())),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 40),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionTitle('What can you host?'),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 42,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) => _CategoryChip(
                            icon: _categories[index].$1,
                            label: _categories[index].$2,
                          ),
                        ),
                      ),
                      const _SectionGap(),
                      const _SectionTitle('Why host with Plan E?'),
                      const SizedBox(height: 16),
                      ..._benefits.map(
                        (benefit) => _BenefitRow(
                          icon: benefit.$1,
                          title: benefit.$2,
                          description: benefit.$3,
                        ),
                      ),
                      const _SectionGap(),
                      const _SectionTitle('How it works'),
                      const SizedBox(height: 12),
                      ..._steps.map(
                        (step) => _ProcessStep(
                          number: step.$1,
                          title: step.$2,
                          description: step.$3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: AppColors.sage,
                          borderRadius: AppRadii.borderMd16,
                        ),
                        child: Row(
                          children: [
                            const ExcludeSemantics(
                              child: Icon(
                                Icons.verified_user_outlined,
                                color: AppColors.forest,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Hosts are verified by Plan E before publishing.',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.forest,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            color: AppColors.ivory,
            border: Border(top: BorderSide(color: AppColors.borderSubtle)),
          ),
          child: Align(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: AppButton(
                label: cta.label,
                icon: Icons.arrow_forward,
                isFullWidth: true,
                borderRadius: AppRadii.borderPill,
                isLoading: application.isLoading,
                onPressed: () => _continue(context, ref, cta),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final VoidCallback onBack;
  const _Hero({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final height = (MediaQuery.sizeOf(context).height * .44).clamp(
      320.0,
      440.0,
    );
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Semantics(
            image: true,
            label: 'A Nepalese pottery host shaping a clay vessel',
            child: Image.asset(
              'assets/images/photo_11052970.webp',
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.25),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x12000000), Color(0xCC01251C)],
                stops: [0.35, 1],
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton.filledTonal(
                  tooltip: 'Back',
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    backgroundColor: AppColors.ivory.withValues(alpha: .92),
                    foregroundColor: AppColors.forest,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BECOME A HOST',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.ivory,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Share what you know.\nHost with Plan E.',
                  style: AppTypography.displayLarge.copyWith(
                    fontFamily: 'serif',
                    color: AppColors.ivory,
                    height: 1.08,
                    shadows: const [
                      Shadow(blurRadius: 12, color: Colors.black54),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Turn your knowledge, place or passion into an experience travellers can discover.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.ivory,
                    height: 1.4,
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

class _HostCta {
  final String label;
  final String route;
  const _HostCta(this.label, this.route);
}

class _SectionGap extends StatelessWidget {
  const _SectionGap();
  @override
  Widget build(BuildContext context) => const SizedBox(height: 32);
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTypography.headingMedium.copyWith(
      fontFamily: 'serif',
      color: AppColors.forest,
    ),
  );
}

class _CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _CategoryChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: const BoxDecoration(
      color: AppColors.sage,
      borderRadius: AppRadii.borderPill,
    ),
    child: Row(
      children: [
        ExcludeSemantics(child: Icon(icon, size: 18, color: AppColors.forest)),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.forest,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.description,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.sage,
              borderRadius: AppRadii.borderSm8,
            ),
            child: Icon(icon, size: 22, color: AppColors.forest),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.forest,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(description, style: AppTypography.bodyMedium),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ProcessStep extends StatelessWidget {
  final String number;
  final String title;
  final String description;
  const _ProcessStep({
    required this.number,
    required this.title,
    required this.description,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 42,
          child: Text(
            number,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.gold,
              fontWeight: FontWeight.w800,
              letterSpacing: .8,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.forest,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(description, style: AppTypography.bodyMedium),
            ],
          ),
        ),
      ],
    ),
  );
}
