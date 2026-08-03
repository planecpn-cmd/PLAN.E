import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ViewStyle } from 'react-native';
import { colors, radii, spacing, touchTarget } from '@/theme/tokens';
import { typography } from '@/theme/typography';

interface CounterProps {
  label?: string;
  value: number;
  min?: number;
  max?: number;
  onChange: (value: number) => void;
  style?: ViewStyle;
}

export function Counter({
  label,
  value,
  min = 0,
  max = 99,
  onChange,
  style,
}: CounterProps) {
  const canDecrement = value > min;
  const canIncrement = value < max;

  return (
    <View style={[styles.container, style]}>
      {label && <Text style={[typography.styles.bodyLarge, styles.label]}>{label}</Text>}
      <View style={styles.controls}>
        <TouchableOpacity
          style={[styles.button, !canDecrement && styles.disabledButton]}
          onPress={() => canDecrement && onChange(value - 1)}
          disabled={!canDecrement}
        >
          <Text style={[styles.buttonText, !canDecrement && styles.disabledText]}>-</Text>
        </TouchableOpacity>

        <Text style={[typography.styles.headingMedium, styles.valueText]}>{value}</Text>

        <TouchableOpacity
          style={[styles.button, !canIncrement && styles.disabledButton]}
          onPress={() => canIncrement && onChange(value + 1)}
          disabled={!canIncrement}
        >
          <Text style={[styles.buttonText, !canIncrement && styles.disabledText]}>+</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: spacing.sm,
  },
  label: {
    fontWeight: '500',
  },
  controls: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  button: {
    minWidth: touchTarget.minWidth,
    minHeight: touchTarget.minHeight,
    borderRadius: radii.sm,
    backgroundColor: colors.sage,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: colors.forest,
  },
  disabledButton: {
    borderColor: colors.sage,
    opacity: 0.5,
  },
  buttonText: {
    fontSize: 20,
    fontWeight: 'bold',
    color: colors.forest,
  },
  disabledText: {
    color: colors.ink,
  },
  valueText: {
    marginHorizontal: spacing.lg,
    minWidth: 24,
    textAlign: 'center',
  },
});
