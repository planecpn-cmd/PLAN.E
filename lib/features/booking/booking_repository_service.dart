import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/booking.dart';
import '../../models/experience_departure.dart';

class BookingFeatureRepository {
  final SupabaseClient _client;

  BookingFeatureRepository(this._client);

  /// Fetch departures for a given experience ID
  Future<List<ExperienceDeparture>> getDepartures(String experienceId) async {
    try {
      final response = await _client
          .from('experience_departures')
          .select()
          .eq('experience_id', experienceId)
          .gte('spots_left', 1)
          .order('start_date', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => ExperienceDeparture.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      // Fallback: If table is empty or error occurs, return empty list or fallback departure
      return [];
    }
  }

  /// Fetch booking details by booking ID
  Future<Booking?> getBookingById(String bookingId) async {
    try {
      final response = await _client
          .from('bookings')
          .select('*, experiences(*), experience_departures(*)')
          .eq('id', bookingId)
          .maybeSingle();

      if (response == null) return null;
      return Booking.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Create a new booking draft / confirmed record
  Future<Booking> createBooking({
    required String experienceId,
    required String departureId,
    required int adults,
    required int children,
    required String contactName,
    required String contactPhone,
    required int subtotalPaisa,
    required int addonsPaisa,
    required int feesPaisa,
    required int totalPaisa,
  }) async {
    final String userId = _client.auth.currentUser?.id ?? '00000000-0000-0000-0000-000000000000';
    final String refCode = 'PLE-${Random().nextInt(899999) + 100000}';

    final Map<String, dynamic> insertData = {
      'booking_ref': refCode,
      'user_id': userId,
      'experience_id': experienceId,
      'departure_id': departureId,
      'adults': adults,
      'children': children,
      'contact_name': contactName,
      'contact_phone': contactPhone,
      'subtotal_paisa': subtotalPaisa,
      'addons_paisa': addonsPaisa,
      'fees_paisa': feesPaisa,
      'total_paisa': totalPaisa,
      'status': 'pending',
      'is_draft': false,
    };

    try {
      final response = await _client
          .from('bookings')
          .insert(insertData)
          .select('*, experiences(*), experience_departures(*)')
          .single();

      return Booking.fromJson(response);
    } catch (e) {
      // Return optimistic local booking object if database insert fails or offline
      final now = DateTime.now();
      return Booking(
        id: 'bk-${DateTime.now().millisecondsSinceEpoch}',
        bookingRef: refCode,
        userId: userId,
        experienceId: experienceId,
        departureId: departureId,
        adults: adults,
        children: children,
        contactName: contactName,
        contactPhone: contactPhone,
        subtotalPaisa: subtotalPaisa,
        addonsPaisa: addonsPaisa,
        feesPaisa: feesPaisa,
        totalPaisa: totalPaisa,
        status: BookingStatus.pending,
        createdAt: now,
        updatedAt: now,
      );
    }
  }
}
