// PL-10 Booking Form (Walled)
// TEMP: client pricing, server re-price lands in Phase 7
import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView, Modal, TouchableOpacity } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { Screen } from '@/components/Screen';
import { Button } from '@/components/Button';
import { Input } from '@/components/Input';
import { Counter } from '@/components/Counter';
import { Card } from '@/components/Card';
import { Skeleton } from '@/components/Skeleton';
import { ErrorState } from '@/components/ErrorState';
import { useExperience } from '@/hooks/useExperience';
import { formatNpr, isNepaliPhone } from '@/lib/format';
import { colors, radii, spacing, shadows } from '@/theme/tokens';
import { typography } from '@/theme/typography';
import { t } from '@/i18n';

export default function BookingFormScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { data: experience, isLoading, error, refetch } = useExperience(id || '');

  const [selectedDepartureId, setSelectedDepartureId] = useState<string | null>(null);
  const [adults, setAdults] = useState(1);
  const [children, setChildren] = useState(0);
  const [fullName, setFullName] = useState('');
  const [phone, setPhone] = useState('');
  const [phoneError, setPhoneError] = useState('');
  const [showComingSoonModal, setShowComingSoonModal] = useState(false);

  if (isLoading) {
    return (
      <Screen style={styles.loadingContainer}>
        <Skeleton width="100%" height={40} style={{ marginBottom: spacing.md }} />
        <Skeleton width="100%" height={120} style={{ marginBottom: spacing.md }} />
        <Skeleton width="100%" height={200} />
      </Screen>
    );
  }

  if (error || !experience) {
    return (
      <Screen style={styles.loadingContainer}>
        <ErrorState message="Could not load experience booking details." onRetry={refetch} />
      </Screen>
    );
  }

  const basePricePaisa = experience.price_paisa;
  const childPricePaisa = experience.child_price_paisa ?? basePricePaisa;

  // Live price breakdown calculation
  const subtotalPaisa = adults * basePricePaisa + children * childPricePaisa;
  const feesPaisa = 0; // Stage A zero fee
  const totalPaisa = subtotalPaisa + feesPaisa;

  const handleProceed = () => {
    if (!isNepaliPhone(phone)) {
      setPhoneError('Please enter a valid Nepali mobile phone number (+97798XXXXXXXX)');
      return;
    }
    setPhoneError('');
    setShowComingSoonModal(true);
  };

  return (
    <Screen scrollable style={styles.container}>
      <Text style={[typography.styles.headingLarge, styles.title]}>{t('booking.title')}</Text>
      <Text style={[typography.styles.bodyMedium, styles.subtitle]}>{experience.title}</Text>

      {/* Select Departure Date */}
      <Card style={styles.card}>
        <Text style={[typography.styles.headingMedium, styles.cardTitle]}>
          {t('booking.selectDate')}
        </Text>
        {experience.experience_departures?.length > 0 ? (
          experience.experience_departures.map((dep: any) => (
            <TouchableOpacity
              key={dep.id}
              style={[
                styles.departurePill,
                selectedDepartureId === dep.id && styles.selectedDeparture,
              ]}
              onPress={() => setSelectedDepartureId(dep.id)}
            >
              <Text style={styles.departureText}>
                📅 {dep.start_date} to {dep.end_date} ({dep.spots_left} spots left)
              </Text>
            </TouchableOpacity>
          ))
        ) : (
          <Text style={typography.styles.bodyMedium}>Daily departures available upon request.</Text>
        )}
      </Card>

      {/* Select Guests */}
      <Card style={styles.card}>
        <Text style={[typography.styles.headingMedium, styles.cardTitle]}>
          {t('booking.selectGuests')}
        </Text>
        <Counter
          label={t('booking.adults')}
          value={adults}
          min={1}
          max={experience.group_size_max}
          onChange={setAdults}
        />
        <Counter
          label={t('booking.children')}
          value={children}
          min={0}
          max={4}
          onChange={setChildren}
        />
      </Card>

      {/* Contact Details */}
      <Card style={styles.card}>
        <Text style={[typography.styles.headingMedium, styles.cardTitle]}>
          {t('booking.contactDetails')}
        </Text>
        <Input
          label={t('booking.fullName')}
          placeholder="e.g. Pasang Lhamu Sherpa"
          value={fullName}
          onChangeText={setFullName}
        />
        <Input
          label={t('booking.phone')}
          placeholder="+97798XXXXXXXX"
          value={phone}
          onChangeText={setPhone}
          keyboardType="phone-pad"
          error={phoneError}
        />
      </Card>

      {/* Live Price Breakdown */}
      <Card style={styles.card}>
        <Text style={[typography.styles.headingMedium, styles.cardTitle]}>
          {t('booking.priceBreakdown')}
        </Text>
        <View style={styles.priceRow}>
          <Text style={typography.styles.bodyMedium}>
            Adults ({adults} × {formatNpr(basePricePaisa)})
          </Text>
          <Text style={typography.styles.bodyMedium}>
            {formatNpr(adults * basePricePaisa)}
          </Text>
        </View>

        {children > 0 && (
          <View style={styles.priceRow}>
            <Text style={typography.styles.bodyMedium}>
              Children ({children} × {formatNpr(childPricePaisa)})
            </Text>
            <Text style={typography.styles.bodyMedium}>
              {formatNpr(children * childPricePaisa)}
            </Text>
          </View>
        )}

        <View style={[styles.priceRow, styles.totalRow]}>
          <Text style={typography.styles.headingMedium}>Total Amount</Text>
          <Text style={[typography.styles.headingLarge, styles.totalText]}>
            {formatNpr(totalPaisa)}
          </Text>
        </View>
      </Card>

      <Button
        title={t('booking.proceedToPayment')}
        onPress={handleProceed}
        style={styles.submitButton}
      />

      {/* Walled "Payments Coming Soon" Sheet */}
      <Modal visible={showComingSoonModal} transparent animationType="slide">
        <View style={styles.modalOverlay}>
          <View style={styles.sheetContainer}>
            <Text style={styles.sheetIcon}>💳</Text>
            <Text style={[typography.styles.headingLarge, styles.sheetTitle]}>
              {t('booking.paymentsComingSoonTitle')}
            </Text>
            <Text style={[typography.styles.bodyMedium, styles.sheetBody]}>
              {t('booking.paymentsComingSoonBody')}
            </Text>
            <Button
              title="Close & Return to App"
              onPress={() => {
                setShowComingSoonModal(false);
                router.replace('/(tabs)/plans');
              }}
              style={styles.modalButton}
            />
          </View>
        </View>
      </Modal>
    </Screen>
  );
}

