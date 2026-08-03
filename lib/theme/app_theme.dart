import 'package:flutter/material.dart';
import 'tokens.dart';
import 'typography.dart';

abstract class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.ivory,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.forest,
        onPrimary: AppColors.ivory,
        primaryContainer: AppColors.deep,
        onPrimaryContainer: AppColors.ivory,
        secondary: AppColors.gold,
        onSecondary: AppColors.ivory,
        secondaryContainer: AppColors.sage,
        onSecondaryContainer: AppColors.deep,
        surface: AppColors.ivory,
        onSurface: AppColors.ink,
        surfaceContainerHighest: AppColors.sage,
        onSurfaceVariant: AppColors.ink,
        error: AppColors.error,
        onError: AppColors.white,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.error,
        outline: AppColors.border,
        outlineVariant: AppColors.borderSubtle,
        shadow: AppColors.black,
      ),
      textTheme: AppTypography.toTextTheme(),
      cardTheme: const CardThemeData(
        color: AppColors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.borderMd16,
          side: BorderSide(color: AppColors.borderSubtle, width: 1.0),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.ivory,
        foregroundColor: AppColors.deep,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: AppTypography.headingMedium,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 1.0,
        space: 1.0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.forest,
          foregroundColor: AppColors.ivory,
          disabledBackgroundColor: AppColors.disabledBackground,
          disabledForegroundColor: AppColors.disabledText,
          minimumSize: const Size(AppTouchTarget.minSize, AppTouchTarget.minSize),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl24,
            vertical: AppSpacing.md12,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadii.borderMd16,
          ),
          textStyle: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.forest,
          disabledForegroundColor: AppColors.disabledText,
          minimumSize: const Size(AppTouchTarget.minSize, AppTouchTarget.minSize),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl24,
            vertical: AppSpacing.md12,
          ),
          side: const BorderSide(color: AppColors.forest, width: 1.5),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadii.borderMd16,
          ),
          textStyle: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.forest,
          disabledForegroundColor: AppColors.disabledText,
          minimumSize: const Size(AppTouchTarget.minSize, AppTouchTarget.minSize),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg16,
            vertical: AppSpacing.sm8,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadii.borderSm8,
          ),
          textStyle: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg16,
          vertical: AppSpacing.md12,
        ),
        border: const OutlineInputBorder(
          borderRadius: AppRadii.borderSm8,
          borderSide: BorderSide(color: AppColors.border, width: 1.0),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadii.borderSm8,
          borderSide: BorderSide(color: AppColors.border, width: 1.0),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadii.borderSm8,
          borderSide: BorderSide(color: AppColors.forest, width: 2.0),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadii.borderSm8,
          borderSide: BorderSide(color: AppColors.error, width: 1.0),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppRadii.borderSm8,
          borderSide: BorderSide(color: AppColors.error, width: 2.0),
        ),
        disabledBorder: const OutlineInputBorder(
          borderRadius: AppRadii.borderSm8,
          borderSide: BorderSide(color: AppColors.borderSubtle, width: 1.0),
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.disabledText),
        labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
        errorStyle: AppTypography.caption.copyWith(color: AppColors.error),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.sage,
        disabledColor: AppColors.disabledBackground,
        selectedColor: AppColors.forest,
        secondarySelectedColor: AppColors.forest,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md12,
          vertical: AppSpacing.sm8,
        ),
        labelStyle: AppTypography.bodyMedium,
        secondaryLabelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.ivory),
        brightness: Brightness.light,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadii.borderPill,
        ),
      ),
    );
  }
}
