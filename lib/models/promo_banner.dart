/// Parsed shape of `remote_content.promo_banner`'s payload:
/// `{"headline": "...", "subtitle": "...", "cta_label": "...", "cta_route": "..."}`
/// — subtitle and the cta pair are all optional. Pulled out of the home
/// screen widget so the parsing/fallback branching is testable without
/// pumping a widget tree.
class PromoBannerContent {
  final String headline;
  final String? subtitle;
  final String? ctaLabel;
  final String? ctaRoute;

  const PromoBannerContent({
    required this.headline,
    this.subtitle,
    this.ctaLabel,
    this.ctaRoute,
  });

  /// Returns null for anything that isn't a usable banner — not a Map, or a
  /// Map with no non-empty headline. Home renders nothing in that case,
  /// which is exactly "no banner", the same as before this slot existed.
  static PromoBannerContent? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final payload = Map<String, dynamic>.from(raw);

    final headline = payload['headline'] as String?;
    if (headline == null || headline.isEmpty) return null;

    final subtitle = payload['subtitle'] as String?;
    final ctaLabel = payload['cta_label'] as String?;
    final ctaRoute = payload['cta_route'] as String?;

    return PromoBannerContent(
      headline: headline,
      subtitle: (subtitle != null && subtitle.isNotEmpty) ? subtitle : null,
      // A CTA needs both a label and a route — one without the other isn't
      // renderable, so both collapse to null together rather than showing
      // a button that goes nowhere or a route with no label to tap.
      ctaLabel: (ctaLabel != null && ctaLabel.isNotEmpty && ctaRoute != null && ctaRoute.isNotEmpty)
          ? ctaLabel
          : null,
      ctaRoute: (ctaLabel != null && ctaLabel.isNotEmpty && ctaRoute != null && ctaRoute.isNotEmpty)
          ? ctaRoute
          : null,
    );
  }
}
