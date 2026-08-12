import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Generic cache-aside primitive, one key per query — the same idea as
/// `RemoteConfigService`, generalized for any repository to use (see
/// docs/OFFLINE_CACHE_PLAN.md §2.1–2.2). A value can be anything
/// `jsonEncode` accepts (a `Map`, a `List` of maps, a primitive) — most
/// repositories here return lists (`List<Experience>`, `List<Booking>`...),
/// not single objects, so this deliberately doesn't assume a `Map` shape
/// the way `RemoteConfigSnapshot` does.
///
/// Enforces a soft total-size cap (see [_maxTotalBytes]) by evicting the
/// least-recently-*written* key first — not an LRU-by-read policy, since
/// "written" is the only timestamp cheap to track here and matches the
/// actual usage pattern (a key is rewritten every time its query succeeds
/// online; a key nobody's fetched in a long time is exactly the one that's
/// gone stale and safe to drop first).
class OfflineCache {
  const OfflineCache._();

  static const String _keyPrefix = 'offline_cache:';
  static const String _manifestKey = 'offline_cache_manifest';

  /// Soft cap on total cached bytes across all keys. Not a hard platform
  /// limit — just where eviction kicks in. See
  /// docs/OFFLINE_CACHE_PLAN.md §4.1 for why this number: the entire
  /// current catalog is ~40KB, so 5MB is generous headroom, not a tight fit.
  static const int _maxTotalBytes = 5 * 1024 * 1024;

  /// Returns null on a cache miss, a decode failure, or a `decode` callback
  /// that throws — a corrupt or stale-shaped cache entry is treated exactly
  /// like "nothing cached", never a crash.
  static Future<T?> read<T>(
    String key,
    T Function(dynamic decodedJson) decode,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey(key));
      if (raw == null) return null;

      final envelope = jsonDecode(raw) as Map<String, dynamic>;
      return decode(envelope['data']);
    } catch (_) {
      return null;
    }
  }

  static Future<DateTime?> lastWrittenAt(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey(key));
      if (raw == null) return null;
      final envelope = jsonDecode(raw) as Map<String, dynamic>;
      return DateTime.tryParse(envelope['written_at'] as String? ?? '');
    } catch (_) {
      return null;
    }
  }

  /// [value] must be `jsonEncode`-able. Failure to write (disk full, a
  /// non-encodable value passed by mistake) is swallowed — a cache write
  /// failing must never break the network call that just succeeded and is
  /// about to be returned to the caller regardless.
  static Future<void> write(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final writtenAt = DateTime.now().toUtc();
      final encoded = jsonEncode({
        'data': value,
        'written_at': writtenAt.toIso8601String(),
      });

      await prefs.setString(_storageKey(key), encoded);
      await _touchManifest(prefs, key, encoded.length, writtenAt);
      await _evictIfOverBudget(prefs);
    } catch (_) {
      // Fail open — see doc comment above.
    }
  }

  static Future<void> clear(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey(key));
      final manifest = await _readManifest(prefs);
      manifest.remove(key);
      await _writeManifest(prefs, manifest);
    } catch (_) {
      // Fail open.
    }
  }

  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final manifest = await _readManifest(prefs);
      for (final key in manifest.keys) {
        await prefs.remove(_storageKey(key));
      }
      await prefs.remove(_manifestKey);
    } catch (_) {
      // Fail open.
    }
  }

  /// Clears every key for which [test] returns true — e.g. every key
  /// scoped to a signed-out user (see docs/OFFLINE_CACHE_PLAN.md §2.5).
  static Future<void> clearWhere(bool Function(String key) test) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final manifest = await _readManifest(prefs);
      final toRemove = manifest.keys.where(test).toList();
      for (final key in toRemove) {
        await prefs.remove(_storageKey(key));
        manifest.remove(key);
      }
      await _writeManifest(prefs, manifest);
    } catch (_) {
      // Fail open.
    }
  }

  static String _storageKey(String key) => '$_keyPrefix$key';

  static Future<Map<String, dynamic>> _readManifest(
    SharedPreferences prefs,
  ) async {
    final raw = prefs.getString(_manifestKey);
    if (raw == null) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  static Future<void> _writeManifest(
    SharedPreferences prefs,
    Map<String, dynamic> manifest,
  ) async {
    await prefs.setString(_manifestKey, jsonEncode(manifest));
  }

  static Future<void> _touchManifest(
    SharedPreferences prefs,
    String key,
    int bytes,
    DateTime writtenAt,
  ) async {
    final manifest = await _readManifest(prefs);
    manifest[key] = {
      'bytes': bytes,
      'written_at': writtenAt.toIso8601String(),
    };
    await _writeManifest(prefs, manifest);
  }

  static Future<void> _evictIfOverBudget(SharedPreferences prefs) async {
    final manifest = await _readManifest(prefs);
    int total = 0;
    for (final entry in manifest.values) {
      total += (entry as Map)['bytes'] as int? ?? 0;
    }
    if (total <= _maxTotalBytes) return;

    final entries = manifest.entries.toList()
      ..sort((a, b) {
        final aTime = DateTime.tryParse((a.value as Map)['written_at'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = DateTime.tryParse((b.value as Map)['written_at'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return aTime.compareTo(bTime); // oldest-written first
      });

    for (final entry in entries) {
      if (total <= _maxTotalBytes) break;
      await prefs.remove(_storageKey(entry.key));
      total -= (entry.value as Map)['bytes'] as int? ?? 0;
      manifest.remove(entry.key);
    }
    await _writeManifest(prefs, manifest);
  }
}
