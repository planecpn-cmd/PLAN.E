// PL-20 Host Application Submitted Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'host_provider.dart';

class ApplicationSubmittedScreen extends ConsumerWidget {
  const ApplicationSubmittedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hostData = ref.watch(hostApplicationProvider);

    return Scaffold(
      body: PlanEBackground(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.forest,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.forest.withValues(alpha: .18),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(Icons.check, color: AppColors.white, size: 40),
              ),
              const SizedBox(height: 18),
              const Text(
                'Application Submitted!',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.forest,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'We’ve received your host application.\nOur team in Nepal will review your details and documents.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: AppColors.disabledText, height: 1.45),
              ),
              const SizedBox(height: 20),

              // Status Timeline Card
              PlanECard(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Application Status',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.forest,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _StatusTimeline(),
                    const Divider(height: 24),
                    _DetailRow(
                      label: 'Host Name',
                      value: hostData.fullName.isNotEmpty ? hostData.fullName : 'Siddharth Gurung',
                    ),
                    _DetailRow(
                      label: 'District',
                      value: hostData.district,
                    ),
                    _DetailRow(
                      label: 'Listing Title',
                      value: hostData.experienceTitle.isNotEmpty
                          ? hostData.experienceTitle
                          : 'Kathmandu Valley Heritage Village Walk',
                    ),
                    _DetailRow(
                      label: 'Price',
                      value: AppFormatters.formatNpr(hostData.pricePaisa),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.eco_outlined, size: 36, color: AppColors.forest),
                  SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Most applications are reviewed within 3–5 business days. We’ll notify you when status updates.',
                      style: TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.disabledText),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              AppButton(
                label: 'BACK TO PROFILE',
                isFullWidth: true,
                onPressed: () => context.go('/profile'),
              ),
              const SizedBox(height: 10),
              AppButton(
                label: 'BACK TO HOME',
                variant: AppButtonVariant.secondary,
                isFullWidth: true,
                onPressed: () => context.go('/home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline();

  @override
  Widget build(BuildContext context) {
    const labels = ['Submitted', 'Under review', 'Verification', 'Approved'];
    return Column(
      children: List.generate(labels.length, (index) {
        final active = index == 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: active ? AppColors.forest : AppColors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: active ? AppColors.forest : AppColors.border, width: 2),
                ),
                child: active ? const Icon(Icons.check, color: AppColors.white, size: 14) : null,
              ),
              const SizedBox(width: 12),
              Text(
                labels[index],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  color: active ? AppColors.forest : AppColors.disabledText,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.disabledText),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}
