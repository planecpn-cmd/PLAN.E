// PL-18 Become a Host
import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView } from 'react-native';
import { useRouter } from 'expo-router';

export default function BecomeHostScreen() {
  const router = useRouter();

  return (
    <ScrollView contentContainerStyle={styles.container}>
      <Text style={styles.title}>PL-18 Become a Host</Text>
      <Text style={styles.subtitle}>Share your local experiences on PLAN E</Text>
      
      <TouchableOpacity 
        style={styles.button}
        onPress={() => router.push('/host/step-1')}
      >
        <Text style={styles.buttonText}>Start Host Application</Text>
      </TouchableOpacity>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flexGrow: 1,
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
    textAlign: 'center',
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
