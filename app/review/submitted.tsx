// RM-15 Review Submitted
import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { useRouter } from 'expo-router';

export default function ReviewSubmittedScreen() {
  const router = useRouter();

  return (
    <View style={styles.container}>
      <Text style={styles.title}>RM-15 Review Submitted</Text>
      <Text style={styles.subtitle}>Thank you for sharing your experience!</Text>
      
      <TouchableOpacity 
        style={styles.button}
        onPress={() => router.replace('/(tabs)/trips')}
      >
        <Text style={styles.buttonText}>Back to My Trips</Text>
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
  },
  buttonText: {
    color: '#FFFFFF',
    fontWeight: 'bold',
    fontSize: 15,
  },
});
