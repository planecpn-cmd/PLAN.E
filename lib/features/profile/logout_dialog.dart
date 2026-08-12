// RM-26 Logout Dialog
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/offline_cache.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/app_button.dart';

class LogoutDialog extends ConsumerWidget {
  const LogoutDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadii.borderMd16,
      ),
      backgroundColor: AppColors.white,
      title: Row(
        children: [
          const Icon(Icons.logout, color: AppColors.error, size: 24),
          const SizedBox(width: AppSpacing.sm8),
          Text(
            'Log Out',
            style: AppTypography.headingMedium.copyWith(color: AppColors.ink),
          ),
        ],
      ),
      content: Text(
        'Are you sure you want to log out of your PLAN E account?',
        style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
      ),
      actionsPadding: const EdgeInsets.all(AppSpacing.lg16),
      actions: [
        Row(
          children: [
            Expanded(
              child: AppButton.secondary(
                label: 'Cancel',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: AppSpacing.md12),
            Expanded(
              child: AppButton(
                label: 'Log Out',
                onPressed: () async {
                  try {
                    final client = ref.read(supabaseClientProvider);
                    // Captured before signOut() — currentUser is null right
                    // after, and every user-scoped cache key carries this id
                    // (see docs/OFFLINE_CACHE_PLAN.md §2.5). A shared/reused
                    // device must never let the next person who logs in see
                    // this user's cached bookings/profile because a fetch
                    // happened to fail right after they signed in.
                    final userId = client.auth.currentUser?.id;
                    await client.auth.signOut();
                    if (userId != null) {
                      await OfflineCache.clearWhere((key) => key.contains(':$userId'));
                    }
                    ref.invalidate(profileProvider);
                  } catch (_) {
                    // Fallback for offline mode
                  }
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    context.go('/auth/login');
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
