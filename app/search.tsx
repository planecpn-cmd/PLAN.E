// PL-08 Search Results
import React, { useState } from 'react';
import { View, StyleSheet, ScrollView, FlatList } from 'react-native';
import { useRouter } from 'expo-router';
import { Screen } from '@/components/Screen';
import { Input } from '@/components/Input';
import { Chip } from '@/components/Chip';
import { ExperienceCard } from '@/components/ExperienceCard';
import { Skeleton } from '@/components/Skeleton';
import { EmptyState } from '@/components/EmptyState';
import { ErrorState } from '@/components/ErrorState';
import { useExperiences } from '@/hooks/useExperiences';
import { formatNpr } from '@/lib/format';
import { colors, spacing } from '@/theme/tokens';
import { typography } from '@/theme/typography';
import { t } from '@/i18n';

export default function SearchScreen() {
  const router = useRouter();
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedDifficulty, setSelectedDifficulty] = useState<string | undefined>();

  const { data: results, isLoading, error, refetch } = useExperiences({
    searchQuery: searchQuery ? searchQuery.trim() : undefined,
    difficulty: selectedDifficulty,
  });

  return (
    <Screen style={styles.container}>
      <Input
        placeholder="Search treks, homestays, regions..."
        value={searchQuery}
        onChangeText={setSearchQuery}
        style={styles.searchInput}
      />

      <View style={styles.filtersRow}>
        <ScrollView horizontal showsHorizontalScrollIndicator={false}>
          <Chip
            label="All Difficulties"
            selected={!selectedDifficulty}
            onPress={() => setSelectedDifficulty(undefined)}
          />
          <Chip
            label="Easy"
            selected={selectedDifficulty === 'easy'}
            onPress={() => setSelectedDifficulty('easy')}
          />
          <Chip
            label="Moderate"
            selected={selectedDifficulty === 'moderate'}
            onPress={() => setSelectedDifficulty('moderate')}
          />
          <Chip
            label="Challenging"
            selected={selectedDifficulty === 'challenging'}
            onPress={() => setSelectedDifficulty('challenging')}
          />
          <Chip
            label="Strenuous"
            selected={selectedDifficulty === 'strenuous'}
            onPress={() => setSelectedDifficulty('strenuous')}
          />
        </ScrollView>
      </View>

      {isLoading ? (
        <View style={styles.listContainer}>
          <Skeleton width="100%" height={180} style={{ marginBottom: spacing.md }} />
          <Skeleton width="100%" height={180} />
        </View>
      ) : error ? (
        <ErrorState message="Search failed. Please try again." onRetry={refetch} />
      ) : !results?.length ? (
        <EmptyState
          title="No Experiences Found"
          description="Try adjusting your search terms or filters."
        />
      ) : (
        <FlatList
          data={results}
          keyExtractor={(item) => item.id}
          renderItem={({ item }) => (
            <View style={styles.cardWrapper}>
              <ExperienceCard
                title={item.title}
                location={item.location_name || 'Nepal'}
                rating={Number(item.rating_avg)}
                reviewCount={item.rating_count}
                formattedPrice={formatNpr(item.price_paisa)}
                imageUrl={item.cover_image_url}
                onPress={() => router.push(`/experience/${item.id}`)}
              />
            </View>
          )}
          contentContainerStyle={styles.listContainer}
        />
      )}
    </Screen>
  );
}

const styles = StyleSheet.create({
  container: {
    padding: spacing.lg,
  },
  searchInput: {
    marginBottom: spacing.md,
  },
  filtersRow: {
    marginBottom: spacing.lg,
  },
  listContainer: {
    paddingBottom: spacing.xxl,
  },
  cardWrapper: {
    marginBottom: spacing.md,
    alignItems: 'center',
  },
});
