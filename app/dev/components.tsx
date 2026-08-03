// Dev Component Gallery — All Phase S1 UI Primitives
import React, { useState } from 'react';
import { ScrollView, StyleSheet, View, Text } from 'react-native';
import { Screen } from '@/components/Screen';
import { Button } from '@/components/Button';
import { Card } from '@/components/Card';
import { ExperienceCard } from '@/components/ExperienceCard';
import { Chip } from '@/components/Chip';
import { Tabs } from '@/components/Tabs';
import { Input } from '@/components/Input';
import { Counter } from '@/components/Counter';
import { RatingStars } from '@/components/RatingStars';
import { SectionHeader } from '@/components/SectionHeader';
import { Rail } from '@/components/Rail';
import { Skeleton } from '@/components/Skeleton';
import { EmptyState } from '@/components/EmptyState';
import { ErrorState } from '@/components/ErrorState';
import { Toast } from '@/components/Toast';
import { BottomBar } from '@/components/BottomBar';
import { ProgressSteps } from '@/components/ProgressSteps';
import { colors, spacing } from '@/theme/tokens';
import { typography } from '@/theme/typography';

export default function DevComponentsGallery() {
  const [chipSelected, setChipSelected] = useState(true);
  const [activeTab, setActiveTab] = useState('tab1');
  const [counterVal, setCounterVal] = useState(2);

  return (
    <Screen scrollable contentContainerStyle={styles.container}>
      <Text style={typography.styles.displayMedium}>Component Gallery</Text>
      <Text style={[typography.styles.bodyMedium, styles.subHeader]}>
        Phase S1 — All Primitives & States
      </Text>

      {/* Buttons */}
      <View style={styles.section}>
        <SectionHeader title="Buttons" />
        <View style={styles.row}>
          <Button title="Primary" onPress={() => {}} variant="primary" />
          <Button title="Secondary" onPress={() => {}} variant="secondary" />
        </View>
        <View style={[styles.row, { marginTop: spacing.sm }]}>
          <Button title="Text Button" onPress={() => {}} variant="text" />
          <Button title="Disabled" onPress={() => {}} disabled />
        </View>
      </View>

      {/* Chips */}
      <View style={styles.section}>
        <SectionHeader title="Chips (Filter Pills)" />
        <View style={styles.row}>
          <Chip label="Selected Trek" selected={chipSelected} onPress={() => setChipSelected(!chipSelected)} />
          <Chip label="Unselected Stay" selected={!chipSelected} onPress={() => setChipSelected(!chipSelected)} />
        </View>
      </View>

      {/* Tabs */}
      <View style={styles.section}>
        <SectionHeader title="Tabs" />
        <Tabs
          tabs={[
            { id: 'tab1', label: 'Upcoming' },
            { id: 'tab2', label: 'Drafts' },
          ]}
          activeTabId={activeTab}
          onSelectTab={setActiveTab}
        />
      </View>

      {/* Form Controls */}
      <View style={styles.section}>
        <SectionHeader title="Form Controls" />
        <Input label="Full Name" placeholder="e.g. Pasang Lhamu" />
        <Input label="Email Address" placeholder="pasang@example.com" error="Invalid email address" />
        <Counter label="Number of Guests" value={counterVal} onChange={setCounterVal} />
      </View>

      {/* Cards & Experience Cards */}
      <View style={styles.section}>
        <SectionHeader title="Cards & Rails" />
        <Card style={styles.cardMargin}>
          <Text style={typography.styles.headingMedium}>Standard Card</Text>
          <Text style={typography.styles.bodyMedium}>Card container with background, elevation and borders.</Text>
        </Card>

        <Rail>
          <ExperienceCard
            title="Everest Base Camp Trek"
            location="Solukhumbu"
            rating={4.9}
            reviewCount={128}
            formattedPrice="Rs. 1,25,000"
            spotsLeft={3}
            onPress={() => {}}
          />
          <ExperienceCard
            title="Pokhara Paragliding"
            location="Kaski"
            rating={4.8}
            reviewCount={64}
            formattedPrice="Rs. 12,500"
            spotsLeft={8}
            onPress={() => {}}
          />
        </Rail>
      </View>

      {/* Rating & Ratings */}
      <View style={styles.section}>
        <SectionHeader title="Rating Stars" />
        <RatingStars rating={4.7} reviewCount={42} />
      </View>

      {/* Progress Steps */}
      <View style={styles.section}>
        <SectionHeader title="Progress Steps" />
        <ProgressSteps
          currentStep={2}
          totalSteps={4}
          stepLabels={['Personal Info', 'Identity Verification', 'Pricing', 'Review']}
        />
      </View>

      {/* Skeletons */}
      <View style={styles.section}>
        <SectionHeader title="Skeleton Loading" />
        <Skeleton width="100%" height={24} style={{ marginBottom: spacing.xs }} />
        <Skeleton width="60%" height={16} />
      </View>

      {/* Empty & Error States */}
      <View style={styles.section}>
        <SectionHeader title="Empty & Error States" />
        <Card style={{ marginBottom: spacing.md }}>
          <EmptyState
            title="No Saved Trips Yet"
            description="Explore Nepal experiences and tap the heart icon to save them."
            actionTitle="Start Exploring"
            onAction={() => {}}
          />
        </Card>
        <Card>
          <ErrorState
            message="Could not load experiences. Please check your connection."
            onRetry={() => {}}
          />
        </Card>
      </View>

      {/* Toast & BottomBar */}
      <View style={styles.section}>
        <SectionHeader title="Toast & Bottom Bar" />
        <Toast message="Saved to wishlist" type="success" style={{ marginBottom: spacing.md }} />
        <BottomBar formattedPrice="Rs. 1,25,000" ctaTitle="Join Experience" onCtaPress={() => {}} />
      </View>
    </Screen>
  );
}

const styles = StyleSheet.create({
  container: {
    padding: spacing.lg,
  },
  subHeader: {
    color: colors.ink,
    opacity: 0.7,
    marginBottom: spacing.xl,
  },
  section: {
    marginBottom: spacing.xxl,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
  },
  cardMargin: {
    marginBottom: spacing.md,
  },
});
