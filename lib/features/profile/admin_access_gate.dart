import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/profile.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

/// Route gate for `/admin/*`. The moderation RPCs already enforce `is_admin()`
/// server-side, but the route used to render for any signed-in user and rely
/// entirely on that. This stops a non-admin from reaching the screen at all —
/// same widget-wrapper pattern as [host_application_auth_gate] /
/// [host_mode_access_gate].
class AdminAccessGate extends ConsumerWidget {
  const AdminAccessGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncValueView(
      value: ref.watch(profileProvider),
      data: (profile) {
        if (profile?.role == UserRole.admin) return child;
        return _denied(context);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.forest)),
      ),
      error: (_, __) => _denied(context),
    );
  }

  Widget _denied(BuildContext context) => Scaffold(
        body: SafeArea(
          child: EmptyStateView(
            icon: Icons.lock_outline,
            title: 'Admin access required',
            description: 'This area is for Plan E staff.',
            actionLabel: 'Return to profile',
            onActionPressed: () => context.go('/profile'),
          ),
        ),
      );
}
