import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_version.dart';
import '../core/offline_cache.dart';
import '../models/legal_document.dart';

/// Fetches versioned legal documents and records acceptances.
///
/// Documents are cached with [OfflineCache] on every successful fetch so the
/// viewer works with no signal — a traveller on a trek needs the Emergency
/// Policy more than anyone.
class LegalRepository {
  final SupabaseClient _client;

  LegalRepository(this._client);

  static const _cacheKey = 'legal_documents_current_en';

  /// Fixed display order for the index screen. Anything not listed sorts last,
  /// alphabetically.
  static const _order = <String>[
    'terms-of-service',
    'privacy-policy',
    'booking-terms',
    'cancellation-policy',
    'refund-policy',
    'payment-policy',
    'grievance-policy',
    'account-deletion-policy',
    'community-guidelines',
    'safety-and-risk-policy',
    'risk-acknowledgment',
    'emergency-policy',
    'cookie-policy',
  ];

  List<LegalDocument> _sorted(List<LegalDocument> docs) {
    int rank(String slug) {
      final i = _order.indexOf(slug);
      return i == -1 ? _order.length : i;
    }

    final copy = [...docs]..sort((a, b) {
      final r = rank(a.slug).compareTo(rank(b.slug));
      return r != 0 ? r : a.title.compareTo(b.title);
    });
    return copy;
  }

  /// All current documents (locale `en`). Falls back to the offline cache when
  /// the network is unavailable.
  Future<List<LegalDocument>> getCurrentDocuments() async {
    try {
      final response = await _client
          .from('legal_documents')
          .select()
          .eq('is_current', true)
          .eq('locale', 'en');
      final docs = (response as List<dynamic>)
          .map((j) => LegalDocument.fromJson(j as Map<String, dynamic>))
          .toList();
      await OfflineCache.write(
        _cacheKey,
        docs.map((d) => d.toJson()).toList(),
      );
      return _sorted(docs);
    } catch (_) {
      final cached = await OfflineCache.read<List<LegalDocument>>(
        _cacheKey,
        (json) => (json as List)
            .map((e) => LegalDocument.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      if (cached != null) return _sorted(cached);
      rethrow;
    }
  }

  Future<LegalDocument?> getDocument(String slug) async {
    final docs = await getCurrentDocuments();
    for (final d in docs) {
      if (d.slug == slug) return d;
    }
    return null;
  }

  /// Records one acceptance row per slug against the slug's *current* document
  /// version. Idempotent at the database (unique on user+document+booking), so
  /// a repeat call is harmless.
  ///
  /// [acceptedAt] lets the caller pass the real moment of the tap when the row
  /// is written later (e.g. sign-up acceptances flushed after email
  /// verification).
  Future<void> recordAcceptances(
    List<String> slugs, {
    String? bookingId,
    DateTime? acceptedAt,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Cannot record legal acceptance without a session.');
    }
    final docs = await getCurrentDocuments();
    final bySlug = {for (final d in docs) d.slug: d};

    final rows = <Map<String, dynamic>>[];
    for (final slug in slugs) {
      final doc = bySlug[slug];
      if (doc == null) continue;
      rows.add({
        'user_id': userId,
        'document_id': doc.id,
        if (bookingId != null) 'booking_id': bookingId,
        if (acceptedAt != null)
          'accepted_at': acceptedAt.toUtc().toIso8601String(),
        'client': 'flutter',
        'app_version': AppVersionInfo.displayVersion,
      });
    }
    if (rows.isEmpty) return;

    // upsert + ignoreDuplicates so a re-tap or a retried flush does not 409 on
    // the unique constraint.
    await _client.from('legal_acceptances').upsert(
      rows,
      onConflict: 'user_id,document_id,booking_id',
      ignoreDuplicates: true,
    );
  }

  /// Document ids the current user has already accepted (any booking context).
  Future<Set<String>> _acceptedDocumentIds() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return {};
    final response = await _client
        .from('legal_acceptances')
        .select('document_id')
        .eq('user_id', userId);
    return {
      for (final r in response as List<dynamic>)
        (r as Map<String, dynamic>)['document_id'] as String,
    };
  }

  /// Current `requires_acceptance` documents the signed-in user has not yet
  /// accepted at their current version. Empty when nothing is outstanding, or
  /// when offline / signed out (fail open — never block the app on a failed
  /// check).
  Future<List<LegalDocument>> outstandingReacceptances() async {
    try {
      if (_client.auth.currentUser == null) return const [];
      final docs = await getCurrentDocuments();
      final accepted = await _acceptedDocumentIds();
      return docs
          .where((d) => d.requiresAcceptance && !accepted.contains(d.id))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  // --- pending sign-up acceptance ------------------------------------------
  //
  // At sign-up there is no session yet (email OTP verification comes first), so
  // the three sign-up acceptances are stashed locally with the real tap time
  // and flushed once a session exists.

  static const _pendingKey = 'legal_pending_signup_acceptance';

  Future<void> stashSignupAcceptance() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _pendingKey,
      jsonEncode({
        'slugs': kSignUpAcceptanceSlugs,
        'at': DateTime.now().toUtc().toIso8601String(),
      }),
    );
  }

  /// Writes any stashed sign-up acceptance rows now that a session exists.
  /// No-op when there is nothing pending or no session.
  Future<void> flushPendingAcceptances() async {
    if (_client.auth.currentUser == null) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingKey);
    if (raw == null) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final slugs = (data['slugs'] as List).cast<String>();
      final at = DateTime.tryParse(data['at'] as String? ?? '');
      await recordAcceptances(slugs, acceptedAt: at);
      await prefs.remove(_pendingKey);
    } catch (_) {
      // Leave the marker in place; the next authenticated launch retries.
    }
  }
}
