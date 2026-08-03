// PL-01 Splash
import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { useRouter } from 'expo-router';

export default function SplashScreen() {
  const router = useRouter();

  return (
    <View style={styles.container}>
      <Text style={styles.title}>PL-01 Splash</Text>
      <Text style={styles.subtitle}>PLAN E — Nepal Travel App</Text>
      
      <TouchableOpacity 
        style={styles.button}
        onPress={() => router.push('/(onboarding)/slide-1')}
      >
        <Text style={styles.buttonText}>Get Started</Text>
      </TouchableOpacity>

      <TouchableOpacity 
        style={styles.devButton}
        onPress={() => router.push('/dev/routes')}
      >
        <Text style={styles.devButtonText}>Open Route Index (/dev/routes)</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#18372D',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 24,
  },
  title: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#F6F2E9',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 18,
    color: '#E7ECE7',
    marginBottom: 40,
  },
  button: {
    backgroundColor: '#B7802B',
    paddingVertical: 14,
    paddingHorizontal: 32,
    borderRadius: 24,
    marginBottom: 16,
  },
  buttonText: {
    color: '#FFFFFF',
    fontWeight: 'bold',
    fontSize: 16,
  },
  devButton: {
    paddingVertical: 10,
    paddingHorizontal: 20,
  },
  devButtonText: {
    color: '#F6F2E9',
    fontSize: 14,
    textDecorationLine: 'underline',
  },
});
