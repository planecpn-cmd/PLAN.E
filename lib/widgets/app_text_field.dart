import 'package:flutter/material.dart';
import '../theme/theme.dart';

class AppTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? errorText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final int maxLines;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.controller,
    this.onChanged,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.maxLines = 1,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: enabled ? AppColors.ink : AppColors.disabledText,
            ),
          ),
          const SizedBox(height: AppSpacing.xs4),
        ],
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppTouchTarget.minSize),
          child: Semantics(
            textField: true,
            label: label ?? hint ?? 'Text field',
            child: TextFormField(
              controller: controller,
              onChanged: onChanged,
              validator: validator,
              obscureText: obscureText,
              keyboardType: keyboardType,
              enabled: enabled,
              maxLines: maxLines,
              textInputAction: textInputAction,
              onFieldSubmitted: onSubmitted,
              style: AppTypography.bodyLarge.copyWith(
                color: enabled ? AppColors.ink : AppColors.disabledText,
              ),
              decoration: InputDecoration(
                hintText: hint,
                errorText: errorText,
                prefixIcon: prefixIcon != null
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm8),
                        child: prefixIcon,
                      )
                    : null,
                suffixIcon: suffixIcon != null
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm8),
                        child: suffixIcon,
                      )
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
