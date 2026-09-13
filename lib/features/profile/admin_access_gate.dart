import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/profile.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

/// Route gate for `/admin/message-moderation`.
///
/// Message moderation is **founder-only**: the underlying RPCs
/// (`get_trip_moderation_queue`, `review_trip_message_report`) are gated on
/// `public.is_admin()` server-side (migration `20260816170000`), and there is no
/// trip-moderation scope in the staff model — so `role == admin` (which, after
/// `20260908140000`, only founders hold) is exactly the right check here. A
/// moderator-reachable version would need a new scope AND those RPCs changed to
/// accept it. Until then this stays role-based, matching the RPC boundary.
///
/// The route used to render for any signed-in user and rely entirely on the RPC
/// check. Same widget-wrapper pattern as [HostApplicationAuthGate] /
/// [HostModeAccessGate].
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
