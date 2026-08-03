import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category.dart';
import '../models/region.dart';

class TaxonomyRepository {
  final SupabaseClient _client;

  TaxonomyRepository(this._client);

  Future<List<Category>> getCategories() async {
    final response = await _client
        .from('categories')
        .select()
        .order('sort_order', ascending: true);

    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => Category.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<Region>> getRegions() async {
    final response = await _client
        .from('regions')
        .select()
        .order('sort_order', ascending: true);

    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => Region.fromJson(json as Map<String, dynamic>)).toList();
  }
}
