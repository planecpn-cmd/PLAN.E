// RM-23 Host Application Step 3
// ASSUMPTION: Step 3 collects pricing & availability settings
import React, { useState } from 'react';
import { View, StyleSheet, Text } from 'react-native';
import { useRouter } from 'expo-router';
import { Screen } from '@/components/Screen';
import { Button } from '@/components/Button';
import { Input } from '@/components/Input';
import { ProgressSteps } from '@/components/ProgressSteps';
import { spacing } from '@/theme/tokens';
import { typography } from '@/theme/typography';
import { t } from '@/i18n';

export default function HostStep3Screen() {
  const router = useRouter();
  const [price, setPrice] = useState('12500');

  return (
    <Screen style={styles.container}>
      <ProgressSteps
        currentStep={3}
        totalSteps={4}
        stepLabels={['Contact Info', 'Documents', 'Pricing', 'Review']}
      />

      <Text style={[typography.styles.headingLarge, styles.title]}>{t('host.step3Title')}</Text>

      <Input
        label="Base Price per Person (NPR)"
        placeholder="e.g. 12500"
        value={price}
        onChangeText={setPrice}
        keyboardType="numeric"
      />

      <View style={styles.footer}>
        <Button
          title="Back"
          onPress={() => router.back()}
          variant="text"
          style={{ marginBottom: spacing.xs }}
        />
        <Button
          title={t('common.next')}
          onPress={() => router.push('/host/step-4')}
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
  footer: {
    marginTop: spacing.xl,
  },
});
