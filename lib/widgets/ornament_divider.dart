import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Thin hairline with a small centered diamond — the "⋄" section separator
/// used throughout the reference mockups (trip detail, profile).
class OrnamentDivider extends StatelessWidget {
  const OrnamentDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Container(height: 1, color: AppColors.gold.withValues(alpha: .35)),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Transform.rotate(
            angle: 0.785398, // 45°
            child: Container(
              width: 6,
              height: 6,
              color: AppColors.gold.withValues(alpha: .55),
            ),
          ),
        ),
        line,
      ],
    );
  }
}
