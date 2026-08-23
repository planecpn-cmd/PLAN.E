import 'package:flutter/material.dart';

import '../core/trip_presence_controller.dart';
import '../theme/theme.dart';

class TripPresenceIndicator extends StatelessWidget {
  const TripPresenceIndicator({
    super.key,
    required this.snapshot,
    required this.viewerRole,
  });

  final TripPresenceSnapshot snapshot;
  final String viewerRole;

  @override
  Widget build(BuildContext context) {
    if (!snapshot.isConnected ||
        (snapshot.remoteOnlineCount == 0 && !snapshot.isAnyoneTyping)) {
      return const SizedBox.shrink();
    }

    final text = snapshot.isAnyoneTyping
        ? _typingLabel()
        : snapshot.remoteOnlineCount == 1
        ? 'Online now'
        : '${snapshot.remoteOnlineCount} participants online';
    return Semantics(
      liveRegion: true,
      label: text,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        color: AppColors.sage.withValues(alpha: 0.65),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFF3D8B55),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              text,
              style: AppTypography.caption.copyWith(
                color: AppColors.forest,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _typingLabel() {
    if (snapshot.typingRoles.length > 1) return 'Several people are typing…';
    final role = snapshot.typingRoles.singleOrNull;
    if (role == 'host' && viewerRole != 'host') return 'Host is typing…';
    if (role == 'traveler' && viewerRole == 'host') {
      return snapshot.remoteOnlineCount > 1
          ? 'A traveler is typing…'
          : 'Traveler is typing…';
    }
    return 'Someone is typing…';
  }
}
