import '../features/host/domain/host_mode_models.dart';
import '../models/trip_message.dart';

/// Canonical chat ordering used after every fetch, realtime emission, and
/// optimistic update. Message IDs are the deduplication boundary; later
/// copies win so backend/realtime data replaces an optimistic copy.
List<TripMessage> mergeTripMessagesChronologically(
  Iterable<TripMessage> messages,
) {
  final byId = <String, TripMessage>{};
  for (final message in messages) {
    byId[message.id] = message;
  }
  return byId.values.toList()..sort((a, b) {
    final timestamp = a.createdAt.compareTo(b.createdAt);
    return timestamp != 0 ? timestamp : a.id.compareTo(b.id);
  });
}

List<HostMessage> sortHostMessagesChronologically(
  Iterable<HostMessage> messages,
) {
  final byId = <String, HostMessage>{};
  for (final message in messages) {
    byId[message.id] = message;
  }
  return byId.values.toList()..sort((a, b) {
    final timestamp = a.sentAt.compareTo(b.sentAt);
    return timestamp != 0 ? timestamp : a.id.compareTo(b.id);
  });
}

List<HostConversation> sortHostConversationsByLatestActivity(
  Iterable<HostConversation> conversations,
) => conversations.toList()
  ..sort((a, b) {
    final activity = b.lastMessageAt.compareTo(a.lastMessageAt);
    return activity != 0 ? activity : a.id.compareTo(b.id);
  });
