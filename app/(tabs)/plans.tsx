// PL-13 My Plans (Upcoming) / PL-14 My Plans (Drafts)
import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { useRouter } from 'expo-router';

export default function PlansScreen() {
  const router = useRouter();

  return (
    <View style={styles.container}>
      <Text style={styles.title}>PL-13 / PL-14 My Plans</Text>
      <Text style={styles.subtitle}>Upcoming Bookings & Saved Drafts</Text>
      
      <TouchableOpacity 
        style={styles.button}
        onPress={() => router.push('/booking/1')}
      >
        <Text style={styles.buttonText}>Sample Booking Form (PL-10)</Text>
      </TouchableOpacity>

      <TouchableOpacity 
        style={styles.buttonSecondary}
        onPress={() => router.push('/itinerary/1')}
      >
        <Text style={styles.buttonTextSecondary}>Sample Itinerary (RM-10)</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F6F2E9',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 24,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#18372D',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 16,
    color: '#24312D',
    marginBottom: 32,
  },
  button: {
    backgroundColor: '#18372D',
    paddingVertical: 14,
    paddingHorizontal: 24,
    borderRadius: 24,
    marginBottom: 12,
  },
  buttonText: {
    color: '#FFFFFF',
    fontWeight: 'bold',
    fontSize: 15,
  },
  buttonSecondary: {
    borderColor: '#18372D',
    borderWidth: 1,
    paddingVertical: 12,
    paddingHorizontal: 20,
    borderRadius: 24,
  },
  buttonTextSecondary: {
    color: '#18372D',
    fontWeight: '600',
    fontSize: 14,
  },
});
