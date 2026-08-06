// PL-20 Host Application Submitted Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../models/host_application.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'host_provider.dart';

class ApplicationSubmittedScreen extends ConsumerWidget {
  const ApplicationSubmittedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncApp = ref.watch(myHostApplicationProvider);
    final hostData = ref.watch(hostApplicationProvider);

    return Scaffold(
      body: PlanEBackground(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: AsyncValueView<HostApplication?>(
          value: asyncApp,
          onRetry: () => ref.refresh(myHostApplicationProvider),
          data: (realApp) {
            final HostAppStatus appStatus = realApp?.status ??
                HostAppStatus.fromString(hostData.status);

            final String hostName = hostData.fullName.isNotEmpty
                ? hostData.fullName
                : 'Siddharth Gurung';
            final String district = realApp?.location ??
                (hostData.district.isNotEmpty ? hostData.district : 'Kathmandu');
            final String listingTitle = realApp?.title ??
                (hostData.experienceTitle.isNotEmpty
                    ? hostData.experienceTitle
                    : 'Kathmandu Valley Heritage Village Walk');
            final int pricePaisa = hostData.pricePaisa;

            return SingleChildScrollView(
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
                    style: TextStyle(
                      fontSize: 13.5,
                      color: AppColors.disabledText,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Live Status Timeline Card
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
                        _LiveStatusTimeline(status: appStatus),
                        const Divider(height: 24),
                        _DetailRow(
                          label: 'Host Name',
                          value: hostName,
                        ),
                        _DetailRow(
                          label: 'District',
                          value: district,
                        ),
                        _DetailRow(
                          label: 'Listing Title',
                          value: listingTitle,
                        ),
                        _DetailRow(
                          label: 'Price',
                          value: AppFormatters.formatNpr(pricePaisa),
                        ),
                        if (realApp?.submittedAt != null)
                          _DetailRow(
                            label: 'Submitted On',
                            value: AppFormatters.formatTripDate(realApp!.submittedAt!),
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
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: AppColors.disabledText,
                          ),
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
            );
          },
        ),
      ),
    );
  }
}

class _LiveStatusTimeline extends StatelessWidget {
  final HostAppStatus status;

  const _LiveStatusTimeline({required this.status});

  int get _activeStepIndex {
    switch (status) {
      case HostAppStatus.submitted:
        return 0;
      case HostAppStatus.underReview:
        return 1;
      case HostAppStatus.verification:
        return 2;
      case HostAppStatus.approved:
        return 3;
      case HostAppStatus.rejected:
        return -1;
      case HostAppStatus.draft:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (status == HostAppStatus.rejected) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.errorContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Application needs revision or rejected. Please contact support.',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final activeIndex = _activeStepIndex;
    const steps = [
      {'title': 'Submitted', 'desc': 'Application received'},
      {'title': 'Under Review', 'desc': 'Details & listing checked'},
      {'title': 'Verification', 'desc': 'ID document verification'},
      {'title': 'Approved', 'desc': 'Host account activated'},
    ];

    return Column(
      children: List.generate(steps.length, (index) {
        final isPassed = index < activeIndex;
        final isCurrent = index == activeIndex;
        final isLast = index == steps.length - 1;

        final Color stepColor = (isPassed || isCurrent)
            ? AppColors.forest
            : AppColors.disabledText;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: (isPassed || isCurrent)
                        ? AppColors.forest
                        : AppColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (isPassed || isCurrent)
                          ? AppColors.forest
                          : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: isPassed
                      ? const Icon(Icons.check, color: AppColors.white, size: 14)
                      : isCurrent
                          ? const Icon(Icons.circle, color: AppColors.white, size: 10)
                          : null,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 24,
                    color: isPassed ? AppColors.forest : AppColors.border,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      steps[index]['title']!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            (isPassed || isCurrent) ? FontWeight.bold : FontWeight.normal,
                        color: stepColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      steps[index]['desc']!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isCurrent
                            ? AppColors.forest
                            : AppColors.disabledText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.disabledText),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
