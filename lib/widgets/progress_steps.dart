import 'package:flutter/material.dart';
import '../theme/theme.dart';

class ProgressSteps extends StatelessWidget {
  final List<String> steps;
  final int currentStep;

  const ProgressSteps({
    super.key,
    required this.steps,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: List.generate(steps.length * 2 - 1, (index) {
              if (index.isOdd) {
                // Line connector
                final int stepBefore = index ~/ 2;
                final bool isPassed = stepBefore < currentStep;
                return Expanded(
                  child: Container(
                    height: 2.0,
                    color: isPassed ? AppColors.forest : AppColors.border,
                  ),
                );
              }

              // Step Circle
              final int stepIndex = index ~/ 2;
              final bool isCompleted = stepIndex < currentStep;
              final bool isActive = stepIndex == currentStep;

              Color circleBg;
              Color circleBorder;
              Widget content;

              if (isCompleted) {
                circleBg = AppColors.forest;
                circleBorder = AppColors.forest;
                content = const Icon(Icons.check, size: 16, color: AppColors.ivory);
              } else if (isActive) {
                circleBg = AppColors.white;
                circleBorder = AppColors.forest;
                content = Text(
                  '${stepIndex + 1}',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.forest,
                  ),
                );
              } else {
                circleBg = AppColors.sage;
                circleBorder = AppColors.border;
                content = Text(
                  '${stepIndex + 1}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.disabledText,
                  ),
                );
              }

              return Container(
                width: 28.0,
                height: 28.0,
                decoration: BoxDecoration(
                  color: circleBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: circleBorder, width: 2.0),
                ),
                alignment: Alignment.center,
                child: content,
              );
            }),
          ),
          const SizedBox(height: AppSpacing.sm8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(steps.length, (index) {
              final bool isActive = index == currentStep;
              final bool isCompleted = index < currentStep;
              return Expanded(
                child: Text(
                  steps[index],
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    fontWeight: isActive || isCompleted ? FontWeight.w600 : FontWeight.w400,
                    color: isActive
                        ? AppColors.forest
                        : isCompleted
                            ? AppColors.ink
                            : AppColors.disabledText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
