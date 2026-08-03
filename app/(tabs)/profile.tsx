// PL-17 Profile Screen
import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView } from 'react-native';
import { useRouter } from 'expo-router';

export default function ProfileScreen() {
  const router = useRouter();

  return (
    <ScrollView contentContainerStyle={styles.container}>
      <Text style={styles.title}>PL-17 Profile Screen</Text>
      <Text style={styles.subtitle}>User Account & Preferences</Text>
      
      <TouchableOpacity style={styles.menuItem} onPress={() => router.push('/saved')}>
        <Text style={styles.menuText}>Saved Experiences (PL-12)</Text>
      </TouchableOpacity>

      <TouchableOpacity style={styles.menuItem} onPress={() => router.push('/profile/edit')}>
        <Text style={styles.menuText}>Edit Profile (RM-16)</Text>
      </TouchableOpacity>

      <TouchableOpacity style={styles.menuItem} onPress={() => router.push('/profile/payment-methods')}>
        <Text style={styles.menuText}>Payment Methods (RM-17)</Text>
      </TouchableOpacity>

      <TouchableOpacity style={styles.menuItem} onPress={() => router.push('/profile/notifications')}>
        <Text style={styles.menuText}>Notifications (RM-18)</Text>
      </TouchableOpacity>

      <TouchableOpacity style={styles.menuItem} onPress={() => router.push('/profile/language')}>
        <Text style={styles.menuText}>Language & Region (RM-19)</Text>
      </TouchableOpacity>

      <TouchableOpacity style={styles.menuItem} onPress={() => router.push('/profile/help')}>
        <Text style={styles.menuText}>Help & Support (RM-20)</Text>
      </TouchableOpacity>

      <TouchableOpacity style={styles.menuItem} onPress={() => router.push('/profile/settings')}>
        <Text style={styles.menuText}>Settings (RM-21)</Text>
      </TouchableOpacity>

      <TouchableOpacity style={styles.menuItem} onPress={() => router.push('/profile/my-reviews')}>
        <Text style={styles.menuText}>My Reviews (RM-27)</Text>
      </TouchableOpacity>

      <TouchableOpacity style={[styles.menuItem, styles.hostItem]} onPress={() => router.push('/host')}>
        <Text style={styles.hostText}>Become a Host (PL-18)</Text>
      </TouchableOpacity>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    padding: 24,
    backgroundColor: '#F6F2E9',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#18372D',
    marginBottom: 4,
    marginTop: 24,
  },
  subtitle: {
    fontSize: 16,
    color: '#24312D',
    marginBottom: 24,
  },
  menuItem: {
    backgroundColor: '#FFFFFF',
    padding: 16,
    borderRadius: 12,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: '#E7ECE7',
  },
  menuText: {
    fontSize: 15,
    color: '#24312D',
    fontWeight: '500',
  },
  hostItem: {
    backgroundColor: '#18372D',
    marginTop: 12,
  },
  hostText: {
    color: '#FFFFFF',
    fontWeight: 'bold',
    fontSize: 15,
    textAlign: 'center',
  },
});
