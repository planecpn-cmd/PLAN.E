// src/theme/typography.ts
import { colors } from './tokens';

export const typography = {
  fontFamily: {
    serif: 'System', // Display serif placeholder
    sans: 'System',  // Body sans placeholder
  },
  styles: {
    displayLarge: {
      fontSize: 32,
      lineHeight: 40,
      fontWeight: 'bold' as const,
      color: colors.ink,
    },
    displayMedium: {
      fontSize: 28,
      lineHeight: 36,
      fontWeight: 'bold' as const,
      color: colors.ink,
    },
    headingLarge: {
      fontSize: 24,
      lineHeight: 32,
      fontWeight: '700' as const,
      color: colors.ink,
    },
    headingMedium: {
      fontSize: 20,
      lineHeight: 28,
      fontWeight: '600' as const,
      color: colors.ink,
    },
    bodyLarge: {
      fontSize: 16,
      lineHeight: 24,
      fontWeight: '400' as const,
      color: colors.ink,
    },
    bodyMedium: {
      fontSize: 14,
      lineHeight: 20,
      fontWeight: '400' as const,
      color: colors.ink,
    },
    caption: {
      fontSize: 12,
      lineHeight: 18,
      fontWeight: '400' as const,
      color: colors.ink,
    },
  },
} as const;
