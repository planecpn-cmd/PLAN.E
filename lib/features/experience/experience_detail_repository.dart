import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/offline_cache.dart';
import '../../models/experience_departure.dart';
import '../../models/itinerary_item.dart';
import '../../models/review.dart';
import '../../models/profile.dart';

class ExperienceDetailRepository {
  final SupabaseClient _client;

  ExperienceDetailRepository(this._client);

  Future<List<ExperienceDeparture>> getDepartures(String experienceId) async {
    final cacheKey = 'experience_departures:$experienceId';
    try {
      final response = await _client
          .from('experience_departures')
          .select()
          .eq('experience_id', experienceId)
          .order('start_date', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      final departures = data
          .map((json) => ExperienceDeparture.fromJson(json as Map<String, dynamic>))
          .toList();
      await OfflineCache.write(cacheKey, departures.map((d) => d.toJson()).toList());
      return departures;
    } catch (_) {
      final cached = await OfflineCache.read<List<ExperienceDeparture>>(
        cacheKey,
        (json) => (json as List)
            .map((e) => ExperienceDeparture.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<List<ItineraryItem>> getItinerary(String experienceId) async {
    final cacheKey = 'experience_itinerary:$experienceId';
    try {
      final response = await _client
          .from('itinerary_items')
          .select()
          .eq('experience_id', experienceId)
          .order('day_number', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      final itinerary = data
          .map((json) => ItineraryItem.fromJson(json as Map<String, dynamic>))
          .toList();
      await OfflineCache.write(cacheKey, itinerary.map((i) => i.toJson()).toList());
      return itinerary;
    } catch (_) {
      final cached = await OfflineCache.read<List<ItineraryItem>>(
        cacheKey,
        (json) => (json as List)
            .map((e) => ItineraryItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<List<Review>> getReviews(String experienceId) async {
    final cacheKey = 'experience_reviews:$experienceId';
    try {
      final response = await _client
          .from('reviews')
          .select()
          .eq('experience_id', experienceId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      final reviews =
          data.map((json) => Review.fromJson(json as Map<String, dynamic>)).toList();
      await OfflineCache.write(cacheKey, reviews.map((r) => r.toJson()).toList());
      return reviews;
    } catch (_) {
      final cached = await OfflineCache.read<List<Review>>(
        cacheKey,
        (json) => (json as List)
            .map((e) => Review.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<Profile?> getHostProfile(String hostId) async {
    final cacheKey = 'host_profile:$hostId';
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', hostId)
          .maybeSingle();

      if (response == null) return null;
      final profile = Profile.fromJson(response);
      await OfflineCache.write(cacheKey, profile.toJson());
      return profile;
    } catch (_) {
      final cached = await OfflineCache.read<Profile>(
        cacheKey,
        (json) => Profile.fromJson(json as Map<String, dynamic>),
      );
      if (cached != null) return cached;
      rethrow;
    }
  }
}