const styles = StyleSheet.create({
  container: {
    padding: spacing.lg,
  },
  loadingContainer: {
    padding: spacing.lg,
  },
  title: {
    marginBottom: 2,
  },
  subtitle: {
    color: colors.ink,
    opacity: 0.7,
    marginBottom: spacing.lg,
  },
  card: {
    marginBottom: spacing.md,
  },
  cardTitle: {
    marginBottom: spacing.md,
  },
  departurePill: {
    padding: spacing.md,
    borderRadius: radii.sm,
    backgroundColor: colors.sage,
    marginBottom: spacing.xs,
    borderWidth: 1,
    borderColor: colors.sage,
  },
  selectedDeparture: {
    borderColor: colors.forest,
    backgroundColor: colors.white,
  },
  departureText: {
    fontSize: 14,
    color: colors.ink,
    fontWeight: '600',
  },
  priceRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: spacing.xs,
  },
  totalRow: {
    marginTop: spacing.md,
    paddingTop: spacing.sm,
    borderTopWidth: 1,
    borderTopColor: colors.sage,
  },
  totalText: {
    color: colors.forest,
  },
  submitButton: {
    marginVertical: spacing.lg,
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.5)',
    justifyContent: 'flex-end',
  },
  sheetContainer: {
    backgroundColor: colors.white,
    borderTopLeftRadius: radii.lg,
    borderTopRightRadius: radii.lg,
    padding: spacing.xxl,
    alignItems: 'center',
  },
  sheetIcon: {
    fontSize: 48,
    marginBottom: spacing.md,
  },
  sheetTitle: {
    textAlign: 'center',
    marginBottom: spacing.xs,
  },
  sheetBody: {
    textAlign: 'center',
    color: colors.ink,
    opacity: 0.7,
    marginBottom: spacing.xl,
  },
  modalButton: {
    width: '100%',
  },
});
