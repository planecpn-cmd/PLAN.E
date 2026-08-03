// PL-09 Experience Details
import React, { useState } from 'react';
import { View, Text, StyleSheet, Image, ScrollView, TouchableOpacity } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { Screen } from '@/components/Screen';
import { Button } from '@/components/Button';
import { RatingStars } from '@/components/RatingStars';
import { BottomBar } from '@/components/BottomBar';
import { Skeleton } from '@/components/Skeleton';
import { ErrorState } from '@/components/ErrorState';
import { useExperience } from '@/hooks/useExperience';
import { useSessionStore } from '@/stores/sessionStore';
import { useDeferredActionStore } from '@/stores/deferredActionStore';
import { formatNpr, formatDuration } from '@/lib/format';
import { colors, radii, spacing, shadows } from '@/theme/tokens';
import { typography } from '@/theme/typography';
import { t } from '@/i18n';

export default function ExperienceDetailsScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { data: experience, isLoading, error, refetch } = useExperience(id || '');
  const isAuthenticated = useSessionStore((state) => state.isAuthenticated);
  const setPendingAction = useDeferredActionStore((state) => state.setPendingAction);

  const [isSaved, setIsSaved] = useState(false);

  const handleToggleSave = () => {
    if (!isAuthenticated) {
      setPendingAction({
        screenId: 'PL-09',
        entityId: id,
        action: 'save_experience',
      });
      router.push('/(auth)/auth-required-modal');
      return;
    }
    // Optimistic toggle
    setIsSaved(!isSaved);
  };

  if (isLoading) {
    return (
      <Screen style={styles.loadingContainer}>
        <Skeleton width="100%" height={260} borderRadius={0} />
        <View style={styles.paddingContainer}>
          <Skeleton width="40%" height={20} style={{ marginBottom: spacing.sm }} />
          <Skeleton width="80%" height={28} style={{ marginBottom: spacing.md }} />
          <Skeleton width="100%" height={100} />
        </View>
      </Screen>
    );
  }

  if (error || !experience) {
    return (
      <Screen style={styles.centerContainer}>
        <ErrorState message="Could not load experience details." onRetry={refetch} />
      </Screen>
    );
  }

  return (
    <View style={styles.mainWrapper}>
      <ScrollView contentContainerStyle={styles.scrollContent}>
        {/* Section 1: Cover Image & Gallery */}
        <View style={styles.coverContainer}>
          <Image source={{ uri: experience.cover_image_url }} style={styles.coverImage} />
          <TouchableOpacity style={styles.heartButton} onPress={handleToggleSave}>
            <Text style={styles.heartIcon}>{isSaved ? '❤️' : '🤍'}</Text>
          </TouchableOpacity>
        </View>

        <View style={styles.detailsBody}>
          {/* Section 2: Spots Left Status */}
          <View style={styles.spotsBadge}>
            <Text style={styles.spotsText}>🔥 3 {t('experience.spotsLeft')}</Text>
          </View>

          {/* Section 3: Title / Location / Rating */}
          <Text style={[typography.styles.caption, styles.locationText]}>
            📍 {experience.location_name || 'Nepal'}
          </Text>
          <Text style={[typography.styles.headingLarge, styles.title]}>{experience.title}</Text>
          <RatingStars rating={Number(experience.rating_avg)} reviewCount={experience.rating_count} />

          {/* Section 4: Duration / Difficulty / Max Altitude / Group Size */}
          <View style={styles.chipsRow}>
            <View style={styles.metaPill}>
              <Text style={styles.metaPillText}>⏱️ {formatDuration(experience.duration_hours)}</Text>
            </View>
            <View style={styles.metaPill}>
              <Text style={styles.metaPillText}>⚡ {experience.difficulty}</Text>
            </View>
            {experience.max_altitude_m && (
              <View style={styles.metaPill}>
                <Text style={styles.metaPillText}>⛰️ {experience.max_altitude_m}m</Text>
              </View>
            )}
            <View style={styles.metaPill}>
              <Text style={styles.metaPillText}>👥 {experience.group_size_min}-{experience.group_size_max} max</Text>
            </View>
          </View>

          {/* Section 5: Trip Overview */}
          <View style={styles.sectionDivider}>
            <Text style={[typography.styles.headingMedium, styles.sectionHeader]}>
              {t('experience.overview')}
            </Text>
            <Text style={[typography.styles.bodyMedium, styles.bodyText]}>
              {experience.description || experience.summary}
            </Text>
          </View>

          {/* Section 6: Price */}
          <View style={styles.sectionDivider}>
            <Text style={[typography.styles.headingMedium, styles.sectionHeader]}>Pricing</Text>
            <Text style={[typography.styles.headingLarge, styles.priceValue]}>
              {formatNpr(experience.price_paisa)}{' '}
              <Text style={typography.styles.caption}>/ adult</Text>
            </Text>
          </View>

          {/* Section 7: What's Included */}
          {experience.included?.length > 0 && (
            <View style={styles.sectionDivider}>
              <Text style={[typography.styles.headingMedium, styles.sectionHeader]}>
                {t('experience.whatsIncluded')}
              </Text>
              {experience.included.map((item: string, idx: number) => (
                <Text key={idx} style={[typography.styles.bodyMedium, styles.listItem]}>
                  ✓ {item}
                </Text>
              ))}
            </View>
          )}

          {/* Section 8: What to Bring */}
          {experience.bring_list?.length > 0 && (
            <View style={styles.sectionDivider}>
              <Text style={[typography.styles.headingMedium, styles.sectionHeader]}>
                {t('experience.whatToBring')}
              </Text>
              {experience.bring_list.map((item: string, idx: number) => (
                <Text key={idx} style={[typography.styles.bodyMedium, styles.listItem]}>
                  🎒 {item}
                </Text>
              ))}
            </View>
          )}

          {/* Section 9: Meeting Point */}
          <View style={styles.sectionDivider}>
            <Text style={[typography.styles.headingMedium, styles.sectionHeader]}>
              {t('experience.meetingPoint')}
            </Text>
            <Text style={[typography.styles.bodyMedium, styles.bodyText]}>
              📍 {experience.meeting_point || experience.location_name || 'Meeting details provided on booking confirmation.'}
            </Text>
          </View>

          {/* Section 10: Participants Preview */}
          <View style={styles.sectionDivider}>
            <Text style={[typography.styles.headingMedium, styles.sectionHeader]}>
              Trip Participants
            </Text>
            <Text style={[typography.styles.bodyMedium, styles.bodyText]}>
              4 travelers joined this upcoming departure date.
            </Text>
          </View>

          {/* Section 11: Things to Know */}
          {experience.things_to_know?.length > 0 && (
            <View style={styles.sectionDivider}>
              <Text style={[typography.styles.headingMedium, styles.sectionHeader]}>
                {t('experience.thingsToKnow')}
              </Text>
              {experience.things_to_know.map((item: string, idx: number) => (
                <Text key={idx} style={[typography.styles.bodyMedium, styles.listItem]}>
                  ℹ️ {item}
                </Text>
              ))}
            </View>
          )}

          {/* Section 12: Traveler Reviews */}
          <View style={styles.sectionDivider}>
            <Text style={[typography.styles.headingMedium, styles.sectionHeader]}>
              {t('experience.reviews')}
            </Text>
            <RatingStars rating={Number(experience.rating_avg)} reviewCount={experience.rating_count} />
          </View>

          {/* Section 13: Local Organizer */}
          <View style={styles.sectionDivider}>
            <Text style={[typography.styles.headingMedium, styles.sectionHeader]}>
              {t('experience.organizer')}
            </Text>
            <Text style={[typography.styles.bodyMedium, styles.bodyText]}>
              Organized by Certified Nepal Mountain Guide
            </Text>
          </View>
        </View>
      </ScrollView>

      {/* Fixed Bottom Bar */}
      <BottomBar
        priceLabel={t('experience.fromPrice')}
        formattedPrice={formatNpr(experience.price_paisa)}
        ctaTitle={t('experience.joinCTA')}
        onCtaPress={() => router.push(`/booking/${experience.id}`)}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  mainWrapper: {
    flex: 1,
    backgroundColor: colors.ivory,
  },
  loadingContainer: {
    padding: 0,
  },
  centerContainer: {
    justifyContent: 'center',
    padding: spacing.lg,
  },
  paddingContainer: {
    padding: spacing.lg,
  },
  scrollContent: {
    paddingBottom: spacing.huge,
  },
  coverContainer: {
    height: 260,
    position: 'relative',
    backgroundColor: colors.sage,
  },
  coverImage: {
    width: '100%',
    height: '100%',
  },
  heartButton: {
    position: 'absolute',
    top: spacing.lg,
    right: spacing.lg,
    backgroundColor: colors.white,
    borderRadius: radii.pill,
    width: 44,
    height: 44,
    justifyContent: 'center',
    alignItems: 'center',
    ...shadows.sm,
  },
  heartIcon: {
    fontSize: 20,
  },
  detailsBody: {
    padding: spacing.lg,
  },
  spotsBadge: {
    alignSelf: 'flex-start',
    backgroundColor: colors.forest,
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.xs,
    borderRadius: radii.sm,
    marginBottom: spacing.xs,
  },
  spotsText: {
    color: colors.white,
    fontWeight: 'bold',
    fontSize: 12,
  },
  locationText: {
    color: colors.ink,
    opacity: 0.7,
    marginTop: spacing.xs,
  },
  title: {
    marginTop: 2,
    marginBottom: spacing.xs,
  },
  chipsRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing.xs,
    marginVertical: spacing.md,
  },
  metaPill: {
    backgroundColor: colors.sage,
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.xs,
    borderRadius: radii.pill,
  },
  metaPillText: {
    fontSize: 13,
    color: colors.ink,
    fontWeight: '600',
  },
  sectionDivider: {
    marginTop: spacing.xl,
    paddingTop: spacing.md,
    borderTopWidth: 1,
    borderTopColor: colors.sage,
  },
  sectionHeader: {
    marginBottom: spacing.xs,
  },
  bodyText: {
    color: colors.ink,
    lineHeight: 22,
  },
  priceValue: {
    color: colors.forest,
  },
  listItem: {
    color: colors.ink,
    marginVertical: 2,
  },
});
