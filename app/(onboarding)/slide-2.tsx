// PL-03 Onboarding Step 2
import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { useRouter } from 'expo-router';

export default function OnboardingSlide2() {
  const router = useRouter();

  return (
    <View style={styles.container}>
      <Text style={styles.title}>PL-03 Onboarding Step 2</Text>
      <Text style={styles.subtitle}>Plan & Track Your Adventures</Text>
      
      <TouchableOpacity 
        style={styles.button}
        onPress={() => router.push('/(onboarding)/slide-3')}
      >
        <Text style={styles.buttonText}>Next</Text>
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
    marginBottom: 40,
  },
  button: {
    backgroundColor: '#18372D',
    paddingVertical: 14,
    paddingHorizontal: 32,
    borderRadius: 24,
  },
  buttonText: {
    color: '#FFFFFF',
    fontWeight: 'bold',
    fontSize: 16,
  },
});
