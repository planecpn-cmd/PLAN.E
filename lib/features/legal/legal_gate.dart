import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/legal_document.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_toast.dart';
import 'legal_document_view.dart';

/// Wraps the routed app (see `MaterialApp.router` builder in main.dart),
/// alongside [VersionGate].
///
///  - Flushes any sign-up acceptance stashed before email verification.
///  - When a `requires_acceptance` document has a newer version the user has
///    not accepted:
///      * before its effective date  → non-blocking banner above the app
///      * on/after its effective date → full-screen block until accepted
///
/// Fail-open: a failed check, offline, or signed-out state renders [child]
/// untouched.
class LegalGate extends ConsumerStatefulWidget {
  final Widget child;
  const LegalGate({super.key, required this.child});

  @override
  ConsumerState<LegalGate> createState() => _LegalGateState();
}

class _LegalGateState extends ConsumerState<LegalGate> {
  bool _bannerDismissed = false;

  @override
  void initState() {
    super.initState();
    // Best-effort, non-blocking.
    Future.microtask(
      () => ref.read(legalRepositoryProvider).flushPendingAcceptances(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final outstanding =
        ref.watch(outstandingReacceptancesProvider).valueOrNull ?? const [];
    if (outstanding.isEmpty) return widget.child;

    final blocking = outstanding.where((d) => d.isEffective).toList();
    if (blocking.isNotEmpty) {
      return _ReacceptScreen(
        doc: blocking.first,
        remaining: blocking.length,
        onAccepted: () => ref.invalidate(outstandingReacceptancesProvider),
      );
    }

    // All outstanding docs are still inside their notice period.
    if (_bannerDismissed) return widget.child;
    return _NoticeBanner(
      docs: outstanding,
      onDismiss: () => setState(() => _bannerDismissed = true),
      child: widget.child,
    );
  }
}

class _NoticeBanner extends StatelessWidget {
  final List<LegalDocument> docs;
  final VoidCallback onDismiss;
  final Widget child;

  const _NoticeBanner({
    required this.docs,
    required this.onDismiss,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final names = docs.map((d) => d.title).join(', ');
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Material(
            color: AppColors.sage,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg16,
                vertical: AppSpacing.sm8,
              ),
              child: Row(
                children: [
                  const Icon(Icons.gavel_outlined,
                      size: 18, color: AppColors.forest),
                  const SizedBox(width: AppSpacing.sm8),
                  Expanded(
                    child: Text(
                      'Updated $names take effect soon. You will be asked to '
                      'accept them.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.forest,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        size: 18, color: AppColors.forest),
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                    tooltip: 'Dismiss',
                    onPressed: onDismiss,
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _ReacceptScreen extends ConsumerStatefulWidget {
  final LegalDocument doc;
  final int remaining;
  final VoidCallback onAccepted;

  const _ReacceptScreen({
    required this.doc,
    required this.remaining,
    required this.onAccepted,
  });

  @override
  ConsumerState<_ReacceptScreen> createState() => _ReacceptScreenState();
}

class _ReacceptScreenState extends ConsumerState<_ReacceptScreen> {
  bool _scrolledToEnd = false;
  bool _submitting = false;

  Future<void> _accept() async {
    setState(() => _submitting = true);
    try {
      await ref
          .read(legalRepositoryProvider)
          .recordAcceptances([widget.doc.slug]);
      widget.onAccepted();
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        AppToast.show(
          context,
          message: 'Could not record acceptance. Check your connection.',
          variant: AppToastVariant.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.ivory,
        appBar: AppBar(
          backgroundColor: AppColors.ivory,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            'Updated: ${widget.doc.title}',
            style: AppTypography.headingMedium.copyWith(color: AppColors.ink),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg16,
                AppSpacing.md12,
                AppSpacing.lg16,
                0,
              ),
              child: Text(
                'We have updated this document. Please review it and accept to '
                'continue using PLAN E.'
                '${widget.remaining > 1 ? ' (${widget.remaining} documents to review.)' : ''}',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
              ),
            ),
            Expanded(
              child: LegalDocumentView(
                bodyMd: widget.doc.bodyMd,
                showSectionIndex: false,
                onScrolledToEnd: () => setState(() => _scrolledToEnd = true),
              ),
            ),
            Material(
              color: AppColors.ivory,
              elevation: 8,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: AppSpacing.paddingLg16,
                  child: AppButton(
                    label: _scrolledToEnd
                        ? 'Accept ${widget.doc.title}'
                        : 'Scroll to the end to accept',
                    isFullWidth: true,
                    isLoading: _submitting,
                    minHeight: AppTouchTarget.minSize,
                    onPressed: (_scrolledToEnd && !_submitting) ? _accept : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
