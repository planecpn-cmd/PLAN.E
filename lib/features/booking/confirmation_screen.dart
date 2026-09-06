// PL-11 Booking Confirmation

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../l10n/app_localizations.dart';
import '../../models/booking.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'booking_providers.dart';

class ConfirmationScreen extends ConsumerWidget {
  final String bookingId;

  const ConfirmationScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncBooking = ref.watch(bookingDetailProvider(bookingId));

    return Scaffold(
      body: PlanEBackground(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
        child: AsyncValueView<Booking?>(
          value: asyncBooking,
          isEmpty: (data) => data == null,
          emptyView: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: AppColors.disabledText,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Booking record not found.',
                  style: AppTypography.headingMedium,
                ),
                const SizedBox(height: 16),
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
              child: Column(
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      color: AppColors.forest,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.sage, width: 7),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.forest.withValues(alpha: .2),
                          blurRadius: 24,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 45,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Booking Confirmed!',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.forest,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your adventure is officially reserved.',
                    style: TextStyle(
                      color: AppColors.disabledText,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Booking Receipt Card
                  PlanECard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.bookingRef,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.disabledText,
                                letterSpacing: 1,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.sage,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                booking.status.toJson().toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.forest,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '#${booking.bookingRef}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.forest,
                          ),
                        ),
                        const Divider(height: 20),

                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline,
                              size: 18,
                              color: AppColors.forest,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              booking.contactName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.groups_outlined,
                              size: 18,
                              color: AppColors.forest,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${booking.adults} Adult${booking.adults > 1 ? "s" : ""}${booking.children > 0 ? ", ${booking.children} Children" : ""}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                              color: AppColors.forest,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppFormatters.formatTripDate(
                                booking.createdAt,
                                pattern: 'd MMM yyyy',
                              ),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const Divider(height: 20),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.sage.withValues(alpha: .5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Text(
                                'Total paid',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppColors.ink,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                AppFormatters.formatNpr(booking.totalPaisa),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.forest,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Next Steps
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Next steps',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.forest,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  PlanECard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _NextStepTile(
                          icon: Icons.assignment_outlined,
                          text: '1. View experience schedule',
                          onTap: () => context.go('/itinerary/${booking.id}'),
                        ),
                        const Divider(height: 1),
                        _NextStepTile(
                          icon: Icons.chat_bubble_outline,
                          text: '2. Message your host',
                          onTap: () => context.go('/chat/${booking.id}'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  AppButton(
                    label: 'VIEW MY PLANS',
                    isFullWidth: true,
                    onPressed: () => context.go('/plans'),
                  ),
                  const SizedBox(height: 10),
                  AppButton(
                    label: 'BACK TO HOME',
                    variant: AppButtonVariant.secondary,
                    isFullWidth: true,
                    onPressed: () => context.go('/home'),
                  ),
                  const SizedBox(height: 14),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.mail_outline,
                        color: AppColors.forest,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Confirmation details saved to your account.',
                        style: TextStyle(
                          color: AppColors.disabledText,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    children: [
                      _PolicyLink(
                        label: 'Cancellation Policy',
                        slug: 'cancellation-policy',
                      ),
                      _PolicyLink(
                        label: 'Refund Policy',
                        slug: 'refund-policy',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PolicyLink extends StatelessWidget {
  final String label;
  final String slug;

  const _PolicyLink({required this.label, required this.slug});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/legal/$slug'),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.gold,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

class _NextStepTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _NextStepTile({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.sage,
              child: Icon(icon, color: AppColors.forest, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.disabledText,
            ),
          ],
        ),
      ),
    );
  }
}
