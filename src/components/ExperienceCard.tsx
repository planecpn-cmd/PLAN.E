import React from 'react';
import { View, Text, StyleSheet, Image, TouchableOpacity } from 'react-native';
import { colors, radii, shadows, spacing } from '@/theme/tokens';
import { typography } from '@/theme/typography';

interface ExperienceCardProps {
  title: string;
  location: string;
  rating: number;
  reviewCount: number;
  formattedPrice: string;
  imageUrl?: string;
  spotsLeft?: number;
  onPress: () => void;
}

export function ExperienceCard({
  title,
  location,
  rating,
  reviewCount,
  formattedPrice,
  imageUrl,
  spotsLeft,
  onPress,
}: ExperienceCardProps) {
  return (
    <TouchableOpacity style={styles.container} onPress={onPress} activeOpacity={0.9}>
      <View style={styles.imageContainer}>
        {imageUrl ? (
          <Image source={{ uri: imageUrl }} style={styles.image} />
        ) : (
          <View style={styles.imagePlaceholder}>
            <Text style={styles.placeholderText}>🏔️</Text>
          </View>
        )}
        {spotsLeft !== undefined && spotsLeft <= 5 && (
          <View style={styles.spotsBadge}>
            <Text style={styles.spotsText}>{spotsLeft} spots left</Text>
          </View>
        )}
      </View>

      <View style={styles.details}>
        <Text style={typography.styles.caption} numberOfLines={1}>
          📍 {location}
        </Text>
        <Text style={[typography.styles.headingMedium, styles.title]} numberOfLines={1}>
          {title}
        </Text>
        
        <View style={styles.footer}>
          <View style={styles.ratingRow}>
            <Text style={styles.starText}>★</Text>
            <Text style={[typography.styles.bodyMedium, styles.ratingText]}>
              {rating.toFixed(1)} ({reviewCount})
            </Text>
          </View>
          <Text style={[typography.styles.bodyLarge, styles.priceText]}>
            {formattedPrice}
          </Text>
        </View>
      </View>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: colors.white,
    borderRadius: radii.md,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: colors.sage,
    width: 260,
    ...shadows.sm,
  },
  imageContainer: {
    height: 140,
    backgroundColor: colors.sage,
    position: 'relative',
  },
  image: {
    width: '100%',
    height: '100%',
  },
  imagePlaceholder: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  placeholderText: {
    fontSize: 32,
  },
  spotsBadge: {
    position: 'absolute',
    top: spacing.sm,
    left: spacing.sm,
    backgroundColor: colors.forest,
    paddingHorizontal: spacing.sm,
    paddingVertical: spacing.xs,
    borderRadius: radii.sm,
  },
  spotsText: {
    color: colors.white,
    fontSize: 11,
    fontWeight: 'bold',
  },
  details: {
    padding: spacing.md,
  },
  title: {
    marginTop: 2,
    marginBottom: spacing.sm,
  },
  footer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  ratingRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  starText: {
    color: colors.gold,
    fontSize: 14,
    marginRight: 2,
  },
  ratingText: {
    fontWeight: '600',
  },
  priceText: {
    color: colors.forest,
    fontWeight: 'bold',
  },
});
