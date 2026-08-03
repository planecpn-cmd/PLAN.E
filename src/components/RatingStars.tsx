import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { colors, spacing } from '@/theme/tokens';
import { typography } from '@/theme/typography';

interface RatingStarsProps {
  rating: number;
  reviewCount?: number;
}

export function RatingStars({ rating, reviewCount }: RatingStarsProps) {
  const rounded = Math.round(rating * 2) / 2;

  return (
    <View style={styles.container}>
      <Text style={styles.starText}>★</Text>
      <Text style={[typography.styles.bodyMedium, styles.ratingNumber]}>
        {rating.toFixed(1)}
      </Text>
      {reviewCount !== undefined && (
        <Text style={[typography.styles.caption, styles.countText]}>
          ({reviewCount} reviews)
        </Text>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  starText: {
    color: colors.gold,
    fontSize: 16,
    marginRight: spacing.xs,
  },
  ratingNumber: {
    fontWeight: 'bold',
    color: colors.ink,
    marginRight: spacing.xs,
  },
  countText: {
    color: colors.ink,
    opacity: 0.7,
  },
});
