// PL-12 Saved Experiences
import React, { useState } from 'react';
import { View, StyleSheet, FlatList, Text } from 'react-native';
import { useRouter } from 'expo-router';
import { Screen } from '@/components/Screen';
import { Tabs } from '@/components/Tabs';
import { ExperienceCard } from '@/components/ExperienceCard';
import { Skeleton } from '@/components/Skeleton';
import { EmptyState } from '@/components/EmptyState';
import { ErrorState } from '@/components/ErrorState';
import { useSaved } from '@/hooks/useSaved';
import { formatNpr } from '@/lib/format';
import { spacing } from '@/theme/tokens';
import { typography } from '@/theme/typography';

export default function SavedExperiencesScreen() {
  const router = useRouter();
  const [activeTab, setActiveTab] = useState('all');
  const { data: savedItems, isLoading, error, refetch } = useSaved();

  return (
    <Screen style={styles.container}>
      <Text style={[typography.styles.headingLarge, styles.title]}>PL-12 Saved Experiences</Text>

      <Tabs
        tabs={[
          { id: 'all', label: 'All Saved' },
          { id: 'treks', label: 'Treks' },
          { id: 'stays', label: 'Homestays' },
        ]}
        activeTabId={activeTab}
        onSelectTab={setActiveTab}
        style={styles.tabs}
      />

      {isLoading ? (
        <View style={styles.list}>
          <Skeleton width="100%" height={180} style={{ marginBottom: spacing.md }} />
        </View>
      ) : error ? (
        <ErrorState message="Could not load your saved experiences." onRetry={refetch} />
      ) : !savedItems?.length ? (
        <EmptyState
          title="No Saved Experiences Yet"
          description="Tap the heart icon on any experience to save it to your wishlist."
          actionTitle="Explore Nepal Experiences"
          onAction={() => router.push('/(tabs)/explore')}
        />
      ) : (
        <FlatList
          data={savedItems}
          keyExtractor={(item) => item.experience_id}
          renderItem={({ item }) => {
            const exp = item.experiences as any;
            if (!exp) return null;
            return (
              <View style={styles.cardWrapper}>
                <ExperienceCard
                  title={exp.title}
                  location={exp.location_name || 'Nepal'}
                  rating={Number(exp.rating_avg)}
                  reviewCount={exp.rating_count}
                  formattedPrice={formatNpr(exp.price_paisa)}
                  imageUrl={exp.cover_image_url}
                  onPress={() => router.push(`/experience/${exp.id}`)}
                />
              </View>
            );
          }}
          contentContainerStyle={styles.list}
        />
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
    paddingBottom: spacing.xxl,
  },
  cardWrapper: {
    marginBottom: spacing.md,
    alignItems: 'center',
  },
});
