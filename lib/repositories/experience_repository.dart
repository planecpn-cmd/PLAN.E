import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/offline_cache.dart';
import '../models/experience.dart';
import '../models/experience_departure.dart';
import '../models/experience_family.dart';
import '../models/itinerary_item.dart';
import '../models/profile.dart';
import '../models/review.dart';

class ExperienceRepository {
  final SupabaseClient _client;

  ExperienceRepository(this._client);

  static const _homeRailsCacheKey = 'home_rails';

  Future<List<Experience>> getExperiences({
    String? familySlug,
    String? categoryId,
    String? regionId,
    String? difficulty,
    String? searchQuery,
    int? minPricePaisa,
    int? maxPricePaisa,
    int? maxDurationHours,
    String? sortBy,
    int limit = 24,
    int offset = 0,
  }) async {
    final familyCategoryIds = familySlug == null || familySlug.isEmpty
        ? null
        : await _categoryIdsForFamily(familySlug);
    if (familyCategoryIds != null && familyCategoryIds.isEmpty) return const [];

    // Query PostgREST directly so search does not depend on an Edge Function
    // being deployed in every environment.
    dynamic query = _client
        .from('experiences')
        .select()
        .eq('status', 'published');

    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.eq('category_id', categoryId);
    } else if (familyCategoryIds != null) {
      query = query.inFilter('category_id', familyCategoryIds);
    }
    if (regionId != null && regionId.isNotEmpty) {
      query = query.eq('region_id', regionId);
    }
    if (difficulty != null && difficulty.isNotEmpty && difficulty != 'all') {
      query = query.eq('difficulty', difficulty);
    }
    if (minPricePaisa != null) {
      query = query.gte('price_paisa', minPricePaisa);
    }
    if (maxPricePaisa != null) {
      query = query.lte('price_paisa', maxPricePaisa);
    }
    if (maxDurationHours != null) {
      query = query.lte('duration_hours', maxDurationHours);
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      // The featured Home CTA uses a natural-language label, while the seeded
      // search vector contains the shorter activity term used by trek titles.
      final normalizedSearch =
          searchQuery.trim().toLowerCase() == 'trekking in nepal'
          ? 'trek'
          : searchQuery.trim();
      query = query.textSearch(
        'search_tsv',
        normalizedSearch,
        config: 'english',
        type: TextSearchType.websearch,
      );
    }

    if (sortBy == 'price_asc') {
      query = query.order('price_paisa', ascending: true);
    } else if (sortBy == 'price_desc') {
      query = query.order('price_paisa', ascending: false);
    } else if (sortBy == 'rating') {
      query = query.order('rating_avg', ascending: false);
    } else if (sortBy == 'duration' || sortBy == 'duration_asc') {
      query = query.order('duration_hours', ascending: true);
    } else if (sortBy == 'duration_desc') {
      query = query.order('duration_hours', ascending: false);
    } else if (sortBy == 'popular') {
      query = query.order('rating_count', ascending: false);
    } else if (sortBy == 'newest') {
      query = query.order('created_at', ascending: false);
    } else {
      query = query.order('rating_avg', ascending: false);
    }

