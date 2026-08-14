import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/chat_ordering.dart';
import '../core/offline_cache.dart';
import '../models/trip_message.dart';

class TripChatRepository {
  final SupabaseClient _client;

  TripChatRepository(this._client);

  /// Fetch historic messages for a trip booking from Supabase. Read-only
  /// cache — offline, this returns whatever was last synced; sending a new
  /// message still requires connectivity (see
  /// docs/OFFLINE_CACHE_PLAN.md §5), the outbox in
  /// TripChatNotifier.sendMessage handles that failure separately, not here.
  Future<List<TripMessage>> getMessages(String bookingId) async {
    final cacheKey = 'trip_messages:$bookingId';
    try {
      final response = await _client
          .from('trip_messages')
          .select('*, profiles(full_name)')
          .eq('booking_id', bookingId)
          .order('created_at', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      // Cache the raw response, not TripMessage.toJson() — that method is
      // shaped for outbound inserts and deliberately drops the joined
      // `profiles.full_name` (there's no sender to re-send on insert).
      // Round-tripping through it would silently blank out every cached
      // message's sender name. The raw data is already exactly the shape
      // fromJson expects.
      await OfflineCache.write(cacheKey, data);
      return mergeTripMessagesChronologically(
        data.map((json) => TripMessage.fromJson(json as Map<String, dynamic>)),
      );
    } catch (_) {
      final cached = await OfflineCache.read<List<TripMessage>>(
        cacheKey,
        (json) => (json as List)
            .map((e) => TripMessage.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      if (cached != null) return mergeTripMessagesChronologically(cached);
      rethrow;
    }
  }

  /// Subscribe to Realtime channel for `trip_messages` table updates
  Stream<List<TripMessage>> streamMessages(String bookingId) {
    return _client
        .from('trip_messages')
        .stream(primaryKey: ['id'])
        .eq('booking_id', bookingId)
        .order('created_at', ascending: true)
        .map(
          (data) => mergeTripMessagesChronologically(
            data.map((json) => TripMessage.fromJson(json)),
          ),
        );
  }

  /// Insert message into Supabase database
  Future<TripMessage> sendMessage({
    required String bookingId,
    required String body,
    required String messageId,
    String? attachmentUrl,
  }) async {
    final currentUser = _client.auth.currentUser;
    final String senderId =
        currentUser?.id ?? '00000000-0000-0000-0000-000000000000';

    final response = await _client
        .from('trip_messages')
        .insert({
          'id': messageId,
          'booking_id': bookingId,
          'sender_id': senderId,
          'body': body,
          if (attachmentUrl != null) 'attachment_url': attachmentUrl,
        })
        .select('*, profiles(full_name)')
        .single();

    return TripMessage.fromJson(response);
  }

  /// Get current user ID
  String? get currentUserId => _client.auth.currentUser?.id;
}
