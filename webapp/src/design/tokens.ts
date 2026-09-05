// Single source of truth for design tokens — mirrored into globals.css `@theme`.
// Values transcribed exactly from docs/MOBILE_UI_SPEC.md (lib/theme/tokens.dart).
// Do not edit colors/spacing/radii here without updating globals.css to match.

export const colors = {
  forest: "#18372D",
  deep: "#01251C",
  ivory: "#FFFFFF",
  white: "#FFFFFF",
  sage: "#E7ECE7",
  ink: "#24312D",
  gold: "#8F5E1B",
  error: "#BA1A1A",
  errorContainer: "#FFDAD6",
  success: "#2E6C40",
  successContainer: "#D2E8D4",
  warning: "#7D5200",
  warningContainer: "#FFDDB3",
  border: "#CBD5CE",
  borderSubtle: "#E2E8E4",
  cardBackground: "#FFFFFF",
  cardBackgroundAlt: "#FAF8F5",
  skeletonBase: "#E3E8E4",
  skeletonHighlight: "#F2F5F3",
} as const;

// 4 / 8 / 12 / 16 / 20 / 24 / 32 / 40 — use only these values.
export const spacing = {
  xs4: 4,
  sm8: 8,
  md12: 12,
  lg16: 16,
  xl20: 20,
  xxl24: 24,
  xxxl32: 32,
  huge40: 40,
} as const;

export const radii = {
  sm: 8,
  md: 16, // cards
  lg: 24,
  pill: 999,
} as const;

export const touchTarget = {
  touchMin: 48, // touch viewports
  pointerMin: 32, // desktop pointer
} as const;

// Serif display / sans body — the one deliberate contrast in the design language.
export const fonts = {
  display: "var(--font-playfair)", // Playfair Display
  sans: "var(--font-inter)", // Inter
} as const;

export const type = {
  displayLarge: { size: 32, weight: 700, face: "display" },
  displayMedium: { size: 28, weight: 700, face: "display" },
  headingLarge: { size: 24, weight: 700, face: "display" },
  headingMedium: { size: 20, weight: 600, face: "display" },
  bodyLarge: { size: 16, weight: 400, face: "sans" },
  bodyMedium: { size: 14, weight: 400, face: "sans" },
  caption: { size: 12, weight: 400, face: "sans" },
} as const;

export const breakpoints = {
  base: 0,
  md: 768,
  lg: 1024,
  xl: 1440,
} as const;
