import 'package:flutter/material.dart';

/// Design tokens for PLAN E based on UI/UX Report §5.2
abstract class AppColors {
  // Brand Palette
  static const Color forest = Color(0xFF18372D);
  static const Color deep = Color(0xFF01251C);
  static const Color ivory = Color(0xFFFFFFFF);
  static const Color sage = Color(0xFFE7ECE7);
  static const Color ink = Color(0xFF24312D);
  static const Color gold = Color(0xFF8F5E1B); // WCAG AA 5.07:1 contrast on ivory

  // Neutral & Base
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);

  // Status & Feedback
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color success = Color(0xFF2E6C40);
  static const Color successContainer = Color(0xFFD2E8D4);
  static const Color warning = Color(0xFF7D5200);
  static const Color warningContainer = Color(0xFFFFDDB3);

  // Borders & Surfaces
  static const Color border = Color(0xFFCBD5CE);
  static const Color borderSubtle = Color(0xFFE2E8E4);
  static const Color disabledBackground = Color(0xFFE0E0E0);
  static const Color disabledText = Color(0xFF8D9993);
  static const Color overlay = Color(0x66000000);
  static const Color shadow = Color(0x18000000);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardBackgroundAlt = Color(0xFFFAF8F5);
  static const Color skeletonBase = Color(0xFFE3E8E4);
  static const Color skeletonHighlight = Color(0xFFF2F5F3);
}

abstract class AppSpacing {
  static const double xs4 = 4.0;
  static const double sm8 = 8.0;
  static const double md12 = 12.0;
  static const double lg16 = 16.0;
  static const double xl20 = 20.0;
  static const double xxl24 = 24.0;
  static const double xxxl32 = 32.0;
  static const double huge40 = 40.0;

  static const EdgeInsets paddingXs4 = EdgeInsets.all(xs4);
  static const EdgeInsets paddingSm8 = EdgeInsets.all(sm8);
  static const EdgeInsets paddingMd12 = EdgeInsets.all(md12);
  static const EdgeInsets paddingLg16 = EdgeInsets.all(lg16);
  static const EdgeInsets paddingXl20 = EdgeInsets.all(xl20);
  static const EdgeInsets paddingXxl24 = EdgeInsets.all(xxl24);
  static const EdgeInsets paddingXxxl32 = EdgeInsets.all(xxxl32);
  static const EdgeInsets paddingHuge40 = EdgeInsets.all(huge40);

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: lg16,
    vertical: md12,
  );
}

abstract class AppRadii {
  static const double sm8 = 8.0;
  static const double md16 = 16.0;
  static const double lg24 = 24.0;
  static const double pill = 999.0;

  static const BorderRadius borderSm8 = BorderRadius.all(Radius.circular(sm8));
  static const BorderRadius borderMd16 = BorderRadius.all(Radius.circular(md16));
  static const BorderRadius borderLg24 = BorderRadius.all(Radius.circular(lg24));
  static const BorderRadius borderPill = BorderRadius.all(Radius.circular(pill));
}

abstract class AppTouchTarget {
  static const double minSize = 48.0;
  static const BoxConstraints minConstraints = BoxConstraints(
    minWidth: minSize,
    minHeight: minSize,
  );
}
