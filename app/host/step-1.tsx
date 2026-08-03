// RM-22 Host Application Step 1
// ASSUMPTION: Step 1 collects personal & contact info
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

export default function HostStep1Screen() {
  const router = useRouter();
  const [fullName, setFullName] = useState('');
  const [phone, setPhone] = useState('');

  return (
    <Screen style={styles.container}>
      <ProgressSteps
        currentStep={1}
        totalSteps={4}
        stepLabels={['Contact Info', 'Documents', 'Pricing', 'Review']}
      />

      <Text style={[typography.styles.headingLarge, styles.title]}>{t('host.step1Title')}</Text>

      <Input
        label="Full Name / Agency Name"
        placeholder="e.g. Pemba Sherpa / Himalayan Treks"
        value={fullName}
        onChangeText={setFullName}
      />
      <Input
        label="Contact Phone (+977)"
        placeholder="+97798XXXXXXXX"
        value={phone}
        onChangeText={setPhone}
        keyboardType="phone-pad"
      />

      <View style={styles.footer}>
        <Button
          title={t('common.next')}
          onPress={() => router.push('/host/step-2')}
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
