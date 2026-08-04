// PL-11 Booking Confirmation

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../l10n/app_localizations.dart';
import '../../models/booking.dart';
import '../../theme/theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/async_value_view.dart';
import 'booking_providers.dart';

class ConfirmationScreen extends ConsumerWidget {
  final String bookingId;

  const ConfirmationScreen({
    super.key,
    required this.bookingId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncBooking = ref.watch(bookingDetailProvider(bookingId));

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.bookingConfirmation),
        backgroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: AsyncValueView<Booking?>(
        value: asyncBooking,
        isEmpty: (data) => data == null,
        emptyView: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.disabledText),
              const SizedBox(height: AppSpacing.md12),
              const Text(
                'Booking record not found.',
                style: AppTypography.headingMedium,
              ),
              const SizedBox(height: AppSpacing.lg16),
              AppButton(
                label: 'Return to Home',
                onPressed: () => context.go('/home'),
              ),
            ],
          ),
        ),
        data: (booking) {
          if (booking == null) return const SizedBox.shrink();

          return SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: AppSpacing.lg16),

                // Success Icon Banner
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppColors.successContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 48,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg16),

                Text(
                  'Reservation Confirmed!',
                  style: AppTypography.displayMedium.copyWith(
                    color: AppColors.forest,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs4),
                Text(
                  'Thank you for booking with PLAN E. Your reservation details are below.',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl24),

                // Booking Reference Badge Card
                AppCard(
                  backgroundColor: AppColors.forest,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BOOKING REFERENCE',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.sage,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs4),
                          Text(
                            booking.bookingRef,
                            style: AppTypography.headingLarge.copyWith(
                              color: AppColors.ivory,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md12,
                          vertical: AppSpacing.xs4,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.ivory,
                          borderRadius: AppRadii.borderPill,
                        ),
                        child: Text(
                          booking.status.toJson().toUpperCase(),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.forest,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg16),

                // Receipt Breakdown Card
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Receipt & Trip Details',
                        style: AppTypography.headingMedium.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 24, color: AppColors.borderSubtle),

                      // Contact info
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.person_outline, size: 20, color: AppColors.forest),
                          const SizedBox(width: AppSpacing.sm8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.fullName, style: AppTypography.caption.copyWith(color: AppColors.disabledText)),
                                Text(
                                  booking.contactName,
                                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  booking.contactPhone,
                                  style: AppTypography.caption,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md12),

                      // Guests
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.group_outlined, size: 20, color: AppColors.forest),
                          const SizedBox(width: AppSpacing.sm8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.adults, style: AppTypography.caption.copyWith(color: AppColors.disabledText)),
                                Text(
                                  '${booking.adults} Adult${booking.adults > 1 ? "s" : ""}${booking.children > 0 ? ", ${booking.children} Child${booking.children > 1 ? "ren" : ""}" : ""}',
                                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md12),

                      // Booking Date
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.forest),
                          const SizedBox(width: AppSpacing.sm8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.bookingRef, style: AppTypography.caption.copyWith(color: AppColors.disabledText)),
                                Text(
                                  AppFormatters.formatTripDate(booking.createdAt, pattern: 'd MMM yyyy, h:mm a'),
                                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, color: AppColors.borderSubtle),

                      // Payment summary
                      Text(
                        l10n.subtotal,
                        style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSpacing.sm8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.subtotal, style: AppTypography.bodyMedium),
                          Text(
                            AppFormatters.formatNpr(booking.subtotalPaisa),
                            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.serviceFee, style: AppTypography.caption.copyWith(color: AppColors.disabledText)),
                          Text(
                            AppFormatters.formatNpr(booking.feesPaisa),
                            style: AppTypography.caption.copyWith(color: AppColors.disabledText),
                          ),
                        ],
                      ),
                      const Divider(height: 20, color: AppColors.borderSubtle),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Paid / Payable',
                            style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            AppFormatters.formatNpr(booking.totalPaisa),
                            style: AppTypography.headingMedium.copyWith(
                              color: AppColors.forest,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl24),

                // Action Buttons
                AppButton(
                  label: 'View Trip Itinerary',
                  isFullWidth: true,
                  icon: Icons.map_outlined,
                  onPressed: () => context.go('/itinerary/${booking.id}'),
                ),
                const SizedBox(height: AppSpacing.md12),
                AppButton.secondary(
                  label: 'Back to Home',
                  isFullWidth: true,
                  icon: Icons.home_outlined,
                  onPressed: () => context.go('/home'),
                ),
                const SizedBox(height: AppSpacing.xxxl32),
              ],
            ),
          );
        },
      ),
    );
  }
}
