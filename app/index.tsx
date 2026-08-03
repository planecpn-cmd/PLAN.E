// PL-01 Splash Screen
import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { useRouter } from 'expo-router';
import { Screen } from '@/components/Screen';
import { Button } from '@/components/Button';
import { colors, spacing } from '@/theme/tokens';
import { typography } from '@/theme/typography';
import { t } from '@/i18n';

export default function SplashScreen() {
  const router = useRouter();

  return (
    <Screen backgroundColor={colors.forest} style={styles.container}>
      <View style={styles.content}>
        <Text style={styles.nepalText}>NEPAL →</Text>
        <Text style={[typography.styles.displayLarge, styles.title]}>{t('common.appName')}</Text>
        <Text style={[typography.styles.bodyLarge, styles.tagline]}>{t('common.tagline')}</Text>
      </View>

      <View style={styles.footer}>
        <Button
          title={t('common.continue')}
          onPress={() => router.push('/(onboarding)/slide-1')}
          variant="secondary"
          style={styles.button}
        />
        <TouchableOpacity style={styles.devLink} onPress={() => router.push('/dev/routes')}>
          <Text style={styles.devText}>Open Route Index (/dev/routes)</Text>
        </TouchableOpacity>
      </View>
    </Screen>
  );
}

const styles = StyleSheet.create({
  container: {
    padding: spacing.xxl,
    justifyContent: 'space-between',
  },
  content: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  nepalText: {
    color: colors.gold,
    fontSize: 16,
    fontWeight: 'bold',
    letterSpacing: 2,
    marginBottom: spacing.xs,
  },
  title: {
    color: colors.ivory,
    fontSize: 40,
    lineHeight: 48,
    marginBottom: spacing.md,
  },
  tagline: {
    color: colors.sage,
    textAlign: 'center',
  },
  footer: {
    marginBottom: spacing.lg,
  },
  button: {
    marginBottom: spacing.md,
  },
  devLink: {
    alignItems: 'center',
    padding: spacing.xs,
  },
  devText: {
    color: colors.ivory,
    fontSize: 13,
    textDecorationLine: 'underline',
  },
});
