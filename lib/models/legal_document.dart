/// One versioned legal document row from `public.legal_documents`.
///
/// Bodies are Markdown. Both this app and the web client read the same rows —
/// never hardcode legal text anywhere in the app.
class LegalDocument {
  final String id;
  final String slug;
  final String version;
  final String locale;
  final String title;
  final String bodyMd;
  final DateTime effectiveAt;
  final bool requiresAcceptance;
  final bool isCurrent;

  const LegalDocument({
    required this.id,
    required this.slug,
    required this.version,
    required this.locale,
    required this.title,
    required this.bodyMd,
    required this.effectiveAt,
    required this.requiresAcceptance,
    required this.isCurrent,
  });

  factory LegalDocument.fromJson(Map<String, dynamic> json) {
    return LegalDocument(
      id: json['id'] as String,
      slug: json['slug'] as String,
      version: json['version'] as String,
      locale: json['locale'] as String? ?? 'en',
      title: json['title'] as String,
      bodyMd: json['body_md'] as String? ?? '',
      effectiveAt: DateTime.parse(json['effective_at'] as String),
      requiresAcceptance: json['requires_acceptance'] as bool? ?? false,
      isCurrent: json['is_current'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'slug': slug,
    'version': version,
    'locale': locale,
    'title': title,
    'body_md': bodyMd,
    'effective_at': effectiveAt.toIso8601String(),
    'requires_acceptance': requiresAcceptance,
    'is_current': isCurrent,
  };

  /// Whether the document's stated effective date has passed. Used to decide
  /// between an informational notice (still in the 14-day notice window) and a
  /// blocking re-acceptance prompt.
  bool get isEffective => !effectiveAt.isAfter(DateTime.now());
}

/// The six documents a signed-in user must have a current-version acceptance
/// for. Mirrors `requires_acceptance = true` in the seed.
const kAcceptanceRequiredSlugs = <String>[
  'terms-of-service',
  'privacy-policy',
  'booking-terms',
  'cancellation-policy',
  'community-guidelines',
  'risk-acknowledgment',
];

/// Accepted together at sign-up.
const kSignUpAcceptanceSlugs = <String>[
  'terms-of-service',
  'privacy-policy',
  'community-guidelines',
];

/// Accepted together at checkout.
const kCheckoutAcceptanceSlugs = <String>[
  'booking-terms',
  'cancellation-policy',
];
