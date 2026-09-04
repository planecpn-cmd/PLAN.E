import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/offline_cache.dart';
import '../core/supabase_client.dart';
import '../models/booking.dart';
import '../models/booking_intent.dart';
import '../models/experience_departure.dart';

class BookingRepository {
  final SupabaseClient _client;

  BookingRepository(this._client);

  Future<List<ExperienceDeparture>> getDepartures(String experienceId) async {
    final response = await _client
        .from('experience_departures')
        .select()
        .eq('experience_id', experienceId)
        .gte('spots_left', 1)
        .order('start_date', ascending: true);

    final List<dynamic> data = response as List<dynamic>;
    return data
        .map(
          (json) => ExperienceDeparture.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

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
      final bookings = data
          .map((json) => Booking.fromJson(json as Map<String, dynamic>))
          .toList();
      await OfflineCache.write(
        cacheKey,
        bookings.map((b) => b.toJson()).toList(),
      );
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

  Future<BookingIntentResult> createBookingIntent({
    required String experienceId,
    required String departureId,
    required int adults,
    required int children,
    required String contactName,
    required String contactPhone,
    String paymentProvider = 'khalti',
  }) async {
    final response = await _client.functions.invoke(
      'create-booking-intent',
      body: {
        'experience_id': experienceId,
        'departure_id': departureId,
        'adults': adults,
        'children': children,
        'contact_name': contactName,
        'contact_phone': contactPhone,
        'payment_provider': paymentProvider,
      },
    );

    if (response.status == 200 && response.data != null) {
      final Map<String, dynamic> data = Map<String, dynamic>.from(
        response.data as Map,
      );
      return BookingIntentResult.fromJson(data);
    }

    final errorMsg = response.data is Map
        ? (response.data['error'] ?? 'Failed to create booking intent')
        : 'Failed to create booking intent';
    throw Exception(errorMsg.toString());
  }

  Future<String> initiatePayment({
    required String bookingId,
    required String provider,
  }) async {
    final response = await _client.functions.invoke(
      'initiate-payment',
      body: {'booking_id': bookingId, 'provider': provider},
    );

    if (response.status == 200 && response.data != null) {
      final data = Map<String, dynamic>.from(response.data as Map);
      final url = data['payment_url'] as String?;
      if (url != null) return _normalizePaymentUrl(url);
    }
    final errorMsg = response.data is Map
        ? (response.data['error'] ?? 'Failed to start payment')
        : 'Failed to start payment';
    throw Exception(errorMsg.toString());
  }

  String _normalizePaymentUrl(String value) {
    final uri = Uri.parse(value);
    if (uri.host != 'kong') return value;

    final publicBase = Uri.parse(AppSupabaseClient.baseUrl);
    return uri
        .replace(
          scheme: publicBase.scheme,
          host: publicBase.host,
          port: publicBase.hasPort ? publicBase.port : null,
        )
        .toString();
  }

  Future<bool> verifyPayment({
    required String bookingId,
    required String idempotencyKey,
    required String provider,
    String? pidx,
    String? transactionUuid,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'payment-webhook',
        body: {
          'booking_id': bookingId,
          'idempotency_key': idempotencyKey,
          'provider': provider,
          if (pidx != null) 'pidx': pidx,
          if (transactionUuid != null) 'transaction_uuid': transactionUuid,
        },
      );

      if (response.status == 200 && response.data != null) {
        final data = Map<String, dynamic>.from(response.data as Map);
        return data['success'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

}
