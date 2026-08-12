/// Rewrites an Unsplash cover-image URL's `w=` query param to request
/// something closer to the pixels actually being rendered, instead of
/// downloading (and caching) the seed data's blanket 800–1000px source for
/// every use — a rail thumbnail rendered at 148–260 logical pixels was
/// pulling 4–7x the pixels it needed. See docs/OFFLINE_CACHE_PLAN.md §4.2.
///
/// [width] is the exact pixel value to request — callers decide any device-
/// pixel-ratio scaling themselves, this function doesn't apply a hidden
/// multiplier.
///
/// Passes any URL it doesn't recognize through **unchanged**: this only
/// applies to `images.unsplash.com` URLs (100% of current seed cover
/// images, verified against the live catalog). Profile avatars go to
/// Supabase Storage with no `w=` param at all, and any future non-Unsplash
/// image host needs its own equivalent — this function must never guess at
/// a query-param scheme it doesn't actually know.
String resizedImageUrl(String url, {required int width}) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.host != 'images.unsplash.com') return url;
  if (!uri.queryParameters.containsKey('w')) return url;

  final queryParameters = Map<String, String>.from(uri.queryParameters);
  queryParameters['w'] = '$width';
  return uri.replace(queryParameters: queryParameters).toString();
}
