// PL-18 Become a Host Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'host_provider.dart';

class BecomeHostScreen extends ConsumerWidget {
  const BecomeHostScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).asData?.value;
    final hostData = ref.watch(hostApplicationProvider);

    const benefits = [
      (Icons.attach_money, 'Earn extra\nincome'),
      (Icons.calendar_month_outlined, 'Flexible\nschedule'),
      (Icons.language, 'Reach global\ntravelers'),
      (Icons.support_agent, 'Full support\nfrom PLAN E'),
    ];

    return Scaffold(
      body: PlanEBackground(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.ink),
                    onPressed: () => context.pop(),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Become a Host',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.forest,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 12),
              const Center(
                child: Column(
                  children: [
                    Text(
                      'Share Nepal. Create unforgettable journeys.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.forest,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Turn your local knowledge into experiences travelers will remember.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.disabledText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Why host with PLAN E',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.forest,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: List.generate(benefits.length, (index) {
                  final benefit = benefits[index];
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index == benefits.length - 1 ? 0 : 6,
                      ),
                      child: PlanECard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 12,
                        ),
                        child: Column(
                          children: [
                            Icon(benefit.$1, size: 26, color: AppColors.forest),
                            const SizedBox(height: 8),
                            Text(
                              benefit.$2,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11,
                                height: 1.2,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 18),
              const Text(
                'How it works',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.forest,
                ),
              ),
              const SizedBox(height: 10),
              const Row(
                children: [
                  Expanded(
                    child: _ProcessStep(number: '1', label: 'Apply'),
                  ),
                  _StepLine(),
                  Expanded(
                    child: _ProcessStep(number: '2', label: 'Get verified'),
                  ),
                  _StepLine(),
                  Expanded(
                    child: _ProcessStep(number: '3', label: 'List experience'),
                  ),
                  _StepLine(),
                  Expanded(
                    child: _ProcessStep(number: '4', label: 'Start hosting'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const PlanECard(
                padding: EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.sage,
                      child: Icon(
                        Icons.landscape_outlined,
                        color: AppColors.forest,
                        size: 28,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '“Hosting connected me with travelers from 20+ countries.”',
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontStyle: FontStyle.italic,
                              fontSize: 14,
                              color: AppColors.forest,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '— Pemba, Trekking Guide in Solukhumbu',
                            style: TextStyle(
                              color: AppColors.disabledText,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: hostData.status == 'under_review'
                    ? 'VIEW SUBMITTED STATUS'
                    : 'START YOUR APPLICATION',
                icon: Icons.arrow_forward,
                isFullWidth: true,
                onPressed: () {
                  if (ref.read(supabaseClientProvider).auth.currentUser ==
                      null) {
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
                  if (profile?.role.name == 'hostApplicant' ||
                      hostData.status == 'under_review') {
                    context.push('/host/submitted');
                  } else {
                    context.push('/host/step-1');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProcessStep extends StatelessWidget {
  final String number;
  final String label;

  const _ProcessStep({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
            color: AppColors.white,
          ),
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.gold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            height: 1.1,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 1,
      margin: const EdgeInsets.only(bottom: 24),
      color: AppColors.sage,
    );
  }
}
