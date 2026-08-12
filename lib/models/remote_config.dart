/// Mirrors `feature_flags` (see supabase/migrations/0021_remote_config.sql).
/// `enabled` is the kill switch — always wins. `rolloutPercent`/`platforms`/
/// `min`/`maxAppVersion` narrow who gets it when enabled; see
/// evaluateFeatureFlag in lib/core/feature_flag_evaluation.dart for how
/// these combine.
class RemoteFeatureFlag {
  final String key;
  final bool enabled;
  final int rolloutPercent;
  // Empty means "no platform restriction" (matches every platform), not
  // "no platform is targeted" — same fail-open rule as the rest of this
  // system: an unset/partially-configured flag behaves like it isn't
  // narrowed on that axis at all, never like a silent kill switch.
  final List<String> platforms;
  final String? minAppVersion;
  final String? maxAppVersion;

  const RemoteFeatureFlag({
    required this.key,
    required this.enabled,
    this.rolloutPercent = 100,
    this.platforms = const [],
    this.minAppVersion,
    this.maxAppVersion,
  });

  factory RemoteFeatureFlag.fromJson(Map<String, dynamic> json) {
    return RemoteFeatureFlag(
      key: json['key'] as String,
      enabled: json['enabled'] as bool? ?? false,
      rolloutPercent: (json['rollout_percent'] as num?)?.toInt() ?? 100,
      platforms: (json['platforms'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      minAppVersion: json['min_app_version'] as String?,
      maxAppVersion: json['max_app_version'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'enabled': enabled,
    'rollout_percent': rolloutPercent,
    'platforms': platforms,
    'min_app_version': minAppVersion,
    'max_app_version': maxAppVersion,
  };
}

/// Mirrors `app_versions`. Used for the boot-time force-update / maintenance
/// gate.
class AppVersionGate {
  final String platform;
  final String minSupportedVersion;
  final String latestVersion;
  final bool maintenanceMode;
  final String? maintenanceMessage;

  const AppVersionGate({
    required this.platform,
    required this.minSupportedVersion,
    required this.latestVersion,
    this.maintenanceMode = false,
    this.maintenanceMessage,
  });

  factory AppVersionGate.fromJson(Map<String, dynamic> json) {
    return AppVersionGate(
      platform: json['platform'] as String,
      minSupportedVersion: json['min_supported_version'] as String,
      latestVersion: json['latest_version'] as String,
      maintenanceMode: json['maintenance_mode'] as bool? ?? false,
      maintenanceMessage: json['maintenance_message'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'platform': platform,
    'min_supported_version': minSupportedVersion,
    'latest_version': latestVersion,
    'maintenance_mode': maintenanceMode,
    'maintenance_message': maintenanceMessage,
  };
}

/// One consistent read of all four remote-config tables. Every field has a
/// safe empty default — a missing or corrupt cache, or a fetch that hasn't
/// completed yet, always resolves to "behave like there is no remote config
/// at all" rather than crashing or blocking a screen.
class RemoteConfigSnapshot {
  final Map<String, RemoteFeatureFlag> flags;
  final Map<String, dynamic> content; // remote_content.slot -> payload
  final Map<String, dynamic> config; // app_config.key -> value
  final Map<String, AppVersionGate> versions; // app_versions.platform -> gate
  final DateTime? fetchedAt;

  const RemoteConfigSnapshot({
    this.flags = const {},
    this.content = const {},
    this.config = const {},
    this.versions = const {},
    this.fetchedAt,
  });

  factory RemoteConfigSnapshot.empty() => const RemoteConfigSnapshot();

  factory RemoteConfigSnapshot.fromJson(Map<String, dynamic> json) {
    final flagsJson = json['flags'] as Map<String, dynamic>? ?? const {};
    final versionsJson = json['versions'] as Map<String, dynamic>? ?? const {};
    return RemoteConfigSnapshot(
      flags: flagsJson.map(
        (key, value) => MapEntry(
          key,
          RemoteFeatureFlag.fromJson(value as Map<String, dynamic>),
        ),
      ),
      content: Map<String, dynamic>.from(
        json['content'] as Map<String, dynamic>? ?? const {},
      ),
      config: Map<String, dynamic>.from(
        json['config'] as Map<String, dynamic>? ?? const {},
      ),
      versions: versionsJson.map(
        (key, value) => MapEntry(
          key,
          AppVersionGate.fromJson(value as Map<String, dynamic>),
        ),
      ),
      fetchedAt: json['fetched_at'] != null
          ? DateTime.tryParse(json['fetched_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'flags': flags.map((key, value) => MapEntry(key, value.toJson())),
    'content': content,
    'config': config,
    'versions': versions.map((key, value) => MapEntry(key, value.toJson())),
    'fetched_at': fetchedAt?.toIso8601String(),
  };
}
