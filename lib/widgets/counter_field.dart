import 'package:flutter/material.dart';
import '../theme/theme.dart';

class CounterField extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final String? label;

  const CounterField({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 99,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final bool canDecrement = value > min;
    final bool canIncrement = value < max;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (label != null)
          Expanded(
            child: Text(
              label!,
              style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: AppRadii.borderPill,
            border: Border.all(color: AppColors.border, width: 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Decrement Button (>= 48x48 dp touch target)
              SizedBox(
                width: AppTouchTarget.minSize,
                height: AppTouchTarget.minSize,
                child: IconButton(
                  onPressed: canDecrement ? () => onChanged(value - 1) : null,
                  icon: const Icon(Icons.remove, size: 20),
                  color: AppColors.forest,
                  disabledColor: AppColors.disabledText,
                  padding: EdgeInsets.zero,
                ),
              ),

              // Value Display
              Container(
                constraints: const BoxConstraints(minWidth: 36.0),
                alignment: Alignment.center,
                child: Text(
                  '$value',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
              ),

              // Increment Button (>= 48x48 dp touch target)
              SizedBox(
                width: AppTouchTarget.minSize,
                height: AppTouchTarget.minSize,
                child: IconButton(
                  onPressed: canIncrement ? () => onChanged(value + 1) : null,
                  icon: const Icon(Icons.add, size: 20),
                  color: AppColors.forest,
                  disabledColor: AppColors.disabledText,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
