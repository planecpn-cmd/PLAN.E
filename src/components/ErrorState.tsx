import React from 'react';
import { View, Text, StyleSheet, ViewStyle } from 'react-native';
import { colors, spacing } from '@/theme/tokens';
import { typography } from '@/theme/typography';
import { Button } from './Button';

interface ErrorStateProps {
  title?: string;
  message: string;
  onRetry?: () => void;
  style?: ViewStyle;
}

export function ErrorState({
  title = 'Something went wrong',
  message,
  onRetry,
  style,
}: ErrorStateProps) {
  return (
    <View style={[styles.container, style]}>
      <Text style={styles.icon}>⚠️</Text>
      <Text style={[typography.styles.headingLarge, styles.title]}>{title}</Text>
      <Text style={[typography.styles.bodyMedium, styles.message]}>{message}</Text>
      {onRetry && (
        <Button title="Try Again" onPress={onRetry} variant="secondary" style={styles.button} />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    padding: spacing.xxl,
    justifyContent: 'center',
    alignItems: 'center',
  },
  icon: {
    fontSize: 44,
    marginBottom: spacing.md,
  },
  title: {
    textAlign: 'center',
    marginBottom: spacing.xs,
    color: colors.error,
  },
  message: {
    textAlign: 'center',
    color: colors.ink,
    opacity: 0.8,
    marginBottom: spacing.lg,
  },
  button: {
    marginTop: spacing.sm,
  },
});
