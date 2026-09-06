import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/legal_document.dart';
import '../repositories/legal_repository.dart';
import 'app_providers.dart';

final legalRepositoryProvider = Provider<LegalRepository>((ref) {
  return LegalRepository(ref.watch(supabaseClientProvider));
});

/// All current legal documents, in index display order.
final legalDocumentsProvider = FutureProvider<List<LegalDocument>>((ref) async {
  return ref.watch(legalRepositoryProvider).getCurrentDocuments();
});

/// One current document by slug. Null when the slug is not seeded.
final legalDocumentProvider =
    FutureProvider.family<LegalDocument?, String>((ref, slug) async {
  final docs = await ref.watch(legalDocumentsProvider.future);
  for (final d in docs) {
    if (d.slug == slug) return d;
  }
  return null;
});

/// Current `requires_acceptance` documents the signed-in user still owes an
/// acceptance for. Drives the launch re-acceptance gate.
final outstandingReacceptancesProvider =
    FutureProvider<List<LegalDocument>>((ref) async {
  return ref.watch(legalRepositoryProvider).outstandingReacceptances();
});
