import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'host_mode_providers.dart';

/// Opens the group conversation for a departure. The repository
/// lookup keeps conversation identity out of widgets and maps cleanly to a
/// future backend query.
Future<void> openHostDepartureConversation(
  BuildContext context,
  WidgetRef ref,
  String experienceId,
  String experienceTitle,
) async {
  final conversation = await ref.read(
    hostDepartureConversationProvider(experienceId).future,
  );
  if (!context.mounted) return;
  if (conversation != null) {
    context.push('/host/messages/${conversation.id}');
    return;
  }
  context.push('/host/messages?q=${Uri.encodeQueryComponent(experienceTitle)}');
}
