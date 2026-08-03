// RM-13 Budget Tracker
import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { useLocalSearchParams } from 'expo-router';
import { Screen } from '@/components/Screen';
import { Card } from '@/components/Card';
import { Toast } from '@/components/Toast';
import { colors, spacing } from '@/theme/tokens';
import { typography } from '@/theme/typography';
import { t } from '@/i18n';

export default function BudgetTrackerScreen() {
  const { bookingId } = useLocalSearchParams<{ bookingId: string }>();

  return (
    <Screen style={styles.container}>
      <Text style={[typography.styles.headingLarge, styles.title]}>RM-13 Budget Tracker</Text>
      <Text style={[typography.styles.bodyMedium, styles.subtitle]}>
        Trip Expense Tracker for Booking: {bookingId}
      </Text>

      <Toast
        message="Trip Budget Tracker lands in Stage B (Phase 8)"
        type="info"
        style={{ marginBottom: spacing.lg }}
      />

      <Card style={styles.card}>
        <Text style={styles.icon}>💰</Text>
        <Text style={[typography.styles.headingMedium, styles.cardTitle]}>
          {t('common.comingSoonTitle')}
        </Text>
        <Text style={[typography.styles.bodyMedium, styles.body]}>
          Track personal spending, porter tips, and trail expenses in integer paisa during Phase 8.
        </Text>
      </Card>
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
  card: {
    alignItems: 'center',
    padding: spacing.xl,
  },
  icon: {
    fontSize: 44,
    marginBottom: spacing.sm,
  },
  cardTitle: {
    marginBottom: spacing.xs,
  },
  body: {
    textAlign: 'center',
    color: colors.ink,
    opacity: 0.7,
  },
});
