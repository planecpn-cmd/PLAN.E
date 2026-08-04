// RM-14 Leave a Review
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/theme.dart';

class LeaveReviewScreen extends StatelessWidget {
  final String bookingId;
  const LeaveReviewScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        backgroundColor: AppColors.ivory,
        elevation: 0,
        title: Text(l10n.leaveReview, style: AppTypography.headingMedium.copyWith(color: AppColors.forest)),
      ),
      body: Center(
        child: Text(l10n.leaveReview, style: AppTypography.bodyLarge),
      ),
    );
  }
}
