import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_client.dart';
import '../../models/booking.dart';
import '../../models/booking_intent.dart';
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
      return data
          .map(
            (json) =>
                ExperienceDeparture.fromJson(json as Map<String, dynamic>),
          )
          .toList();
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

  /// Create server booking intent with re-priced calculations and idempotency key
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
        'user_id': _client.auth.currentUser?.id,
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

  /// Ask the server to open a real payment session with the gateway and
  /// return the checkout URL to load in a WebView.
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

  /// Verify payment with the gateway server-side (never trusts client-claimed
  /// success) and confirm the booking if verification passes.
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
    } catch (e) {
      return false;
    }
  }

  /// Create a new booking draft / confirmed record (legacy fallback)
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
    final String userId =
        _client.auth.currentUser?.id ?? '00000000-0000-0000-0000-000000000000';
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
