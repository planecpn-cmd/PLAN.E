// RM-15 Review Submitted
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/theme.dart';

class ReviewSubmittedScreen extends StatelessWidget {
  const ReviewSubmittedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        backgroundColor: AppColors.ivory,
        elevation: 0,
        title: Text(l10n.reviewSubmitted, style: AppTypography.headingMedium.copyWith(color: AppColors.forest)),
      ),
      body: Center(
        child: Text(l10n.reviewSubmitted, style: AppTypography.bodyLarge),
      ),
    );
  }
}
