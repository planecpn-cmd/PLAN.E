import React from 'react';
import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';

export default function RootLayout() {
  return (
    <>
      <StatusBar style="auto" />
      <Stack screenOptions={{ headerShown: false }}>
        <Stack.Screen name="index" />
        <Stack.Screen name="(onboarding)" />
        <Stack.Screen name="(auth)" />
        <Stack.Screen name="(auth)/auth-required-modal" options={{ presentation: 'modal' }} />
        <Stack.Screen name="(tabs)" />
        <Stack.Screen name="search" />
        <Stack.Screen name="collection/[slug]" />
        <Stack.Screen name="experience/[id]" />
        <Stack.Screen name="booking/[id]" />
        <Stack.Screen name="booking/confirmation" />
        <Stack.Screen name="saved" />
        <Stack.Screen name="map" />
        <Stack.Screen name="itinerary/[bookingId]" />
        <Stack.Screen name="chat/[bookingId]" />
        <Stack.Screen name="gear/[bookingId]" />
        <Stack.Screen name="budget/[bookingId]" />
        <Stack.Screen name="review/[bookingId]" />
        <Stack.Screen name="review/submitted" />
        <Stack.Screen name="profile/edit" />
        <Stack.Screen name="profile/payment-methods" />
        <Stack.Screen name="profile/notifications" />
        <Stack.Screen name="profile/language" />
        <Stack.Screen name="profile/help" />
        <Stack.Screen name="profile/settings" />
        <Stack.Screen name="profile/my-reviews" />
        <Stack.Screen name="host/index" />
        <Stack.Screen name="host/step-1" />
        <Stack.Screen name="host/step-2" />
        <Stack.Screen name="host/step-3" />
        <Stack.Screen name="host/step-4" />
        <Stack.Screen name="host/submitted" />
        <Stack.Screen name="dev/routes" />
        <Stack.Screen name="dev/components" />
      </Stack>
    </>
  );
}
