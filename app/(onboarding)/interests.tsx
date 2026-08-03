// PL-05 Select Interests
import React from 'react';
import { View, Text, StyleSheet, ScrollView } from 'react-native';
import { useRouter } from 'expo-router';
import { Screen } from '@/components/Screen';
import { Button } from '@/components/Button';
import { Chip } from '@/components/Chip';
import { useCategories } from '@/hooks/useCategories';
import { useGuestStore } from '@/stores/guestStore';
import { Skeleton } from '@/components/Skeleton';
import { ErrorState } from '@/components/ErrorState';
import { colors, spacing } from '@/theme/tokens';
import { typography } from '@/theme/typography';
import { t } from '@/i18n';

export default function SelectInterestsScreen() {
  const router = useRouter();
  const { data: categories, isLoading, error, refetch } = useCategories();
  const { selectedInterests, toggleInterest } = useGuestStore();

  const canContinue = selectedInterests.length >= 3;

  return (
    <Screen style={styles.container}>
      <View style={styles.header}>
        <Text style={typography.styles.headingLarge}>{t('onboarding.interestsTitle')}</Text>
        <Text style={[typography.styles.bodyMedium, styles.subtitle]}>
          {t('onboarding.interestsSubtitle')}
        </Text>
      </View>

      {isLoading ? (
        <View style={styles.grid}>
          {Array.from({ length: 9 }).map((_, i) => (
            <Skeleton key={i} width={100} height={44} style={styles.skeletonChip} />
          ))}
        </View>
      ) : error ? (
        <ErrorState message="Could not load interest categories." onRetry={refetch} />
      ) : (
        <ScrollView contentContainerStyle={styles.grid}>
          {categories?.map((cat: any) => {
            const isSelected = selectedInterests.includes(cat.id);
            return (
              <Chip
                key={cat.id}
                label={`${cat.icon || ''} ${cat.name_en}`}
                selected={isSelected}
                onPress={() => toggleInterest(cat.id)}
                style={styles.chipMargin}
              />
            );
          })}
        </ScrollView>
      )}

      <View style={styles.footer}>
        <Text style={[typography.styles.caption, styles.counterText]}>
          Selected: {selectedInterests.length} / 3 minimum
        </Text>
        <Button
          title={t('common.continue')}
          onPress={() => router.replace('/(tabs)/home')}
          disabled={!canContinue}
        />
      </View>
    </Screen>
  );
}

const styles = StyleSheet.create({
  container: {
    padding: spacing.lg,
    justifyContent: 'space-between',
  },
  header: {
    marginBottom: spacing.lg,
  },
  subtitle: {
    color: colors.ink,
    opacity: 0.7,
    marginTop: spacing.xs,
  },
  grid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing.sm,
  },
  chipMargin: {
    marginBottom: spacing.sm,
  },
  skeletonChip: {
    borderRadius: 22,
  },
  footer: {
    marginTop: spacing.lg,
  },
  counterText: {
    textAlign: 'center',
    marginBottom: spacing.sm,
    color: colors.ink,
    fontWeight: '600',
  },
});
