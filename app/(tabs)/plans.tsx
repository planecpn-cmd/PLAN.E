// PL-13 My Plans (Upcoming) / PL-14 My Plans (Drafts)
import React, { useState } from 'react';
import { View, StyleSheet, Text } from 'react-native';
import { Screen } from '@/components/Screen';
import { Tabs } from '@/components/Tabs';
import { Card } from '@/components/Card';
import { EmptyState } from '@/components/EmptyState';
import { Skeleton } from '@/components/Skeleton';
import { ErrorState } from '@/components/ErrorState';
import { useBookings } from '@/hooks/useBookings';
import { colors, spacing } from '@/theme/tokens';
import { typography } from '@/theme/typography';

export default function PlansScreen() {
  const [activeTab, setActiveTab] = useState<'upcoming' | 'drafts'>('upcoming');
  const { data: bookings, isLoading, error, refetch } = useBookings(
    activeTab === 'upcoming' ? 'confirmed' : 'pending',
  );

  return (
    <Screen style={styles.container}>
      <Text style={[typography.styles.headingLarge, styles.title]}>PL-13 / PL-14 My Plans</Text>

      <Tabs
        tabs={[
          { id: 'upcoming', label: 'Upcoming Trips' },
          { id: 'drafts', label: 'Saved Drafts' },
        ]}
        activeTabId={activeTab}
        onSelectTab={(id) => setActiveTab(id as any)}
        style={styles.tabs}
      />

      {isLoading ? (
        <View style={styles.list}>
          <Skeleton width="100%" height={100} style={{ marginBottom: spacing.md }} />
          <Skeleton width="100%" height={100} />
        </View>
      ) : error ? (
        <ErrorState message="Could not load your trip plans." onRetry={refetch} />
      ) : !bookings?.length ? (
        <Card style={styles.emptyCard}>
          <EmptyState
            title={activeTab === 'upcoming' ? 'No Upcoming Trips' : 'No Saved Drafts'}
            description={
              activeTab === 'upcoming'
                ? 'Your confirmed mountain adventures will appear here once booked.'
                : 'Unfinished trip bookings will be saved here as drafts.'
            }
          />
        </Card>
      ) : (
        <View style={styles.list}>
          {bookings.map((booking: any) => (
            <Card key={booking.id} style={styles.bookingCard}>
              <Text style={typography.styles.headingMedium}>Ref: {booking.booking_ref}</Text>
              <Text style={typography.styles.bodyMedium}>
                {booking.experiences?.title || 'Nepal Experience'}
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
    marginBottom: spacing.md,
  },
  tabs: {
    marginBottom: spacing.lg,
  },
  list: {
    flex: 1,
  },
  emptyCard: {
    marginTop: spacing.md,
  },
  bookingCard: {
    marginBottom: spacing.md,
  },
});
