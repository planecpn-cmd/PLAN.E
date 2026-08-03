import React from 'react';
import { ScrollView, StyleSheet, ViewStyle } from 'react-native';
import { spacing } from '@/theme/tokens';

interface RailProps {
  children: React.ReactNode;
  style?: ViewStyle;
}

export function Rail({ children, style }: RailProps) {
  return (
    <ScrollView
      horizontal
      showsHorizontalScrollIndicator={false}
      contentContainerStyle={[styles.content, style]}
    >
      {children}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  content: {
    paddingHorizontal: spacing.lg,
    gap: spacing.md,
  },
});
