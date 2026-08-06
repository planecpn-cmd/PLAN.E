// RM-14 Leave a Review
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

class LeaveReviewScreen extends StatefulWidget {
  final String bookingId;
  const LeaveReviewScreen({super.key, required this.bookingId});

  @override
  State<LeaveReviewScreen> createState() => _LeaveReviewScreenState();
}

class _LeaveReviewScreenState extends State<LeaveReviewScreen> {
  int _rating = 5;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    // Navigate to Review Submitted Screen
    context.push('/review/submitted');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How was your experience?',
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
                onPressed: _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