    final response = await query
        .range(offset, offset + limit - 1)
        .timeout(
          const Duration(seconds: 12),
          onTimeout: () => throw TimeoutException(
            'Search took too long. Check the connection and try again.',
          ),
        );
    final List<dynamic> data = response as List<dynamic>;
    return data
        .map((json) => Experience.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Experience?> getExperienceById(String id) async {
    final cacheKey = 'experience_detail:$id';
    try {
      final response = await _client
          .from('experiences')
          .select('*, experience_departures(*), itinerary_items(*)')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      final experience = Experience.fromJson(response);
      await OfflineCache.write(cacheKey, experience.toJson());
      return experience;
    } catch (_) {
      final cached = await OfflineCache.read<Experience>(
        cacheKey,
        (json) => Experience.fromJson(json as Map<String, dynamic>),
      );
      if (cached != null) return cached;
      rethrow;
    }
  }

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
          .map(
            (json) =>
                ExperienceDeparture.fromJson(json as Map<String, dynamic>),
          )
          .toList();
      await OfflineCache.write(
        cacheKey,
        departures.map((d) => d.toJson()).toList(),
      );
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
      await OfflineCache.write(
        cacheKey,
        itinerary.map((i) => i.toJson()).toList(),
      );
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
    final cacheKey = 'experience_reviews:v2:$experienceId';
    try {
      final response = await _client.rpc(
        'get_public_experience_reviews',
        params: {'p_experience_id': experienceId},
      );

      final List<dynamic> data = response as List<dynamic>;
      final reviews = data
          .map((json) => Review.fromJson(json as Map<String, dynamic>))
          .toList();
      await OfflineCache.write(
        cacheKey,
        reviews.map((r) => r.toJson()).toList(),
      );
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
      final response = await _client.rpc(
        'get_public_host_profile',
        params: {'p_user_id': hostId},
      ) as List<dynamic>;

      if (response.isEmpty) return null;
      final profile = Profile.fromJson(
        Map<String, dynamic>.from(response.first as Map),
      );
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

  Future<List<Experience>> getHomeRailExperiences(String railType) async {
    final rails = await getHomeRails();
    return rails[railType] ?? const [];
  }

  Future<Map<String, List<Experience>>> getHomeRails() async {
    try {
      List<dynamic> categoriesResponse;
      try {
        categoriesResponse = await _client
            .from('categories')
            .select('id, slug, family_id');
      } catch (_) {
        // The app can still show deterministic family rails while the
        // additive Phase 1 migration is waiting to be deployed.
        categoriesResponse = await _client
            .from('categories')
            .select('id, slug');
      }
      final categorySlugs = <String, String>{
        for (final category in categoriesResponse)
          (category as Map<String, dynamic>)['id'] as String:
              category['slug'] as String,
      };
      final categoryFamilyIds = <String, String?>{
        for (final category in categoriesResponse)
          (category as Map<String, dynamic>)['id'] as String:
              category['family_id'] as String?,
      };
      final familySlugsById = <String, String>{};
      try {
        final familiesResponse = await _client
            .from('experience_families')
            .select('id, slug');
        for (final family in familiesResponse as List<dynamic>) {
          final map = family as Map<String, dynamic>;
          familySlugsById[map['id'] as String] = map['slug'] as String;
        }
      } catch (_) {
        // Legacy schema: category-slug fallback below supplies the family.
      }

      final response = await _client
          .from('experiences')
          .select()
          .eq('status', 'published')
          .order('rating_avg', ascending: false)
          .limit(50);

      final List<dynamic> data = response as List<dynamic>;
      final experiences = data
          .map((json) => Experience.fromJson(json as Map<String, dynamic>))
          .toList();

      String categoryOf(Experience experience) =>
          categorySlugs[experience.categoryId] ?? '';

      String? familyOf(Experience experience) {
        final familyId = categoryFamilyIds[experience.categoryId];
        return familySlugsById[familyId] ??
            fallbackFamilySlugByCategorySlug[categoryOf(experience)];
      }

      List<Experience> take(Iterable<Experience> source) =>
          source.take(10).toList(growable: false);

      final trending = [...experiences]
        ..sort((a, b) => b.ratingCount.compareTo(a.ratingCount));

      final rails = {
        'recommended': take(experiences),
        'trending': take(trending),
        for (final family in defaultExperienceFamilies)
          family.slug: take(
            experiences.where(
              (experience) => familyOf(experience) == family.slug,
            ),
          ),
      };

      // Cached as a snapshot of whatever rail set/rules produced it — an
      // offline view reflects the last successful sync, not a live
      // recomputation against rules that may have changed since (see
      // docs/OFFLINE_CACHE_PLAN.md §2.3).
      await OfflineCache.write(
        _homeRailsCacheKey,
        rails.map(
          (key, list) => MapEntry(key, list.map((e) => e.toJson()).toList()),
        ),
      );
      return rails;
    } catch (_) {
      final cached = await OfflineCache.read<Map<String, List<Experience>>>(
        _homeRailsCacheKey,
        (json) => (json as Map).map(
          (key, value) => MapEntry(
            key as String,
            (value as List)
                .map((e) => Experience.fromJson(e as Map<String, dynamic>))
                .toList(),
          ),
        ),
      );
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<List<String>> _categoryIdsForFamily(String familySlug) async {
    try {
      final response = await _client
          .from('categories')
          .select('id, experience_families!inner(slug)')
          .eq('experience_families.slug', familySlug);
      return (response as List<dynamic>)
          .map((item) => (item as Map<String, dynamic>)['id'] as String)
          .toList(growable: false);
    } catch (_) {
      final categorySlugs = fallbackFamilySlugByCategorySlug.entries
          .where((entry) => entry.value == familySlug)
          .map((entry) => entry.key)
          .toList(growable: false);
      if (categorySlugs.isEmpty) return const [];
      final response = await _client
          .from('categories')
          .select('id')
          .inFilter('slug', categorySlugs);
      return (response as List<dynamic>)
          .map((item) => (item as Map<String, dynamic>)['id'] as String)
          .toList(growable: false);
    }
  }
}
