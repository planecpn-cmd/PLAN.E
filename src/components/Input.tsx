import React from 'react';
import { View, Text, TextInput, StyleSheet, ViewStyle, TextInputProps } from 'react-native';
import { colors, radii, spacing, touchTarget } from '@/theme/tokens';
import { typography } from '@/theme/typography';

interface InputProps extends TextInputProps {
  label?: string;
  error?: string;
  helperText?: string;
  containerStyle?: ViewStyle;
}

export function Input({
  label,
  error,
  helperText,
  containerStyle,
  style,
  ...props
}: InputProps) {
  return (
    <View style={[styles.container, containerStyle]}>
      {label && <Text style={[typography.styles.bodyMedium, styles.label]}>{label}</Text>}
      <TextInput
        style={[
          styles.input,
          error ? styles.inputError : null,
          style,
        ]}
        placeholderTextColor="#8E9995"
        {...props}
      />
      {error ? (
        <Text style={[typography.styles.caption, styles.errorText]}>{error}</Text>
      ) : helperText ? (
        <Text style={[typography.styles.caption, styles.helperText]}>{helperText}</Text>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    marginBottom: spacing.md,
  },
  label: {
    fontWeight: '600',
    color: colors.ink,
    marginBottom: spacing.xs,
  },
  input: {
    minHeight: touchTarget.minHeight,
    backgroundColor: colors.white,
    borderWidth: 1,
    borderColor: colors.sage,
    borderRadius: radii.md,
    paddingHorizontal: spacing.lg,
    fontSize: 16,
    color: colors.ink,
  },
  inputError: {
    borderColor: colors.error,
  },
  errorText: {
    color: colors.error,
    marginTop: spacing.xs,
  },
  helperText: {
    color: colors.ink,
    opacity: 0.6,
    marginTop: spacing.xs,
  },
});
