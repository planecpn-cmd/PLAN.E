// RM-14 Leave a Review
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

class LeaveReviewScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const LeaveReviewScreen({super.key, required this.bookingId});

  @override
  ConsumerState<LeaveReviewScreen> createState() => _LeaveReviewScreenState();
}

class _LeaveReviewScreenState extends ConsumerState<LeaveReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  int _rating = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      AppToast.show(
        context,
        message: 'Choose a star rating before submitting.',
        variant: AppToastVariant.error,
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(reviewRepositoryProvider)
          .submitReview(
            bookingId: widget.bookingId,
            rating: _rating,
            title: _titleController.text,
            body: _bodyController.text,
          );
      if (!mounted) return;
      ref.invalidate(bookingsProvider('completed'));
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppColors.ivory,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadii.borderLg24,
          ),
          icon: const Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 52,
          ),
          title: Text(
            'Review sent',
            textAlign: TextAlign.center,
            style: AppTypography.headingMedium.copyWith(
              color: AppColors.forest,
            ),
          ),
          content: const Text(
            'Thank you for sharing your experience.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            AppButton(
              label: 'Done',
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        ),
      );
      if (mounted) context.go('/trips');
    } catch (error) {
      if (mounted) {
        final message = error.toString().replaceFirst('Bad state: ', '');
        AppToast.show(
          context,
          message: message,
          variant: AppToastVariant.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/trips'),
          icon: const Icon(Icons.arrow_back, color: AppColors.forest),
        ),
        title: Text(
          l10n.leaveReview,
          style: AppTypography.headingMedium.copyWith(color: AppColors.forest),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How was your experience?',
                style: AppTypography.headingLarge.copyWith(
                  color: AppColors.forest,
                  fontFamily: 'serif',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your feedback helps travelers and local hosts.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.disabledText,
                ),
              ),
              const SizedBox(height: 24),
              AppCard(
                child: Column(
                  children: [
                    Text(
                      _rating == 0
                          ? 'Tap to rate'
                          : const [
                              '',
                              'Poor',
                              'Fair',
                              'Good',
                              'Very Good',
                              'Excellent',
                            ][_rating],
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.forest,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final value = index + 1;
                        return IconButton(
                          tooltip: '$value stars',
                          onPressed: () => setState(() => _rating = value),
                          icon: Icon(
                            value <= _rating ? Icons.star : Icons.star_border,
                            color: AppColors.gold,
                            size: 36,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AppTextField(
                controller: _titleController,
                label: 'Review title (optional)',
                hint: 'Summarize your experience',
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _bodyController,
                label: 'Your review (optional)',
                hint:
                    'Share highlights, tips, and your experience with the host',
                maxLines: 5,
              ),
              const SizedBox(height: 24),
              AppButton(
                label: l10n.submitReview,
                isFullWidth: true,
                isLoading: _isSubmitting,
                onPressed: _submit,
              ),
              const SizedBox(height: 12),
              Center(
                child: GestureDetector(
                  onTap: () => context.push('/legal/community-guidelines'),
                  child: Text(
                    'Reviews must follow our Community Guidelines',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.gold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
