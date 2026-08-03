// PL-09 Experience Details
import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';

export default function ExperienceDetailsScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();

  return (
    <View style={styles.container}>
      <ScrollView contentContainerStyle={styles.scrollContent}>
        <Text style={styles.title}>PL-09 Experience Details</Text>
        <Text style={styles.subtitle}>ID: {id || '1'} — Everest Base Camp Trek</Text>
        <Text style={styles.body}>Full overview, itinerary, what's included, reviews & organizer info.</Text>
      </ScrollView>

      <View style={styles.bottomBar}>
        <View>
          <Text style={styles.priceLabel}>From</Text>
          <Text style={styles.priceText}>Rs. 1,25,000</Text>
        </View>
        <TouchableOpacity 
          style={styles.bookButton}
          onPress={() => router.push(`/booking/${id || '1'}`)}
        >
          <Text style={styles.bookButtonText}>Join Experience</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F6F2E9',
  },
  scrollContent: {
    padding: 24,
    flexGrow: 1,
    justifyContent: 'center',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#18372D',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 18,
    color: '#B7802B',
    marginBottom: 16,
    fontWeight: '600',
  },
  body: {
    fontSize: 15,
    color: '#24312D',
    lineHeight: 22,
  },
  bottomBar: {
    backgroundColor: '#FFFFFF',
    padding: 16,
    borderTopWidth: 1,
    borderTopColor: '#E7ECE7',
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  priceLabel: {
    fontSize: 12,
    color: '#24312D',
  },
  priceText: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#18372D',
  },
  bookButton: {
    backgroundColor: '#18372D',
    paddingVertical: 12,
    paddingHorizontal: 24,
    borderRadius: 24,
  },
  bookButtonText: {
    color: '#FFFFFF',
    fontWeight: 'bold',
    fontSize: 15,
  },
});
