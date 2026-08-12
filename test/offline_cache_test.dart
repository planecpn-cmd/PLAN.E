import 'package:flutter_test/flutter_test.dart';
import 'package:plan_e/core/offline_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('read/write round-trip', () {
    test('a Map value round-trips', () async {
      await OfflineCache.write('profile:user-1', {
        'id': 'user-1',
        'full_name': 'Ram Bahadur',
      });

      final result = await OfflineCache.read<String>(
        'profile:user-1',
        (json) => (json as Map)['full_name'] as String,
      );

      expect(result, 'Ram Bahadur');
    });

    test('a List value round-trips — the common case, most repos return lists', () async {
      await OfflineCache.write('home_rails:trending', [
        {'id': 'exp-1', 'title': 'Everest Base Camp'},
        {'id': 'exp-2', 'title': 'Annapurna Circuit'},
      ]);

      final result = await OfflineCache.read<List<String>>(
        'home_rails:trending',
        (json) => (json as List)
            .map((e) => (e as Map)['title'] as String)
            .toList(),
      );

      expect(result, ['Everest Base Camp', 'Annapurna Circuit']);
    });
  });

  group('fail-open behavior', () {
    test('read on a missing key returns null, not an error', () async {
      final result = await OfflineCache.read<String>(
        'never_written',
        (json) => json as String,
      );
      expect(result, isNull);
    });

    test('a decode callback that throws returns null instead of propagating', () async {
      await OfflineCache.write('bad_shape', {'unexpected': 'shape'});

      final result = await OfflineCache.read<String>(
        'bad_shape',
        (json) => (json as Map)['this_key_does_not_exist'] as String,
      );

      expect(result, isNull);
    });

    test('a corrupt raw cache entry returns null instead of crashing', () async {
      // Simulates a schema change or disk corruption — something wrote
      // garbage under our storage key directly.
      SharedPreferences.setMockInitialValues({
        'offline_cache:corrupt_key': 'not valid json at all {{{',
      });

      final result = await OfflineCache.read<String>(
        'corrupt_key',
        (json) => json as String,
      );

      expect(result, isNull);
    });
  });

  group('lastWrittenAt', () {
    test('null before any write', () async {
      expect(await OfflineCache.lastWrittenAt('never_written'), isNull);
    });

    test('a real timestamp after a write, close to now', () async {
      final before = DateTime.now().toUtc();
      await OfflineCache.write('categories', {'a': 1});
      final after = DateTime.now().toUtc();

      final writtenAt = await OfflineCache.lastWrittenAt('categories');

      expect(writtenAt, isNotNull);
      expect(writtenAt!.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(writtenAt.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });
  });

  group('clear / clearAll / clearWhere', () {
    test('clear(key) removes only that key', () async {
      await OfflineCache.write('a', {'v': 1});
      await OfflineCache.write('b', {'v': 2});

      await OfflineCache.clear('a');

      expect(await OfflineCache.read<int>('a', (j) => (j as Map)['v'] as int), isNull);
      expect(await OfflineCache.read<int>('b', (j) => (j as Map)['v'] as int), 2);
    });

    test('clearAll removes every key', () async {
      await OfflineCache.write('a', {'v': 1});
      await OfflineCache.write('b', {'v': 2});

      await OfflineCache.clearAll();

      expect(await OfflineCache.read<int>('a', (j) => (j as Map)['v'] as int), isNull);
      expect(await OfflineCache.read<int>('b', (j) => (j as Map)['v'] as int), isNull);
    });

    test('clearWhere removes only matching keys — the logout use case', () async {
      await OfflineCache.write('profile:user-1', {'v': 1});
      await OfflineCache.write('bookings:user-1:confirmed', {'v': 2});
      await OfflineCache.write('categories', {'v': 3}); // not user-scoped

      await OfflineCache.clearWhere((key) => key.contains(':user-1'));

      expect(await OfflineCache.read<int>('profile:user-1', (j) => (j as Map)['v'] as int), isNull);
      expect(await OfflineCache.read<int>('bookings:user-1:confirmed', (j) => (j as Map)['v'] as int), isNull);
      expect(await OfflineCache.read<int>('categories', (j) => (j as Map)['v'] as int), 3);
    });
  });

  group('soft size cap eviction (docs/OFFLINE_CACHE_PLAN.md §4.1)', () {
    test('oldest-written key is evicted first once the cap is exceeded', () async {
      // Six ~1MB entries — total ~6MB, over the 5MB cap — forces eviction.
      final chunk = 'x' * (1024 * 1024);

      await OfflineCache.write('oldest', chunk);
      // Real wall-clock gaps so written_at ordering is unambiguous, not
      // relying on same-millisecond writes sorting predictably.
      await Future.delayed(const Duration(milliseconds: 5));
      await OfflineCache.write('middle', chunk);
      await Future.delayed(const Duration(milliseconds: 5));
      await OfflineCache.write('newest', chunk);
      await Future.delayed(const Duration(milliseconds: 5));
      await OfflineCache.write('newer2', chunk);
      await Future.delayed(const Duration(milliseconds: 5));
      await OfflineCache.write('newer3', chunk);
      await Future.delayed(const Duration(milliseconds: 5));
      await OfflineCache.write('newer4', chunk);

      // The oldest write should have been evicted to stay under budget.
      final oldest = await OfflineCache.read<String>('oldest', (j) => j as String);
      expect(oldest, isNull);

      // The most recent write must always survive — otherwise a single
      // write could evict itself, which would make the cache useless.
      final newest4 = await OfflineCache.read<String>('newer4', (j) => j as String);
      expect(newest4, isNotNull);
    });

    test('a single write under the cap is never evicted by itself', () async {
      await OfflineCache.write('small', {'v': 1});
      final result = await OfflineCache.read<int>('small', (j) => (j as Map)['v'] as int);
      expect(result, 1);
    });
  });
}
