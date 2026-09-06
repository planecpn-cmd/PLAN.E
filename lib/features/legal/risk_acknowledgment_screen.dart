import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/legal_document.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_toast.dart';
import 'legal_document_view.dart';

/// Full-screen Risk Acknowledgment step in the booking flow. Not a checkbox,
/// not a modal — a record that means something.
///
/// Pushed from the booking screen after the booking intent is created, for
/// experiences of difficulty Moderate/Challenging/Strenuous, altitude > 3000 m,
/// or the climbing / rafting / paragliding / canyoning categories. Pops `true`
/// once the acceptance row is written; anything else means the user backed out.
class RiskAcknowledgmentScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const RiskAcknowledgmentScreen({super.key, required this.bookingId});

  @override
  ConsumerState<RiskAcknowledgmentScreen> createState() =>
      _RiskAcknowledgmentScreenState();
}

class _RiskAcknowledgmentScreenState
    extends ConsumerState<RiskAcknowledgmentScreen> {
  static const _confirmations = <String>[
    'I have read and understood this Risk Acknowledgment.',
    'I confirm the accuracy of the health and fitness information I have provided.',
    'I am 18 or older, or a parent or guardian confirming on behalf of a minor '
        'participant, whose details I have provided.',
  ];

  final _checked = List<bool>.filled(_confirmations.length, false);
  bool _scrolledToEnd = false;
  bool _submitting = false;

  bool get _allChecked => _checked.every((c) => c);

  Future<void> _continue() async {
    setState(() => _submitting = true);
    try {
      await ref.read(legalRepositoryProvider).recordAcceptances(
        const ['risk-acknowledgment'],
        bookingId: widget.bookingId,
      );
      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        AppToast.show(
          context,
          message: 'Could not record acknowledgment. Please try again.',
          variant: AppToastVariant.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(legalDocumentProvider('risk-acknowledgment'));

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        backgroundColor: AppColors.ivory,
        elevation: 0,
        title: Text(
          'Risk Acknowledgment',
          style: AppTypography.headingMedium.copyWith(color: AppColors.ink),
        ),
      ),
      body: AsyncValueView<LegalDocument?>(
        value: async,
        onRetry: () => ref.invalidate(legalDocumentsProvider),
        data: (doc) {
          if (doc == null) {
            // Fail safe: never silently skip the step. Block the booking and
            // tell the user to retry with a connection.
            return Padding(
              padding: AppSpacing.paddingXxl24,
              child: Center(
                child: Text(
                  'The Risk Acknowledgment could not be loaded. A network '
                  'connection is required the first time. Please retry.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
                ),
              ),
            );
          }
          return Column(
            children: [
              Expanded(
                child: LegalDocumentView(
                  bodyMd: doc.bodyMd,
                  showSectionIndex: false,
                  onScrolledToEnd: () =>
                      setState(() => _scrolledToEnd = true),
                ),
              ),
              _ConfirmBar(
                confirmations: _confirmations,
                checked: _checked,
                enabled: _scrolledToEnd,
                allChecked: _allChecked,
                submitting: _submitting,
                onToggle: (i, v) => setState(() => _checked[i] = v),
                onContinue: _continue,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ConfirmBar extends StatelessWidget {
  final List<String> confirmations;
  final List<bool> checked;
  final bool enabled;
  final bool allChecked;
  final bool submitting;
  final void Function(int index, bool value) onToggle;
  final VoidCallback onContinue;

  const _ConfirmBar({
    required this.confirmations,
    required this.checked,
    required this.enabled,
    required this.allChecked,
    required this.submitting,
    required this.onToggle,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.ivory,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: AppSpacing.paddingLg16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!enabled)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm8),
                  child: Text(
                    'Scroll to the end to continue.',
                    style: AppTypography.caption.copyWith(color: AppColors.gold),
                  ),
                ),
              for (var i = 0; i < confirmations.length; i++)
                _CheckRow(
                  label: confirmations[i],
                  value: checked[i],
                  enabled: enabled,
                  onChanged: (v) => onToggle(i, v ?? false),
                ),
              const SizedBox(height: AppSpacing.sm8),
              AppButton(
                label: 'Confirm and continue',
                isFullWidth: true,
                isLoading: submitting,
                minHeight: AppTouchTarget.minSize,
                onPressed: (enabled && allChecked && !submitting)
                    ? onContinue
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool?> onChanged;

  const _CheckRow({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => onChanged(!value) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeColor: AppColors.forest,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: AppSpacing.sm8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md12),
                child: Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: enabled ? AppColors.ink : AppColors.disabledText,
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
