import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/offline_cache.dart';
import '../models/category.dart';
import '../models/experience_family.dart';
import '../models/region.dart';

class TaxonomyRepository {
  final SupabaseClient _client;

  TaxonomyRepository(this._client);

  static const _categoriesCacheKey = 'categories';
  static const _regionsCacheKey = 'regions';
  static const _familiesCacheKey = 'experience_families';

  Future<List<ExperienceFamily>> getExperienceFamilies() async {
    try {
      final response = await _client
          .from('experience_families')
          .select()
          .order('sort_order', ascending: true);
      final families = (response as List<dynamic>)
          .map(
            (json) => ExperienceFamily.fromJson(json as Map<String, dynamic>),
          )
          .toList();
      await OfflineCache.write(
        _familiesCacheKey,
        families.map((family) => family.toJson()).toList(),
      );
      return families;
    } catch (_) {
      final cached = await OfflineCache.read<List<ExperienceFamily>>(
        _familiesCacheKey,
        (json) => (json as List)
            .map(
              (item) => ExperienceFamily.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
      );
      return cached ?? defaultExperienceFamilies;
    }
  }

  Future<List<Category>> getCategories() async {
    try {
      final response = await _client
          .from('categories')
          .select()
          .order('sort_order', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      final categories = data
          .map((json) => Category.fromJson(json as Map<String, dynamic>))
          .toList();

      await OfflineCache.write(
        _categoriesCacheKey,
        categories.map((c) => c.toJson()).toList(),
      );
      return categories;
    } catch (_) {
      final cached = await OfflineCache.read<List<Category>>(
        _categoriesCacheKey,
        (json) => (json as List)
            .map((e) => Category.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<List<Region>> getRegions() async {
    try {
      final response = await _client
          .from('regions')
          .select()
          .order('sort_order', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      final regions = data
          .map((json) => Region.fromJson(json as Map<String, dynamic>))
          .toList();

      await OfflineCache.write(
        _regionsCacheKey,
        regions.map((r) => r.toJson()).toList(),
      );
      return regions;
    } catch (_) {
      final cached = await OfflineCache.read<List<Region>>(
        _regionsCacheKey,
        (json) => (json as List)
            .map((e) => Region.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      if (cached != null) return cached;
      rethrow;
    }
  }
}
