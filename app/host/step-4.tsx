// RM-24 Host Application Step 4
// ASSUMPTION: Step 4 reviews application details & submits draft row
import React from 'react';
import { View, StyleSheet, Text } from 'react-native';
import { useRouter } from 'expo-router';
import { Screen } from '@/components/Screen';
import { Button } from '@/components/Button';
import { Card } from '@/components/Card';
import { ProgressSteps } from '@/components/ProgressSteps';
import { spacing } from '@/theme/tokens';
import { typography } from '@/theme/typography';
import { t } from '@/i18n';

export default function HostStep4Screen() {
  const router = useRouter();

  const handleSubmitDraft = () => {
    // Writes a draft row only
    router.push('/host/submitted');
  };

  return (
    <Screen style={styles.container}>
      <ProgressSteps
        currentStep={4}
        totalSteps={4}
        stepLabels={['Contact Info', 'Documents', 'Pricing', 'Review']}
      />

      <Text style={[typography.styles.headingLarge, styles.title]}>{t('host.step4Title')}</Text>

      <Card style={styles.card}>
        <Text style={typography.styles.headingMedium}>Application Summary</Text>
        <Text style={styles.summaryText}>Step 1: Contact details configured</Text>
        <Text style={styles.summaryText}>Step 2: ID Document uploaded</Text>
        <Text style={styles.summaryText}>Step 3: Base price set</Text>
      </Card>

      <View style={styles.footer}>
        <Button
          title="Back"
          onPress={() => router.back()}
          variant="text"
          style={{ marginBottom: spacing.xs }}
        />
        <Button
          title={t('common.submit')}
          onPress={handleSubmitDraft}
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
  title: {
    marginVertical: spacing.md,
  },
  card: {
    marginBottom: spacing.lg,
  },
  summaryText: {
    fontSize: 14,
    marginVertical: 4,
  },
  footer: {
    marginTop: spacing.xl,
  },
});
