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
    int limit = 20,
    int offset = 0,
  }) async {
    dynamic query = _client.from('experiences').select().eq('status', 'published');

    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.eq('category_id', categoryId);
    }
    if (regionId != null && regionId.isNotEmpty) {
      query = query.eq('region_id', regionId);
    }
    if (difficulty != null && difficulty.isNotEmpty) {
      query = query.eq('difficulty', difficulty);
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      query = query.textSearch('search_tsv', searchQuery.trim());
    }

    final response = await query.order('created_at', ascending: false).range(offset, offset + limit - 1);
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
