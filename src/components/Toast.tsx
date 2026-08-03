import React from 'react';
import { View, Text, StyleSheet, ViewStyle } from 'react-native';
import { colors, radii, shadows, spacing } from '@/theme/tokens';
import { typography } from '@/theme/typography';

interface ToastProps {
  message: string;
  type?: 'info' | 'success' | 'error';
  style?: ViewStyle;
}

export function Toast({ message, type = 'info', style }: ToastProps) {
  const isError = type === 'error';
  const isSuccess = type === 'success';

  return (
    <View
      style={[
        styles.container,
        isError && styles.errorContainer,
        isSuccess && styles.successContainer,
        style,
      ]}
    >
      <Text style={[typography.styles.bodyMedium, styles.text]}>{message}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: colors.forest,
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.md,
    borderRadius: radii.md,
    ...shadows.md,
  },
  errorContainer: {
    backgroundColor: colors.error,
  },
  successContainer: {
    backgroundColor: colors.forest,
  },
  text: {
    color: colors.white,
    fontWeight: '600',
    textAlign: 'center',
  },
});
