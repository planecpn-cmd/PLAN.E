import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/remote_config.dart';

/// Cache + fetch for the four remote-config tables (see
/// supabase/migrations/0021_remote_config.sql). Two entry points:
///
/// - [loadCached] — local disk only, called once at boot before `runApp` so
///   the first frame already has last-known-good config, no network wait.
/// - [fetchAndCache] — hits Supabase, called unawaited right after boot and
///   again on foreground resume. On any failure the caller keeps whatever it
///   already had (cache or previous state) — a flaky network never wipes out
///   good config.
class RemoteConfigService {
  const RemoteConfigService._();

  static const String _cacheKey = 'remote_config_cache_v1';

  static Future<RemoteConfigSnapshot> loadCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return RemoteConfigSnapshot.empty();
      return RemoteConfigSnapshot.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      // Corrupt cache (e.g. a schema change) — fail open, not crash.
      return RemoteConfigSnapshot.empty();
    }
  }

  static Future<RemoteConfigSnapshot> fetchAndCache(
    SupabaseClient client,
  ) async {
    final results = await Future.wait([
      client.from('feature_flags').select(),
      client.from('remote_content').select(),
      client.from('app_config').select(),
      client.from('app_versions').select(),
    ]);

    final flagRows = results[0] as List<dynamic>;
    final contentRows = results[1] as List<dynamic>;
    final configRows = results[2] as List<dynamic>;
    final versionRows = results[3] as List<dynamic>;

    final snapshot = RemoteConfigSnapshot(
      flags: {
        for (final row in flagRows)
          (row as Map<String, dynamic>)['key'] as String:
              RemoteFeatureFlag.fromJson(row),
      },
      content: {
        for (final row in contentRows)
          (row as Map<String, dynamic>)['slot'] as String: row['payload'],
      },
      config: {
        for (final row in configRows)
          (row as Map<String, dynamic>)['key'] as String: row['value'],
      },
      versions: {
        for (final row in versionRows)
          (row as Map<String, dynamic>)['platform'] as String:
              AppVersionGate.fromJson(row),
      },
      fetchedAt: DateTime.now().toUtc(),
    );

    await _writeCache(snapshot);
    return snapshot;
  }

  static Future<void> _writeCache(RemoteConfigSnapshot snapshot) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(snapshot.toJson()));
    } catch (_) {
      // Cache write failing (disk full, etc.) shouldn't break the fetch that
      // just succeeded — the in-memory snapshot is still returned to the
      // caller either way.
    }
  }
}
