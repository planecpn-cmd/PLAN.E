// RM-14 Leave a Review
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/booking/booking_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../models/booking.dart';
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
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit(Booking booking) async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repo = ref.read(reviewRepositoryProvider);
      await repo.submitReview(
        bookingId: booking.id,
        experienceId: booking.experienceId,
        rating: _rating,
        body: _commentController.text.trim(),
      );

      // Invalidate relevant providers to update UI
      ref.invalidate(userReviewsProvider);
      ref.invalidate(bookingsProvider('completed'));
      if (booking.experienceId.isNotEmpty) {
        ref.invalidate(experienceDetailProvider(booking.experienceId));
      }

      if (mounted) {
        context.push('/review/submitted');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit review: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bookingAsync = ref.watch(bookingDetailProvider(widget.bookingId));

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        backgroundColor: AppColors.ivory,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.forest),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.leaveReview,
          style: AppTypography.headingMedium.copyWith(color: AppColors.forest),
        ),
      ),
      body: AsyncValueView<Booking?>(
        value: bookingAsync,
        onRetry: () => ref.invalidate(bookingDetailProvider(widget.bookingId)),
        data: (booking) {
          final effectiveBooking = booking ?? Booking(
            id: widget.bookingId,
            bookingRef: 'PLE-TRIP',
            userId: '',
            experienceId: '',
            departureId: '',
            adults: 1,
            contactName: '',
            contactPhone: '',
            subtotalPaisa: 0,
            totalPaisa: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          final String expTitle = effectiveBooking.experience?.title ?? 'your experience';

          return SafeArea(
            child: SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How was $expTitle?',
                    style: AppTypography.headingLarge.copyWith(color: AppColors.forest),
                  ),
                  const SizedBox(height: AppSpacing.xs4),
                  Text(
                    'Your feedback helps future travelers and local hosts.',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.disabledText),
                  ),
                  const SizedBox(height: AppSpacing.xl20),
                  Center(
                    child: RatingStars(
                      rating: _rating.toDouble(),
                      onRatingChanged: (val) {
                        setState(() => _rating = val.toInt());
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl24),
                  AppTextField(
                    label: 'Your Review',
                    hint: 'Share details about the guide, trail, and hospitality...',
                    controller: _commentController,
                    maxLines: 4,
                  ),
                  const SizedBox(height: AppSpacing.xxl24),
                  AppButton(
                    label: 'SUBMIT REVIEW',
                    isFullWidth: true,
                    isLoading: _isSubmitting,
                    onPressed: () => _handleSubmit(effectiveBooking),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
