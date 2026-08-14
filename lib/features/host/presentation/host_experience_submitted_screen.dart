import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/theme.dart';
import '../../../widgets/widgets.dart';

class HostExperienceSubmittedScreen extends StatelessWidget {
  const HostExperienceSubmittedScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.successContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_top_rounded,
                size: 48,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Submitted for review',
              style: AppTypography.headingLarge.copyWith(fontFamily: 'serif'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Your experience is pending review. We’ll notify you when its status changes.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'View Experiences',
              isFullWidth: true,
              onPressed: () => context.go('/host/experiences'),
            ),
          ],
        ),
      ),
    ),
  );
}
