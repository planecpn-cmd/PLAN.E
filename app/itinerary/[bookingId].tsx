// RM-10 Interactive Itinerary
import React from 'react';
import { View, Text, StyleSheet, ScrollView } from 'react-native';
import { useLocalSearchParams } from 'expo-router';
import { Screen } from '@/components/Screen';
import { Card } from '@/components/Card';
import { useExperience } from '@/hooks/useExperience';
import { Skeleton } from '@/components/Skeleton';
import { ErrorState } from '@/components/ErrorState';
import { EmptyState } from '@/components/EmptyState';
import { colors, spacing } from '@/theme/tokens';
import { typography } from '@/theme/typography';

export default function ItineraryScreen() {
  const { bookingId } = useLocalSearchParams<{ bookingId: string }>();
  const { data: experience, isLoading, error, refetch } = useExperience(bookingId || '');

  return (
    <Screen scrollable style={styles.container}>
      <Text style={[typography.styles.headingLarge, styles.title]}>RM-10 Interactive Itinerary</Text>
      <Text style={[typography.styles.bodyMedium, styles.subtitle]}>
        Day-by-day trail guide for Booking: {bookingId}
      </Text>

      {isLoading ? (
        <View style={styles.list}>
          <Skeleton width="100%" height={100} style={{ marginBottom: spacing.md }} />
          <Skeleton width="100%" height={100} />
        </View>
      ) : error ? (
        <ErrorState message="Could not load itinerary details." onRetry={refetch} />
      ) : !experience?.itinerary_items?.length ? (
        <Card style={styles.card}>
          <EmptyState
            title="Itinerary Details"
            description="Detailed day-by-day itinerary breakdown is prepared by the host upon booking confirmation."
          />
        </Card>
      ) : (
        <View style={styles.list}>
          {experience.itinerary_items.map((item: any) => (
            <Card key={item.id} style={styles.card}>
              <Text style={styles.dayBadge}>Day {item.day_number}</Text>
              <Text style={typography.styles.headingMedium}>{item.title}</Text>
              <Text style={[typography.styles.bodyMedium, styles.itemBody]}>
                {item.description}
              </Text>
            </Card>
          ))}
        </View>
      )}
    </Screen>
  );
}

const styles = StyleSheet.create({
  container: {
    padding: spacing.lg,
  },
  title: {
    marginBottom: 2,
  },
  subtitle: {
    color: colors.ink,
    opacity: 0.7,
    marginBottom: spacing.lg,
  },
  list: {
    paddingBottom: spacing.xxl,
  },
  card: {
    marginBottom: spacing.md,
  },
  dayBadge: {
    color: colors.gold,
    fontWeight: 'bold',
    fontSize: 12,
    marginBottom: spacing.xs,
  },
  itemBody: {
    color: colors.ink,
    marginTop: spacing.xs,
  },
});
