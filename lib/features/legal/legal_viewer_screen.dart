import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/legal_document.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/empty_state_view.dart';
import 'legal_document_view.dart';

/// `/legal/:slug` — reads one current document and renders it.
class LegalViewerScreen extends ConsumerWidget {
  final String slug;

  const LegalViewerScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(legalDocumentProvider(slug));

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        backgroundColor: AppColors.ivory,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/legal'),
        ),
        title: Text(
          async.valueOrNull?.title ?? 'Legal',
          style: AppTypography.headingMedium.copyWith(color: AppColors.ink),
        ),
      ),
      body: AsyncValueView<LegalDocument?>(
        value: async,
        onRetry: () => ref.invalidate(legalDocumentsProvider),
        data: (doc) {
          if (doc == null) {
            return const EmptyStateView(
              icon: Icons.description_outlined,
              title: 'Not published yet',
              description:
                  'This document has not been published. Please check back.',
            );
          }
          return LegalDocumentView(
            bodyMd: doc.bodyMd,
            header: _DocMeta(doc: doc),
          );
        },
      ),
    );
  }
}

class _DocMeta extends StatelessWidget {
  final LegalDocument doc;
  const _DocMeta({required this.doc});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('d MMMM yyyy').format(doc.effectiveAt);
    return Text(
      'Version ${doc.version}  ·  Effective $date',
      style: AppTypography.caption.copyWith(color: AppColors.disabledText),
    );
  }
}
