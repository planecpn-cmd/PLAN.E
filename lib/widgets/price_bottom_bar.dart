import 'package:flutter/material.dart';
import '../theme/theme.dart';
import 'app_button.dart';

class PriceBottomBar extends StatelessWidget {
  final String priceText;
  final String unitText;
  final String buttonLabel;
  final VoidCallback? onPressed;
  final bool isLoading;

  const PriceBottomBar({
    super.key,
    required this.priceText,
    this.unitText = '/ person',
    this.buttonLabel = 'Book Now',
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg16,
        vertical: AppSpacing.md12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle, width: 1.0),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                label: 'Price $priceText $unitText',
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          priceText,
                          style: AppTypography.headingMedium.copyWith(
                            color: AppColors.forest,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (unitText.isNotEmpty) ...[
                          const SizedBox(width: AppSpacing.xs4),
                          Text(
                            unitText,
                            style: AppTypography.caption.copyWith(color: AppColors.disabledText),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg16),
            AppButton(
              label: buttonLabel,
              onPressed: onPressed,
              isLoading: isLoading,
              variant: AppButtonVariant.primary,
            ),
          ],
        ),
      ),
    );
  }
}
