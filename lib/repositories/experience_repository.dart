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
        final List<dynamic> experiencesJson =
            data['experiences'] as List<dynamic>? ?? [];
        return experiencesJson
            .map((json) => Experience.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // Edge function fallback to PostgREST query below
    }

    // 2. Fallback to direct PostgREST query if Edge Function is offline/unreachable
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
      query = query.textSearch(
        'search_tsv',
        searchQuery.trim(),
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

    final response = await query.range(offset, offset + limit - 1);
    final List<dynamic> data = response as List<dynamic>;
    return data
        .map((json) => Experience.fromJson(json as Map<String, dynamic>))
        .toList();
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
    final rails = await getHomeRails();
    return rails[railType] ?? const [];
  }

  Future<Map<String, List<Experience>>> getHomeRails() async {
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

    String searchableText(Experience experience) => [
      experience.title,
      experience.summary ?? '',
      experience.description ?? '',
      ...experience.thingsToKnow,
    ].join(' ').toLowerCase();

    bool containsAny(Experience experience, List<String> terms) {
      final text = searchableText(experience);
      return terms.any(text.contains);
    }

    List<Experience> take(Iterable<Experience> source) =>
        source.take(10).toList(growable: false);

    final trending = [...experiences]
      ..sort((a, b) => b.ratingCount.compareTo(a.ratingCount));

    return {
      'recommended': take(experiences),
      'trending': take(trending),
      'homestays': take(
        experiences.where((experience) => categoryOf(experience) == 'homestay'),
      ),
      'community': take(
        experiences.where(
          (experience) => containsAny(experience, const [
            'community',
            'local women',
            'local family',
            'cooperative',
          ]),
        ),
      ),
      'adventure-together': take(
        experiences.where(
          (experience) => containsAny(experience, const [
            'family',
            'group',
            'tandem',
            'rafting',
            'camping',
            'safari',
            'day out',
            'festival',
            'homestay',
          ]),
        ),
      ),
      'mind-soul': take(
        experiences.where(
          (experience) =>
              categoryOf(experience) == 'wellness' ||
              containsAny(experience, const [
                'yoga',
                'meditation',
                'spiritual',
                'wellness',
                'relax',
                'healing',
                'peace',
                'quiet',
                'monastery',
                'forest',
              ]),
        ),
      ),
      'give-back': take(
        experiences.where(
          (experience) =>
              categoryOf(experience) == 'volunteering' ||
              containsAny(experience, const [
                'volunteer',
                'community',
                'conservation',
                'environment',
                'sustainable',
                'empower',
                'cooperative',
                'organic farm',
                'social impact',
              ]),
        ),
      ),
    };
  }
}
