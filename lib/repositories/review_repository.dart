import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/review.dart';

class ReviewRepository {
  final SupabaseClient _client;

  ReviewRepository(this._client);

  /// Submit a review for a completed booking
  Future<Review> submitReview({
    required String bookingId,
    required String experienceId,
    required int rating,
    String? title,
    String? body,
    List<String> photos = const [],
  }) async {
    final String? userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User must be logged in to leave a review.');
    }

    final insertData = {
      'booking_id': bookingId,
      'experience_id': experienceId,
      'user_id': userId,
      'rating': rating,
      if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
      if (body != null && body.trim().isNotEmpty) 'body': body.trim(),
      'photos': photos,
    };

    final response = await _client
        .from('reviews')
        .insert(insertData)
        .select('*, experiences(*)')
        .single();

    return Review.fromJson(response);
  }

  /// Get all reviews submitted by the current user
  Future<List<Review>> getUserReviews() async {
    final String? userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('reviews')
        .select('*, experiences(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => Review.fromJson(json as Map<String, dynamic>)).toList();
  }
}
