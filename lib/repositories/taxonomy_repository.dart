import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/offline_cache.dart';
import '../models/category.dart';
import '../models/region.dart';

class TaxonomyRepository {
  final SupabaseClient _client;

  TaxonomyRepository(this._client);

  static const _categoriesCacheKey = 'categories';
  static const _regionsCacheKey = 'regions';

  Future<List<Category>> getCategories() async {
    try {
      final response = await _client
          .from('categories')
          .select()
          .order('sort_order', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      final categories =
          data.map((json) => Category.fromJson(json as Map<String, dynamic>)).toList();

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
      final regions =
          data.map((json) => Region.fromJson(json as Map<String, dynamic>)).toList();

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
