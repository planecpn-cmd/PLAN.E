// RM-24 Host Application Step 4
import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { useRouter } from 'expo-router';

export default function HostStep4Screen() {
  const router = useRouter();

  return (
    <View style={styles.container}>
      <Text style={styles.title}>RM-24 Host Application Step 4</Text>
      <Text style={styles.subtitle}>Review & Submit Application</Text>
      
      <TouchableOpacity 
        style={styles.button}
        onPress={() => router.push('/host/submitted')}
      >
        <Text style={styles.buttonText}>Submit Application</Text>
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
