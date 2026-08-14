import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../providers/app_providers.dart';
import '../../../../widgets/widgets.dart';

/// Session gate for the host-application journey. Approval is deliberately
/// not granted here; approved/active Host Mode access is checked separately.
class HostApplicationAuthGate extends ConsumerWidget {
  const HostApplicationAuthGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(supabaseClientProvider).auth.currentUser != null) {
      return child;
    }

    return Scaffold(
      body: SafeArea(
        child: EmptyStateView(
          icon: Icons.lock_outline,
          title: 'Sign in to register as a host',
          description:
              'A verified account is required before a host application can be submitted.',
          actionLabel: 'Log in or create account',
          onActionPressed: () {
            ref
                .read(deferredActionProvider.notifier)
                .setPending(
                  const DeferredAction(
                    screenId: 'HOST_APPLICATION',
                    action: 'register as a PLAN E host',
                  ),
                );
            context.go('/auth/required');
          },
        ),
      ),
    );
  }
}
