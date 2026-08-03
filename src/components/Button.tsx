import React from 'react';
import { TouchableOpacity, Text, StyleSheet, ViewStyle, TextStyle, ActivityIndicator } from 'react-native';
import { colors, radii, touchTarget, spacing } from '@/theme/tokens';
import { typography } from '@/theme/typography';

interface ButtonProps {
  title: string;
  onPress: () => void;
  variant?: 'primary' | 'secondary' | 'text';
  disabled?: boolean;
  loading?: boolean;
  style?: ViewStyle;
  textStyle?: TextStyle;
}

export function Button({
  title,
  onPress,
  variant = 'primary',
  disabled = false,
  loading = false,
  style,
  textStyle,
}: ButtonProps) {
  const isPrimary = variant === 'primary';
  const isSecondary = variant === 'secondary';
  const isText = variant === 'text';

  const containerStyle = [
    styles.base,
    isPrimary && styles.primary,
    isSecondary && styles.secondary,
    isText && styles.textVariant,
    disabled && styles.disabled,
    style,
  ];

  const textStyles = [
    typography.styles.bodyLarge,
    styles.baseText,
    isPrimary && styles.primaryText,
    isSecondary && styles.secondaryText,
    isText && styles.textVariantText,
    disabled && styles.disabledText,
    textStyle,
  ];

  return (
    <TouchableOpacity
      style={containerStyle}
      onPress={onPress}
      disabled={disabled || loading}
      activeOpacity={0.8}
    >
      {loading ? (
        <ActivityIndicator color={isPrimary ? colors.white : colors.forest} />
      ) : (
        <Text style={textStyles}>{title}</Text>
      )}
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  base: {
    minHeight: touchTarget.minHeight,
    paddingHorizontal: spacing.xl,
    paddingVertical: spacing.md,
    borderRadius: radii.pill,
    justifyContent: 'center',
    alignItems: 'center',
    flexDirection: 'row',
  },
  primary: {
    backgroundColor: colors.forest,
  },
  secondary: {
    backgroundColor: colors.sage,
    borderWidth: 1,
    borderColor: colors.forest,
  },
  textVariant: {
    backgroundColor: colors.transparent,
    paddingHorizontal: spacing.sm,
  },
  disabled: {
    backgroundColor: colors.sage,
    borderColor: colors.transparent,
    opacity: 0.6,
  },
  baseText: {
    fontWeight: '600',
  },
  primaryText: {
    color: colors.white,
  },
  secondaryText: {
    color: colors.forest,
  },
  textVariantText: {
    color: colors.gold,
  },
  disabledText: {
    color: colors.ink,
    opacity: 0.5,
  },
});
