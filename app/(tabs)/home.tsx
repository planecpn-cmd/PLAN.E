// PL-06 Home Screen
import React from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity } from 'react-native';
import { useRouter } from 'expo-router';
import { Screen } from '@/components/Screen';
import { SectionHeader } from '@/components/SectionHeader';
import { Rail } from '@/components/Rail';
import { ExperienceCard } from '@/components/ExperienceCard';
import { Skeleton } from '@/components/Skeleton';
import { EmptyState } from '@/components/EmptyState';
import { ErrorState } from '@/components/ErrorState';
import { useHomeRails } from '@/hooks/useHomeRails';
import { formatNpr } from '@/lib/format';
import { colors, radii, spacing, shadows } from '@/theme/tokens';
import { typography } from '@/theme/typography';
import { t } from '@/i18n';

export default function HomeScreen() {
  const router = useRouter();
  const { data, isLoading, error, refetch } = useHomeRails();

  return (
    <Screen scrollable style={styles.container}>
      {/* Top App Bar (Variant: Location + Notifications + Points) */}
      <View style={styles.appBar}>
        <View>
          <Text style={[typography.styles.caption, styles.locationLabel]}>📍 Location</Text>
          <Text style={[typography.styles.headingMedium, styles.locationText]}>Kathmandu, Nepal</Text>
        </View>

        <View style={styles.appBarActions}>
          <View style={styles.pointsChip}>
            <Text style={styles.pointsText}>🪙 50 pts</Text>
          </View>
          <TouchableOpacity style={styles.iconButton} onPress={() => router.push('/profile/notifications')}>
            <Text style={styles.iconText}>🔔</Text>
          </TouchableOpacity>
        </View>
      </View>

      {/* Hero Banner */}
      <View style={styles.heroBanner}>
        <Text style={styles.heroTag}>DESTINATION NEPAL</Text>
        <Text style={[typography.styles.headingLarge, styles.heroTitle]}>
          Find Your Next Himalayan Adventure
        </Text>
        <TouchableOpacity style={styles.heroButton} onPress={() => router.push('/search')}>
          <Text style={styles.heroButtonText}>Search Experiences 🔍</Text>
        </TouchableOpacity>
      </View>

      {/* Rail 1: Recommended for You */}
      <View style={styles.railSection}>
        <SectionHeader
          title={t('home.recommendedRail')}
          actionText="See All"
          onActionPress={() => router.push('/collection/recommended')}
        />
        {isLoading ? (
          <Rail>
            <Skeleton width={260} height={200} borderRadius={radii.md} />
            <Skeleton width={260} height={200} borderRadius={radii.md} />
          </Rail>
        ) : error ? (
          <ErrorState message="Could not load recommended experiences." onRetry={refetch} />
        ) : !data?.recommended.length ? (
          <EmptyState title="No Experiences Found" description="Check back soon for new additions." />
        ) : (
          <Rail>
            {data.recommended.map((exp: any) => (
              <ExperienceCard
                key={exp.id}
                title={exp.title}
                location={exp.location_name || 'Nepal'}
                rating={Number(exp.rating_avg)}
                reviewCount={exp.rating_count}
                formattedPrice={formatNpr(exp.price_paisa)}
                imageUrl={exp.cover_image_url}
                onPress={() => router.push(`/experience/${exp.id}`)}
              />
            ))}
          </Rail>
        )}
      </View>

      {/* Rail 2: Trending Treks & Adventures */}
      <View style={styles.railSection}>
        <SectionHeader
          title={t('home.trendingRail')}
          actionText="See All"
          onActionPress={() => router.push('/collection/trending')}
        />
        {isLoading ? (
          <Rail>
            <Skeleton width={260} height={200} borderRadius={radii.md} />
          </Rail>
        ) : error ? (
          <ErrorState message="Could not load trending treks." onRetry={refetch} />
        ) : !data?.trending.length ? (
          <EmptyState title="No Treks Found" description="Check back soon." />
        ) : (
          <Rail>
            {data.trending.map((exp: any) => (
              <ExperienceCard
                key={exp.id}
                title={exp.title}
                location={exp.location_name || 'Nepal'}
                rating={Number(exp.rating_avg)}
                reviewCount={exp.rating_count}
                formattedPrice={formatNpr(exp.price_paisa)}
                imageUrl={exp.cover_image_url}
                onPress={() => router.push(`/experience/${exp.id}`)}
              />
            ))}
          </Rail>
        )}
      </View>
    </Screen>
  );
}

const styles = StyleSheet.create({
  container: {
    paddingVertical: spacing.md,
  },
  appBar: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: spacing.lg,
    marginBottom: spacing.lg,
  },
  locationLabel: {
    color: colors.ink,
    opacity: 0.7,
  },
  locationText: {
    color: colors.forest,
  },
  appBarActions: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
  },
  pointsChip: {
    backgroundColor: colors.sage,
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.xs,
    borderRadius: radii.pill,
  },
  pointsText: {
    fontSize: 13,
    fontWeight: 'bold',
    color: colors.forest,
  },
  iconButton: {
    padding: spacing.xs,
  },
  iconText: {
    fontSize: 20,
  },
  heroBanner: {
    marginHorizontal: spacing.lg,
    backgroundColor: colors.forest,
    borderRadius: radii.md,
    padding: spacing.xl,
    marginBottom: spacing.xxl,
    ...shadows.md,
  },
  heroTag: {
    color: colors.gold,
    fontSize: 12,
    fontWeight: 'bold',
    letterSpacing: 1.5,
    marginBottom: spacing.xs,
  },
  heroTitle: {
    color: colors.ivory,
    marginBottom: spacing.lg,
  },
  heroButton: {
    backgroundColor: colors.gold,
    paddingVertical: spacing.md,
    paddingHorizontal: spacing.lg,
    borderRadius: radii.pill,
    alignSelf: 'flex-start',
  },
  heroButtonText: {
    color: colors.white,
    fontWeight: 'bold',
    fontSize: 14,
  },
  railSection: {
    marginBottom: spacing.xxl,
  },
});
