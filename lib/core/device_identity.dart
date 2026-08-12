import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// A stable per-install id, used only as the rollout bucketing identifier
/// for guests — nobody has a Supabase session to key off of before signing
/// in. Persisted once, read on every later launch; never regenerated.
class DeviceIdentity {
  static const String _key = 'remote_config_device_id';
  static String? _id;

  static Future<void> initialize() async {
    if (_id != null) return;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_key);
    if (id == null) {
      id = _generate();
      await prefs.setString(_key, id);
    }
    _id = id;
  }

  /// Never throws — falls back to a fixed placeholder if read before
  /// [initialize] completes (or in tests that never call it), same pattern
  /// as AppVersionInfo. Rollout bucketing degrades to "everyone on this
  /// device shares one bucket for the session" rather than crashing.
  static String get id => _id ?? 'uninitialized-device';

  static String _generate() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
