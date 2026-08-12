import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// Platform key matching `app_versions.platform` / `feature_flags.platforms`
/// in supabase/migrations/0021_remote_config.sql — 'ios' | 'android' |
/// 'windows' | 'web'.
String get currentPlatformKey {
  if (kIsWeb) return 'web';
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
      return 'ios';
    case TargetPlatform.android:
      return 'android';
    case TargetPlatform.windows:
      return 'windows';
    default:
      return 'unknown';
  }
}
