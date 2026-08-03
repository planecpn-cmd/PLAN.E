// PL-07 Explore Screen
import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { useRouter } from 'expo-router';

export default function ExploreScreen() {
  const router = useRouter();

  return (
    <View style={styles.container}>
      <Text style={styles.title}>PL-07 Explore Screen</Text>
      <Text style={styles.subtitle}>Explore Regions & Categories</Text>
      
      <TouchableOpacity 
        style={styles.button}
        onPress={() => router.push('/map')}
      >
        <Text style={styles.buttonText}>Open Map View (RM-08)</Text>
      </TouchableOpacity>

      <TouchableOpacity 
        style={styles.buttonSecondary}
        onPress={() => router.push('/collection/treks')}
      >
        <Text style={styles.buttonTextSecondary}>View Treks Collection (RM-06)</Text>
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
