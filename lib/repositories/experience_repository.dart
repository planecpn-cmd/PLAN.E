import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/experience.dart';

class ExperienceRepository {
  final SupabaseClient _client;

  ExperienceRepository(this._client);

  Future<List<Experience>> getExperiences({
    String? categoryId,
    String? regionId,
    String? difficulty,
    String? searchQuery,
    int? minPricePaisa,
    int? maxPricePaisa,
    String? sortBy,
    int limit = 20,
    int offset = 0,
  }) async {
    // 1. Try invoking search-experiences Edge Function
    try {
      final response = await _client.functions.invoke(
        'search-experiences',
        body: {
          'query': searchQuery ?? '',
          'category_id': categoryId,
          'region_id': regionId,
          'difficulty': difficulty,
          'min_price': minPricePaisa,
          'max_price': maxPricePaisa,
          'sort_by': sortBy ?? 'relevance',
          'page': (offset ~/ limit) + 1,
          'limit': limit,
        },
      );

      if (response.status == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> experiencesJson = data['experiences'] as List<dynamic>? ?? [];
        return experiencesJson
            .map((json) => Experience.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // Edge function fallback to PostgREST query below
    }

    // 2. Fallback to direct PostgREST query if Edge Function is offline/unreachable
    dynamic query = _client.from('experiences').select().eq('status', 'published');

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
      query = query.textSearch('search_tsv', searchQuery.trim());
    }

    if (sortBy == 'price_asc') {
      query = query.order('price_paisa', ascending: true);
    } else if (sortBy == 'price_desc') {
      query = query.order('price_paisa', ascending: false);
    } else if (sortBy == 'rating') {
      query = query.order('rating_avg', ascending: false);
    } else if (sortBy == 'popular') {
      query = query.order('rating_count', ascending: false);
    } else {
      query = query.order('created_at', ascending: false);
    }

    final response = await query.range(offset, offset + limit - 1);
    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => Experience.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Experience?> getExperienceById(String id) async {
    final response = await _client
        .from('experiences')
        .select('*, experience_departures(*), itinerary_items(*)')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Experience.fromJson(response);
  }

  Future<List<Experience>> getHomeRailExperiences(String railType) async {
    final response = await _client
        .from('experiences')
        .select()
        .eq('status', 'published')
        .order('rating_avg', ascending: false)
        .limit(10);

    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => Experience.fromJson(json as Map<String, dynamic>)).toList();
  }
}
