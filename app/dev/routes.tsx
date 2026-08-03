// Dev Route Index — All 34 App Flow Screen IDs
import React from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity } from 'react-native';
import { useRouter } from 'expo-router';

const ROUTES = [
  { id: 'PL-01', name: 'Splash', path: '/' },
  { id: 'PL-02', name: 'Onboarding Slide 1', path: '/(onboarding)/slide-1' },
  { id: 'PL-03', name: 'Onboarding Slide 2', path: '/(onboarding)/slide-2' },
  { id: 'PL-04', name: 'Onboarding Slide 3', path: '/(onboarding)/slide-3' },
  { id: 'PL-05', name: 'Select Interests', path: '/(onboarding)/interests' },
  { id: 'RM-01', name: 'Sign Up', path: '/(auth)/sign-up' },
  { id: 'RM-02', name: 'Login', path: '/(auth)/login' },
  { id: 'RM-03', name: 'Forgot Password', path: '/(auth)/forgot-password' },
  { id: 'RM-04', name: 'Reset Result', path: '/(auth)/reset-result' },
  { id: 'PL-06', name: 'Home', path: '/(tabs)/home' },
  { id: 'PL-07', name: 'Explore', path: '/(tabs)/explore' },
  { id: 'PL-13/14', name: 'My Plans (Upcoming / Drafts)', path: '/(tabs)/plans' },
  { id: 'PL-15/16', name: 'My Trips (Completed / Cancelled)', path: '/(tabs)/trips' },
  { id: 'PL-17', name: 'Profile', path: '/(tabs)/profile' },
  { id: 'PL-08', name: 'Search Results', path: '/search' },
  { id: 'RM-06', name: 'Collection / See All', path: '/collection/treks' },
  { id: 'PL-09', name: 'Experience Details', path: '/experience/1' },
  { id: 'PL-10', name: 'Booking Form', path: '/booking/1' },
  { id: 'PL-11', name: 'Booking Confirmation', path: '/booking/confirmation' },
  { id: 'PL-12', name: 'Saved Experiences', path: '/saved' },
  { id: 'RM-08', name: 'Map View', path: '/map' },
  { id: 'RM-10', name: 'Itinerary', path: '/itinerary/1' },
  { id: 'RM-11', name: 'Trip Chat', path: '/chat/1' },
  { id: 'RM-12', name: 'Gear Checklist', path: '/gear/1' },
  { id: 'RM-13', name: 'Budget Tracker', path: '/budget/1' },
  { id: 'RM-14', name: 'Leave Review', path: '/review/1' },
  { id: 'RM-15', name: 'Review Submitted', path: '/review/submitted' },
  { id: 'RM-16', name: 'Edit Profile', path: '/profile/edit' },
  { id: 'RM-17', name: 'Payment Methods', path: '/profile/payment-methods' },
  { id: 'RM-18', name: 'Notifications', path: '/profile/notifications' },
  { id: 'RM-19', name: 'Language & Region', path: '/profile/language' },
  { id: 'RM-20', name: 'Help & Support', path: '/profile/help' },
  { id: 'RM-21', name: 'Settings', path: '/profile/settings' },
  { id: 'RM-27', name: 'My Reviews', path: '/profile/my-reviews' },
  { id: 'PL-18', name: 'Become a Host', path: '/host' },
  { id: 'RM-22', name: 'Host Step 1', path: '/host/step-1' },
  { id: 'PL-19', name: 'Host Step 2', path: '/host/step-2' },
  { id: 'RM-23', name: 'Host Step 3', path: '/host/step-3' },
  { id: 'RM-24', name: 'Host Step 4', path: '/host/step-4' },
  { id: 'PL-20', name: 'Host Application Submitted', path: '/host/submitted' },
];

export default function DevRoutesScreen() {
  const router = useRouter();

  return (
    <ScrollView contentContainerStyle={styles.container}>
      <Text style={styles.title}>PLAN E — Route Index</Text>
      <Text style={styles.subtitle}>All 34 App Flow Screen Routes</Text>

      {ROUTES.map((route, idx) => (
        <TouchableOpacity
          key={idx}
          style={styles.card}
          onPress={() => router.push(route.path as any)}
        >
          <View style={styles.badge}>
            <Text style={styles.badgeText}>{route.id}</Text>
          </View>
          <View style={styles.textContainer}>
            <Text style={styles.routeName}>{route.name}</Text>
            <Text style={styles.routePath}>{route.path}</Text>
          </View>
        </TouchableOpacity>
      ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    padding: 20,
    backgroundColor: '#F6F2E9',
  },
  title: {
    fontSize: 26,
    fontWeight: 'bold',
    color: '#18372D',
    marginTop: 20,
  },
  subtitle: {
    fontSize: 15,
    color: '#24312D',
    marginBottom: 20,
  },
  card: {
    backgroundColor: '#FFFFFF',
    padding: 14,
    borderRadius: 12,
    marginBottom: 10,
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#E7ECE7',
  },
  badge: {
    backgroundColor: '#18372D',
    paddingVertical: 6,
    paddingHorizontal: 10,
    borderRadius: 8,
    marginRight: 14,
  },
  badgeText: {
    color: '#F6F2E9',
    fontWeight: 'bold',
    fontSize: 12,
  },
  textContainer: {
    flex: 1,
  },
  routeName: {
    fontSize: 15,
    fontWeight: '600',
    color: '#18372D',
  },
  routePath: {
    fontSize: 12,
    color: '#B7802B',
    marginTop: 2,
  },
});
