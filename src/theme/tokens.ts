// src/theme/tokens.ts
export const colors = {
  forest: '#18372D',
  deep: '#01251C',
  ivory: '#F6F2E9',
  // Darkened gold from #B7802B to #8F5E1B to meet WCAG AA contrast ratio requirement (5.07:1 vs #F6F2E9)
  gold: '#8F5E1B',
  sage: '#E7ECE7',
  ink: '#24312D',
  white: '#FFFFFF',
  error: '#D32F2F',
  transparent: 'transparent',
} as const;

export const spacing = {
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 20,
  xxl: 24,
  xxxl: 32,
  huge: 40,
} as const;

export const radii = {
  sm: 8,
  md: 16,
  lg: 24,
  pill: 9999,
} as const;

export const touchTarget = {
  minHeight: 44,
  minWidth: 44,
} as const;

export const shadows = {
  sm: {
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.08,
    shadowRadius: 2,
    elevation: 2,
  },
  md: {
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.12,
    shadowRadius: 8,
    elevation: 4,
  },
} as const;
