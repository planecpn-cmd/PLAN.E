import React from 'react';
import { View, Text, StyleSheet, ViewStyle } from 'react-native';
import { colors, radii, shadows, spacing } from '@/theme/tokens';
import { typography } from '@/theme/typography';
import { Button } from './Button';

interface BottomBarProps {
  priceLabel?: string;
  formattedPrice: string;
  ctaTitle: string;
  onCtaPress: () => void;
  style?: ViewStyle;
}

export function BottomBar({
  priceLabel = 'Total Price',
  formattedPrice,
  ctaTitle,
  onCtaPress,
  style,
}: BottomBarProps) {
  return (
    <View style={[styles.container, style]}>
      <View style={styles.priceContainer}>
        <Text style={[typography.styles.caption, styles.label]}>{priceLabel}</Text>
        <Text style={[typography.styles.headingLarge, styles.price]}>{formattedPrice}</Text>
      </View>
      <Button title={ctaTitle} onPress={onCtaPress} style={styles.button} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: colors.white,
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.md,
    borderTopWidth: 1,
    borderTopColor: colors.sage,
    ...shadows.md,
  },
  priceContainer: {
    flex: 1,
  },
  label: {
    color: colors.ink,
    opacity: 0.7,
  },
  price: {
    color: colors.forest,
    fontWeight: 'bold',
  },
  button: {
    minWidth: 140,
  },
});
