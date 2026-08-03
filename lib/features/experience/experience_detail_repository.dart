import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/experience_departure.dart';
import '../../models/itinerary_item.dart';
import '../../models/review.dart';
import '../../models/profile.dart';

class ExperienceDetailRepository {
  final SupabaseClient _client;

  ExperienceDetailRepository(this._client);

  Future<List<ExperienceDeparture>> getDepartures(String experienceId) async {
    try {
      final response = await _client
          .from('experience_departures')
          .select()
          .eq('experience_id', experienceId)
          .order('start_date', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => ExperienceDeparture.fromJson(json as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<ItineraryItem>> getItinerary(String experienceId) async {
    try {
      final response = await _client
          .from('itinerary_items')
          .select()
          .eq('experience_id', experienceId)
          .order('day_number', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => ItineraryItem.fromJson(json as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Review>> getReviews(String experienceId) async {
    try {
      final response = await _client
          .from('reviews')
          .select()
          .eq('experience_id', experienceId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => Review.fromJson(json as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Profile?> getHostProfile(String hostId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', hostId)
          .maybeSingle();

      if (response == null) return null;
      return Profile.fromJson(response);
    } catch (_) {
      return null;
    }
  }
}
