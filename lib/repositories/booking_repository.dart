import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking.dart';

class BookingRepository {
  final SupabaseClient _client;

  BookingRepository(this._client);

  Future<List<Booking>> getBookingsByStatus(String status) async {
    final String? userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('bookings')
        .select('*, experiences(*)')
        .eq('user_id', userId)
        .eq('status', status)
        .order('created_at', ascending: false);

    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => Booking.fromJson(json as Map<String, dynamic>)).toList();
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
