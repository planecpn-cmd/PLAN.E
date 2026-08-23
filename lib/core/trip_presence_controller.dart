import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@immutable
class TripPresenceSnapshot {
  const TripPresenceSnapshot({
    this.isConnected = false,
    this.remoteOnlineCount = 0,
    this.typingRoles = const <String>{},
  });

  final bool isConnected;
  final int remoteOnlineCount;
  final Set<String> typingRoles;

  bool get isAnyoneTyping => typingRoles.isNotEmpty;

  static TripPresenceSnapshot fromPresenceState(
    List<SinglePresenceState> states, {
    required String currentUserId,
    bool isConnected = true,
  }) {
    final remoteUsers = <String>{};
    final roles = <String>{};
    for (final state in states) {
      if (state.key == currentUserId) continue;
      remoteUsers.add(state.key);
      for (final presence in state.presences) {
        if (presence.payload['typing'] != true) continue;
        final role = presence.payload['role'];
        roles.add(
          role == 'host' || role == 'traveler' ? role as String : 'participant',
        );
      }
    }
    return TripPresenceSnapshot(
      isConnected: isConnected,
      remoteOnlineCount: remoteUsers.length,
      typingRoles: Set.unmodifiable(roles),
    );
  }
}

class TripPresenceController extends ValueNotifier<TripPresenceSnapshot> {
  TripPresenceController({
    required this.client,
    required this.bookingId,
    required this.userId,
    required this.role,
    this.typingTimeout = const Duration(milliseconds: 1800),
  }) : super(const TripPresenceSnapshot());

  final SupabaseClient client;
  final String bookingId;
  final String userId;
  final String role;
  final Duration typingTimeout;

  RealtimeChannel? _channel;
  Timer? _typingTimer;
  bool _started = false;
  bool _closed = false;
  bool _isTyping = false;

  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  static bool isValidBookingId(String value) => _uuidPattern.hasMatch(value);

  Future<void> start() async {
    if (_started || _closed || !isValidBookingId(bookingId)) return;
    if (role != 'host' && role != 'traveler') return;
    _started = true;

    late final RealtimeChannel channel;
    channel = client.channel(
      'trip-presence:$bookingId',
      opts: RealtimeChannelConfig(key: userId, enabled: true, private: true),
    );
    _channel = channel;
    channel.onPresenceSync((_) => _syncFromChannel(channel)).subscribe((
      status,
      error,
    ) {
      if (_closed) return;
      if (status == RealtimeSubscribeStatus.subscribed) {
        unawaited(_publishTyping(false));
      } else if (status == RealtimeSubscribeStatus.channelError ||
          status == RealtimeSubscribeStatus.closed ||
          status == RealtimeSubscribeStatus.timedOut) {
        value = const TripPresenceSnapshot();
      }
    });
  }

  /// Sends one `typing: true` update at the start of a typing burst and one
  /// `typing: false` update after inactivity. Keystrokes only reset the local
  /// timer, keeping Presence traffic bounded.
  void updateTyping(bool hasText) {
    if (_closed || !_started) return;
    _typingTimer?.cancel();
    if (!hasText) {
      unawaited(stopTyping());
      return;
    }
    if (!_isTyping) unawaited(_publishTyping(true));
    _typingTimer = Timer(typingTimeout, () => unawaited(stopTyping()));
  }

  Future<void> stopTyping() async {
    _typingTimer?.cancel();
    _typingTimer = null;
    if (!_isTyping) return;
    await _publishTyping(false);
  }

  Future<void> _publishTyping(bool typing) async {
    final channel = _channel;
    if (_closed || channel == null) return;
    _isTyping = typing;
    try {
      await channel.track({'user_id': userId, 'role': role, 'typing': typing});
    } catch (_) {
      // Presence is an enhancement; chat sending must remain independent.
    }
  }

  void _syncFromChannel(RealtimeChannel channel) {
    if (_closed) return;
    value = TripPresenceSnapshot.fromPresenceState(
      channel.presenceState(),
      currentUserId: userId,
    );
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _typingTimer?.cancel();
    _typingTimer = null;
    final channel = _channel;
    _channel = null;
    if (channel != null) {
      try {
        await channel.untrack();
      } catch (_) {
        // The socket may already be gone while a screen is being disposed.
      }
      await client.removeChannel(channel);
    }
    super.dispose();
  }
}
