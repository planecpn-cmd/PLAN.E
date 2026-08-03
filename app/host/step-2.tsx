// PL-19 Host Application Step 2
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

export default function HostStep2Screen() {
  const router = useRouter();

  return (
    <Screen style={styles.container}>
      <ProgressSteps
        currentStep={2}
        totalSteps={4}
        stepLabels={['Contact Info', 'Documents', 'Pricing', 'Review']}
      />

      <Text style={[typography.styles.headingLarge, styles.title]}>{t('host.step2Title')}</Text>

      <Card style={styles.card}>
        <Text style={styles.docIcon}>📄</Text>
        <Text style={typography.styles.headingMedium}>Upload Government ID / License</Text>
        <Text style={[typography.styles.bodyMedium, styles.docBody]}>
          Upload Citizenship card, Passport, or Trekking Guide License scan.
        </Text>
        <Button
          title="Select Document File"
          onPress={() => {}}
          variant="secondary"
        />
      </Card>

      <View style={styles.footer}>
        <Button
          title="Back"
          onPress={() => router.back()}
          variant="text"
          style={{ marginBottom: spacing.xs }}
        />
        <Button
          title={t('common.next')}
          onPress={() => router.push('/host/step-3')}
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
    alignItems: 'center',
    padding: spacing.xl,
  },
  docIcon: {
    fontSize: 44,
    marginBottom: spacing.sm,
  },
  docBody: {
    textAlign: 'center',
    marginBottom: spacing.lg,
    opacity: 0.7,
  },
  footer: {
    marginTop: spacing.xl,
  },
});
