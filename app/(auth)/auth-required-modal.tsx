// RM-05 Authentication Required Modal
import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { useRouter } from 'expo-router';
import { Screen } from '@/components/Screen';
import { Button } from '@/components/Button';
import { Card } from '@/components/Card';
import { useDeferredActionStore } from '@/stores/deferredActionStore';
import { colors, spacing } from '@/theme/tokens';
import { typography } from '@/theme/typography';

export default function AuthRequiredModalScreen() {
  const router = useRouter();
  const pendingAction = useDeferredActionStore((state) => state.pendingAction);

  return (
    <Screen style={styles.container}>
      <Card style={styles.card}>
        <Text style={styles.icon}>🔐</Text>
        <Text style={[typography.styles.headingLarge, styles.title]}>
          RM-05 Authentication Required
        </Text>
        <Text style={[typography.styles.bodyMedium, styles.body]}>
          Please log in or sign up to complete your action ({pendingAction?.action || 'save'}).
        </Text>

        <Button
          title="Sign Up New Account"
          onPress={() => router.push('/(auth)/sign-up')}
          style={styles.button}
        />
        <Button
          title="Log In Existing Account"
          onPress={() => router.push('/(auth)/login')}
          variant="secondary"
          style={styles.button}
        />
        <Button
          title="Cancel"
          onPress={() => router.back()}
          variant="text"
        />
      </Card>
    </Screen>
  );
}

const styles = StyleSheet.create({
  container: {
    padding: spacing.lg,
    justifyContent: 'center',
  },
  card: {
    alignItems: 'center',
    padding: spacing.xl,
  },
  icon: {
    fontSize: 48,
    marginBottom: spacing.md,
  },
  title: {
    textAlign: 'center',
    marginBottom: spacing.xs,
  },
  body: {
    textAlign: 'center',
    color: colors.ink,
    opacity: 0.7,
    marginBottom: spacing.xl,
  },
  button: {
    width: '100%',
    marginBottom: spacing.sm,
  },
});
