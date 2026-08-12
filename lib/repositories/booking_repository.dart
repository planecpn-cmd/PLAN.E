import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/offline_cache.dart';
import '../models/booking.dart';

class BookingRepository {
  final SupabaseClient _client;

  BookingRepository(this._client);

  Future<List<Booking>> getBookingsByStatus(String status) async {
    final String? userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final cacheKey = 'bookings:$userId:$status';
    try {
      final response = await _client
          .from('bookings')
          .select('*, experiences(*)')
          .eq('user_id', userId)
          .eq('status', status)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      final bookings =
          data.map((json) => Booking.fromJson(json as Map<String, dynamic>)).toList();
      await OfflineCache.write(cacheKey, bookings.map((b) => b.toJson()).toList());
      return bookings;
    } catch (_) {
      final cached = await OfflineCache.read<List<Booking>>(
        cacheKey,
        (json) => (json as List)
            .map((e) => Booking.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<Booking?> getBookingById(String bookingId) async {
    final response = await _client
        .from('bookings')
        .select('*, experiences(*), experience_departures(*)')
        .eq('id', bookingId)
        .maybeSingle();

    if (response == null) return null;
    return Booking.fromJson(response);
  }
}
