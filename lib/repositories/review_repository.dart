import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/review.dart';

class UserReview {
  final Review review;
  final String experienceTitle;
  final String location;

  const UserReview({
    required this.review,
    required this.experienceTitle,
    required this.location,
  });
}

class ReviewRepository {
  final SupabaseClient _client;

  ReviewRepository(this._client);

  Future<List<UserReview>> getMyReviews() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const [];

    final response = await _client
        .from('reviews')
        .select('*, experiences(title, location_name)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>).map((row) {
      final json = row as Map<String, dynamic>;
      final experience = json['experiences'] as Map<String, dynamic>?;
      return UserReview(
        review: Review.fromJson(json),
        experienceTitle: experience?['title'] as String? ?? 'PLAN E Experience',
        location: experience?['location_name'] as String? ?? 'Nepal',
      );
    }).toList();
  }

  Future<Review> submitReview({
    required String bookingId,
    required int rating,
    String? title,
    String? body,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Sign in to leave a review.');
    if (rating < 1 || rating > 5) {
      throw ArgumentError('Choose a rating between 1 and 5 stars.');
    }

    final booking = await _client
        .from('bookings')
        .select('id, user_id, experience_id, status')
        .eq('id', bookingId)
        .maybeSingle();
    if (booking == null || booking['user_id'] != userId) {
      throw StateError('This booking is not available for review.');
    }
    if (booking['status'] != 'completed') {
      throw StateError('Only completed trips can be reviewed.');
    }

    final existing = await _client
        .from('reviews')
        .select('id')
        .eq('booking_id', bookingId)
        .maybeSingle();
    if (existing != null) {
      throw StateError('You have already reviewed this trip.');
    }

    final response = await _client
        .from('reviews')
        .insert({
          'booking_id': bookingId,
          'experience_id': booking['experience_id'],
          'user_id': userId,
          'rating': rating,
          if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
          if (body != null && body.trim().isNotEmpty) 'body': body.trim(),
        })
        .select()
        .single();
    return Review.fromJson(response);
  }
}
