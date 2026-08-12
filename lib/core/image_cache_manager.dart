import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Explicit, bounded config for every cached network image in the app —
/// replaces `cached_network_image`'s library default (200 objects, 30-day
/// staleness, no byte cap), which has no ceiling on total disk usage.
/// See docs/OFFLINE_CACHE_PLAN.md §4.2.
///
/// The numbers here aren't tuned against real measured usage (the seed
/// catalog only has 7 distinct images today, so there's nothing to tune
/// against yet) — they're a deliberate, inspectable cap to replace "whatever
/// the library defaults to," not a promise of exactly these values forever.
class AppImageCacheManager {
  static const key = 'plan_e_image_cache';

  static final CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 14),
      maxNrOfCacheObjects: 150,
    ),
  );
}
