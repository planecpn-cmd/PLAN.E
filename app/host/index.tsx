// PL-18 Become a Host
import React from 'react';
import { View, Text, StyleSheet, ScrollView } from 'react-native';
import { useRouter } from 'expo-router';
import { Screen } from '@/components/Screen';
import { Button } from '@/components/Button';
import { Card } from '@/components/Card';
import { colors, radii, spacing, shadows } from '@/theme/tokens';
import { typography } from '@/theme/typography';
import { t } from '@/i18n';

export default function BecomeHostScreen() {
  const router = useRouter();

  return (
    <Screen scrollable style={styles.container}>
      <View style={styles.hero}>
        <Text style={styles.heroTag}>HOST COMMUNITY</Text>
        <Text style={[typography.styles.headingLarge, styles.title]}>{t('host.landingTitle')}</Text>
        <Text style={[typography.styles.bodyMedium, styles.subtitle]}>{t('host.landingSubtitle')}</Text>
      </View>

      <Card style={styles.card}>
        <Text style={[typography.styles.headingMedium, styles.cardTitle]}>How It Works</Text>
        <Text style={styles.stepItem}>1️⃣ Fill personal & organization contact info</Text>
        <Text style={styles.stepItem}>2️⃣ Upload identity & trekking license documents</Text>
        <Text style={styles.stepItem}>3️⃣ Set pricing & departure dates</Text>
        <Text style={styles.stepItem}>4️⃣ Submit for PLAN E verification</Text>
      </Card>

      <Button
        title={t('host.startApplication')}
        onPress={() => router.push('/host/step-1')}
        style={styles.button}
      />
    </Screen>
  );
}

const styles = StyleSheet.create({
  container: {
    padding: spacing.lg,
  },
  hero: {
    backgroundColor: colors.forest,
    padding: spacing.xl,
    borderRadius: radii.md,
    marginBottom: spacing.lg,
    ...shadows.md,
  },
  heroTag: {
    color: colors.gold,
    fontSize: 12,
    fontWeight: 'bold',
    letterSpacing: 1.5,
    marginBottom: spacing.xs,
  },
  title: {
    color: colors.ivory,
    marginBottom: spacing.xs,
  },
  subtitle: {
    color: colors.sage,
  },
  card: {
    marginBottom: spacing.xl,
  },
  cardTitle: {
    marginBottom: spacing.md,
  },
  stepItem: {
    fontSize: 15,
    color: colors.ink,
    marginVertical: spacing.xs,
  },
  button: {
    marginBottom: spacing.xxl,
  },
});
