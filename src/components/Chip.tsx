import React from 'react';
import { TouchableOpacity, Text, StyleSheet, ViewStyle } from 'react-native';
import { colors, radii, touchTarget, spacing } from '@/theme/tokens';
import { typography } from '@/theme/typography';

interface ChipProps {
  label: string;
  selected: boolean;
  onPress: () => void;
  style?: ViewStyle;
}

export function Chip({ label, selected, onPress, style }: ChipProps) {
  return (
    <TouchableOpacity
      style={[
        styles.chip,
        selected ? styles.selectedChip : styles.unselectedChip,
        style,
      ]}
      onPress={onPress}
      activeOpacity={0.8}
    >
      <Text style={[typography.styles.bodyMedium, selected ? styles.selectedText : styles.unselectedText]}>
        {selected ? `✓ ${label}` : label}
      </Text>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  chip: {
    minHeight: touchTarget.minHeight,
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.sm,
    borderRadius: radii.pill,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 1.5,
    marginRight: spacing.sm,
  },
  selectedChip: {
    backgroundColor: colors.forest,
    borderColor: colors.forest,
  },
  unselectedChip: {
    backgroundColor: colors.white,
    borderColor: colors.sage,
  },
  selectedText: {
    color: colors.white,
    fontWeight: 'bold',
  },
  unselectedText: {
    color: colors.ink,
    fontWeight: '500',
  },
});
