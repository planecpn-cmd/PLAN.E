// PL-17 Profile Screen
import React from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity } from 'react-native';
import { useRouter } from 'expo-router';
import { Screen } from '@/components/Screen';
import { Card } from '@/components/Card';
import { useProfile } from '@/hooks/useProfile';
import { useSaved } from '@/hooks/useSaved';
import { colors, radii, spacing, shadows } from '@/theme/tokens';
import { typography } from '@/theme/typography';

export default function ProfileScreen() {
  const router = useRouter();
  const { data: profile } = useProfile();
  const { data: savedList } = useSaved();

  return (
    <Screen scrollable style={styles.container}>
      {/* Header Profile Section */}
      <View style={styles.header}>
        <View style={styles.avatarCircle}>
          <Text style={styles.avatarText}>
            {profile?.full_name ? profile.full_name.charAt(0).toUpperCase() : '👤'}
          </Text>
        </View>
        <Text style={[typography.styles.headingLarge, styles.userName]}>
          {profile?.full_name || 'Traveler'}
        </Text>
        <Text style={[typography.styles.bodyMedium, styles.userLocation]}>
          📍 {profile?.location || 'Kathmandu, Nepal'}
        </Text>
      </View>

      {/* DB Counters Card */}
      <Card style={styles.statsCard}>
        <View style={styles.statCol}>
          <Text style={[typography.styles.headingLarge, styles.statValue]}>
            {savedList?.length || 0}
          </Text>
          <Text style={[typography.styles.caption, styles.statLabel]}>Saved</Text>
        </View>
        <View style={styles.statDivider} />
        <View style={styles.statCol}>
          <Text style={[typography.styles.headingLarge, styles.statValue]}>0</Text>
          <Text style={[typography.styles.caption, styles.statLabel]}>Trips</Text>
        </View>
        <View style={styles.statDivider} />
        <View style={styles.statCol}>
          <Text style={[typography.styles.headingLarge, styles.statValue]}>
            {profile?.points || 50}
          </Text>
          <Text style={[typography.styles.caption, styles.statLabel]}>Points</Text>
        </View>
      </Card>

      {/* Destinations List */}
      <View style={styles.menuSection}>
        <TouchableOpacity style={styles.menuItem} onPress={() => router.push('/saved')}>
          <Text style={styles.menuText}>❤️ Saved Experiences (PL-12)</Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.menuItem} onPress={() => router.push('/profile/edit')}>
          <Text style={styles.menuText}>✏️ Edit Profile (RM-16)</Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.menuItem} onPress={() => router.push('/profile/payment-methods')}>
          <Text style={styles.menuText}>💳 Payment Methods (RM-17)</Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.menuItem} onPress={() => router.push('/profile/notifications')}>
          <Text style={styles.menuText}>🔔 Notifications (RM-18)</Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.menuItem} onPress={() => router.push('/profile/language')}>
          <Text style={styles.menuText}>🌐 Language & Region (RM-19)</Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.menuItem} onPress={() => router.push('/profile/help')}>
          <Text style={styles.menuText}>💬 Help & Support (RM-20)</Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.menuItem} onPress={() => router.push('/profile/settings')}>
          <Text style={styles.menuText}>⚙️ Settings (RM-21)</Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.menuItem} onPress={() => router.push('/profile/my-reviews')}>
          <Text style={styles.menuText}>★ My Reviews (RM-27)</Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.hostButton} onPress={() => router.push('/host')}>
          <Text style={styles.hostButtonText}>🏔️ Become a Host (PL-18)</Text>
        </TouchableOpacity>
      </View>
    </Screen>
  );
}

const styles = StyleSheet.create({
  container: {
    padding: spacing.lg,
  },
  header: {
    alignItems: 'center',
    marginVertical: spacing.lg,
  },
  avatarCircle: {
    width: 72,
    height: 72,
    borderRadius: 36,
    backgroundColor: colors.forest,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: spacing.sm,
  },
  avatarText: {
    color: colors.white,
    fontSize: 28,
    fontWeight: 'bold',
  },
  userName: {
    marginBottom: 2,
  },
  userLocation: {
    color: colors.ink,
    opacity: 0.7,
  },
  statsCard: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    alignItems: 'center',
    marginBottom: spacing.xl,
    paddingVertical: spacing.md,
  },
  statCol: {
    alignItems: 'center',
    flex: 1,
  },
  statValue: {
    color: colors.forest,
  },
  statLabel: {
    color: colors.ink,
    opacity: 0.7,
    marginTop: 2,
  },
  statDivider: {
    width: 1,
    height: 28,
    backgroundColor: colors.sage,
  },
  menuSection: {
    marginBottom: spacing.xxl,
  },
  menuItem: {
    backgroundColor: colors.white,
    padding: spacing.md,
    borderRadius: radii.md,
    marginBottom: spacing.xs,
    borderWidth: 1,
    borderColor: colors.sage,
  },
  menuText: {
    fontSize: 15,
    color: colors.ink,
    fontWeight: '500',
  },
  hostButton: {
    backgroundColor: colors.forest,
    padding: spacing.md,
    borderRadius: radii.pill,
    marginTop: spacing.md,
    alignItems: 'center',
  },
  hostButtonText: {
    color: colors.white,
    fontWeight: 'bold',
    fontSize: 15,
  },
});
