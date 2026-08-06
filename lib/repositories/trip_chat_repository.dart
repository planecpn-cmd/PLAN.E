import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/trip_message.dart';

class TripChatRepository {
  final SupabaseClient _client;

  TripChatRepository(this._client);

  /// Fetch historic messages for a trip booking from Supabase
  Future<List<TripMessage>> getMessages(String bookingId) async {
    final response = await _client
        .from('trip_messages')
        .select('*, profiles(full_name)')
        .eq('booking_id', bookingId)
        .order('created_at', ascending: true);

    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => TripMessage.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Subscribe to Realtime channel for `trip_messages` table updates
  Stream<List<TripMessage>> streamMessages(String bookingId) {
    return _client
        .from('trip_messages')
        .stream(primaryKey: ['id'])
        .eq('booking_id', bookingId)
        .order('created_at', ascending: true)
        .map((data) => data.map((json) => TripMessage.fromJson(json)).toList());
  }

  /// Insert message into Supabase database
  Future<TripMessage> sendMessage({
    required String bookingId,
    required String body,
    String? attachmentUrl,
  }) async {
    final currentUser = _client.auth.currentUser;
    final String senderId = currentUser?.id ?? '00000000-0000-0000-0000-000000000000';

    final response = await _client
        .from('trip_messages')
        .insert({
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
