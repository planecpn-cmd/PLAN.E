import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/theme.dart';
import '../../../../widgets/widgets.dart';
import '../host_mode_providers.dart';

/// Access is derived from the authenticated account and backend-approved host
/// status. Database RLS remains the final authorization boundary.
class HostModeAccessGate extends ConsumerStatefulWidget {
  const HostModeAccessGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<HostModeAccessGate> createState() => _HostModeAccessGateState();
}

class _HostModeAccessGateState extends ConsumerState<HostModeAccessGate> {
  bool _refreshed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_refreshed) return;
    _refreshed = true;
    ref.invalidate(hostAccessProvider);
  }

  @override
  Widget build(BuildContext context) {
    return AsyncValueView(
      value: ref.watch(hostAccessProvider),
      data: (access) {
        if (access.canEnterHostMode) return widget.child;
        return Scaffold(
          body: SafeArea(
            child: EmptyStateView(
              icon: Icons.lock_outline,
              title: 'Host Mode unavailable',
              description: 'An approved and active host account is required.',
              actionLabel: 'Return to profile',
              onActionPressed: () => context.go('/profile'),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.forest)),
      ),
    );
  }
}
