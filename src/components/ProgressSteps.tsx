import React from 'react';
import { View, Text, StyleSheet, ViewStyle } from 'react-native';
import { colors, radii, spacing } from '@/theme/tokens';
import { typography } from '@/theme/typography';

interface ProgressStepsProps {
  currentStep: number; // 1-indexed
  totalSteps: number;
  stepLabels?: string[];
  style?: ViewStyle;
}

export function ProgressSteps({
  currentStep,
  totalSteps,
  stepLabels,
  style,
}: ProgressStepsProps) {
  return (
    <View style={[styles.container, style]}>
      <View style={styles.barRow}>
        {Array.from({ length: totalSteps }).map((_, index) => {
          const stepNum = index + 1;
          const isCompleted = stepNum < currentStep;
          const isCurrent = stepNum === currentStep;

          return (
            <View
              key={index}
              style={[
                styles.stepSegment,
                isCompleted && styles.completedSegment,
                isCurrent && styles.currentSegment,
              ]}
            />
          );
        })}
      </View>
      {stepLabels && stepLabels[currentStep - 1] && (
        <Text style={[typography.styles.caption, styles.label]}>
          Step {currentStep} of {totalSteps}: {stepLabels[currentStep - 1]}
        </Text>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    marginVertical: spacing.md,
  },
  barRow: {
    flexDirection: 'row',
    gap: spacing.xs,
  },
  stepSegment: {
    flex: 1,
    height: 6,
    borderRadius: radii.pill,
    backgroundColor: colors.sage,
  },
  completedSegment: {
    backgroundColor: colors.forest,
  },
  currentSegment: {
    backgroundColor: colors.gold,
  },
  label: {
    marginTop: spacing.xs,
    color: colors.ink,
    textAlign: 'center',
    fontWeight: '600',
  },
});
