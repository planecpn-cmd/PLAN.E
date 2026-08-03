import 'package:shared_preferences/shared_preferences.dart';

class RecentSearchesRepository {
  static const String _key = 'recent_searches';
  static const int _maxItems = 10;

  Future<List<String>> getRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  Future<void> addSearchQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];

    list.remove(trimmed);
    list.insert(0, trimmed);

    if (list.length > _maxItems) {
      list.removeRange(_maxItems, list.length);
    }

    await prefs.setStringList(_key, list);
  }

  Future<void> removeSearchQuery(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    list.remove(query);
    await prefs.setStringList(_key, list);
  }

  Future<void> clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
