import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/offline_cache.dart';
import '../models/experience.dart';
import '../models/home_rail_rule.dart';

class ExperienceRepository {
  final SupabaseClient _client;

  ExperienceRepository(this._client);

  static const _homeRailsCacheKey = 'home_rails';

  Future<List<Experience>> getExperiences({
    String? categoryId,
    String? regionId,
    String? difficulty,
    String? searchQuery,
    int? minPricePaisa,
    int? maxPricePaisa,
    String? sortBy,
    int limit = 24,
    int offset = 0,
  }) async {
    // Query PostgREST directly so search does not depend on an Edge Function
    // being deployed in every environment.
    dynamic query = _client
        .from('experiences')
        .select()
        .eq('status', 'published');

    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.eq('category_id', categoryId);
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

  Future<List<Experience>> getHomeRailExperiences(String railType) async {
    final rails = await getHomeRails();
    return rails[railType] ?? const [];
  }

  Future<Map<String, List<Experience>>> getHomeRails({
    List<HomeRailRule>? railRules,
  }) async {
    try {
      final categoriesResponse = await _client
          .from('categories')
          .select('id, slug');
      final categorySlugs = <String, String>{
        for (final category in categoriesResponse as List<dynamic>)
          (category as Map<String, dynamic>)['id'] as String:
              category['slug'] as String,
      };

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

      List<Experience> take(Iterable<Experience> source) =>
          source.take(10).toList(growable: false);

      final trending = [...experiences]
        ..sort((a, b) => b.ratingCount.compareTo(a.ratingCount));

      final rails = {
        'recommended': take(experiences),
        'trending': take(trending),
        'homestays': take(
          experiences.where((experience) => categoryOf(experience) == 'homestay'),
        ),
        // Merchandising rails (community/adventure-together/mind-soul/
        // give-back) — keyword+category rules, editable without a release via
        // remote_content.home_rail_rules. See lib/models/home_rail_rule.dart.
        ...buildRuleBasedRails(
          experiences,
          categorySlugs,
          railRules ?? defaultHomeRailRules,
        ),
      };

      // Cached as a snapshot of whatever rail set/rules produced it — an
      // offline view reflects the last successful sync, not a live
      // recomputation against rules that may have changed since (see
      // docs/OFFLINE_CACHE_PLAN.md §2.3).
      await OfflineCache.write(
        _homeRailsCacheKey,
        rails.map((key, list) => MapEntry(key, list.map((e) => e.toJson()).toList())),
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
}
