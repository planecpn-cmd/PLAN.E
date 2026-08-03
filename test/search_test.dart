import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plan_e/repositories/recent_searches_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RecentSearchesRepository', () {
    late RecentSearchesRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repository = RecentSearchesRepository();
    });

    test('starts with empty recent searches', () async {
      final searches = await repository.getRecentSearches();
      expect(searches, isEmpty);
    });

    test('adds search queries and maintains reverse chronological order', () async {
      await repository.addSearchQuery('Everest');
      await repository.addSearchQuery('Annapurna');
      await repository.addSearchQuery('Pokhara');

      final searches = await repository.getRecentSearches();
      expect(searches, ['Pokhara', 'Annapurna', 'Everest']);
    });

    test('deduplicates search queries', () async {
      await repository.addSearchQuery('Everest');
      await repository.addSearchQuery('Annapurna');
      await repository.addSearchQuery('Everest');

      final searches = await repository.getRecentSearches();
      expect(searches, ['Everest', 'Annapurna']);
    });

    test('ignores empty or whitespace queries', () async {
      await repository.addSearchQuery('   ');
      final searches = await repository.getRecentSearches();
      expect(searches, isEmpty);
    });

    test('removes individual query and clears all', () async {
      await repository.addSearchQuery('Everest');
      await repository.addSearchQuery('Annapurna');

      await repository.removeSearchQuery('Everest');
      var searches = await repository.getRecentSearches();
      expect(searches, ['Annapurna']);

      await repository.clearRecentSearches();
      searches = await repository.getRecentSearches();
      expect(searches, isEmpty);
    });
  });
}
