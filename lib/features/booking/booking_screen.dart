// PL-10 Booking Form
// TEMP: client pricing, server re-price lands in Phase 7

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../models/experience.dart';
import '../../models/experience_departure.dart';
import '../../theme/theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/counter_field.dart';
import '../../widgets/price_bottom_bar.dart';
import '../../widgets/progress_steps.dart';
import 'booking_providers.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final String experienceId;

  const BookingScreen({
    super.key,
    required this.experienceId,
  });

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  ExperienceDeparture? _selectedDeparture;
  int _adults = 1;
  int _children = 0;
  bool _isCreatingBooking = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onDepartureSelected(ExperienceDeparture departure) {
    setState(() {
      _selectedDeparture = departure;
      // Ensure guest counts stay within available spots
      if (_adults + _children > departure.spotsLeft) {
        _adults = 1;
        _children = 0;
      }
    });
  }

  // TEMP: client pricing, server re-price lands in Phase 7
  int _calculateSubtotalPaisa(Experience experience) {
    if (_selectedDeparture == null) return 0;
    final int adultRatePaisa = _selectedDeparture!.priceOverridePaisa ?? experience.pricePaisa;
    final int childRatePaisa = experience.childPricePaisa ?? (adultRatePaisa * 0.75).toInt();
    return (_adults * adultRatePaisa) + (_children * childRatePaisa);
  }

  // TEMP: client pricing, server re-price lands in Phase 7
  int _calculateFeesPaisa(int subtotalPaisa) {
    return (subtotalPaisa * 0.05).round(); // 5% platform service fee
  }

  void _handleProceedToPayment(Experience experience) {
    if (_selectedDeparture == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a departure date.')),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      _showPaymentModalSheet(experience);
    }
  }

  void _showPaymentModalSheet(Experience experience) {
    final subtotalPaisa = _calculateSubtotalPaisa(experience);
    final feesPaisa = _calculateFeesPaisa(subtotalPaisa);
    final totalPaisa = subtotalPaisa + feesPaisa;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg24)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.lg16,
                right: AppSpacing.lg16,
                top: AppSpacing.xxl24,
                bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom + AppSpacing.xxl24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.border,
                        borderRadius: AppRadii.borderPill,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg16),

                  Row(
                    children: [
                      const Icon(
                        Icons.payments_outlined,
                        color: AppColors.forest,
                        size: 28,
                      ),
                      const SizedBox(width: AppSpacing.sm8),
                      Text(
                        'Payments Coming Soon',
                        style: AppTypography.headingMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.forest,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm8),
                  Text(
                    'Online payment gateway integration (Khalti & eSewa) lands in Phase 7. You can place a draft reservation now.',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
                  ),
                  const SizedBox(height: AppSpacing.lg16),

                  AppCard(
                    backgroundColor: AppColors.cardBackgroundAlt,
                    padding: AppSpacing.paddingLg16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          experience.title,
                          style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppSpacing.xs4),
                        if (_selectedDeparture != null)
                          Text(
                            'Departure: ${AppFormatters.formatTripDate(_selectedDeparture!.startDate, pattern: 'd MMM yyyy')}',
                            style: AppTypography.caption.copyWith(color: AppColors.forest, fontWeight: FontWeight.w600),
                          ),
                        const SizedBox(height: AppSpacing.xs4),
                        Text(
                          'Guests: $_adults Adult${_adults > 1 ? "s" : ""}${_children > 0 ? ", $_children Child${_children > 1 ? "ren" : ""}" : ""}',
                          style: AppTypography.bodyMedium,
                        ),
                        const Divider(height: 24, color: AppColors.borderSubtle),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Amount:',
                              style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              AppFormatters.formatNpr(totalPaisa),
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

                  AppButton(
                    label: 'Confirm Draft Reservation',
                    isFullWidth: true,
                    isLoading: _isCreatingBooking,
                    onPressed: () async {
                      setModalState(() => _isCreatingBooking = true);
                      setState(() => _isCreatingBooking = true);

                      final navigator = Navigator.of(bottomSheetContext);
                      final router = GoRouter.of(context);

                      final repo = ref.read(bookingFeatureRepositoryProvider);
                      final booking = await repo.createBooking(
                        experienceId: experience.id,
                        departureId: _selectedDeparture!.id,
                        adults: _adults,
                        children: _children,
                        contactName: _nameController.text.trim(),
                        contactPhone: _phoneController.text.trim(),
                        subtotalPaisa: subtotalPaisa,
                        addonsPaisa: 0,
                        feesPaisa: feesPaisa,
                        totalPaisa: totalPaisa,
                      );

                      navigator.pop();
                      router.go('/booking/confirmation/${booking.id}');
                    },
                  ),
                  const SizedBox(height: AppSpacing.md12),
                  AppButton.secondary(
                    label: 'Cancel',
                    isFullWidth: true,
                    onPressed: () => Navigator.of(bottomSheetContext).pop(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(bookingFormDataProvider(widget.experienceId));

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: const Text('Book Experience'),
        backgroundColor: AppColors.white,
        elevation: 0,
      ),
      body: AsyncValueView<BookingFormData>(
        value: asyncData,
        data: (formData) {
          final experience = formData.experience;
          final departures = formData.departures;

          // Default selected departure if null
          if (_selectedDeparture == null && departures.isNotEmpty) {
            _selectedDeparture = departures.first;
          }

          final int subtotalPaisa = _calculateSubtotalPaisa(experience);
          final int feesPaisa = _calculateFeesPaisa(subtotalPaisa);
          final int totalPaisa = subtotalPaisa + feesPaisa;

          final int maxSpots = _selectedDeparture?.spotsLeft ?? experience.groupSizeMax;

          return Column(
            children: [
              const ProgressSteps(
                currentStep: 0,
                steps: ['Booking Details', 'Confirmation'],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: AppSpacing.screenPadding,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Experience Header Card
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                experience.title,
                                style: AppTypography.headingMedium.copyWith(fontWeight: FontWeight.bold),
                              ),
                              if (experience.locationName != null) ...[
                                const SizedBox(height: AppSpacing.xs4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.forest),
                                    const SizedBox(width: AppSpacing.xs4),
                                    Text(
                                      experience.locationName!,
                                      style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: AppSpacing.md12),
                              Text(
                                'Price per adult: ${AppFormatters.formatNpr(experience.pricePaisa)}',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.forest,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl20),

                        // Departure Date Selection
                        Text(
                          'Select Departure Date',
                          style: AppTypography.headingMedium.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm8),
                        Column(
                          children: departures.map((dep) {
                            final bool isSelected = _selectedDeparture?.id == dep.id;
                            final int adultPricePaisa = dep.priceOverridePaisa ?? experience.pricePaisa;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.sm8),
                              child: AppCard(
                                onTap: () => _onDepartureSelected(dep),
                                borderColor: isSelected ? AppColors.forest : AppColors.borderSubtle,
                                backgroundColor: isSelected ? AppColors.sage : AppColors.white,
                                child: Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(right: AppSpacing.sm8),
                                      child: Icon(
                                        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                        color: isSelected ? AppColors.forest : AppColors.disabledText,
                                        size: 24,
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${AppFormatters.formatTripDate(dep.startDate, pattern: 'd MMM yyyy')} - ${AppFormatters.formatTripDate(dep.endDate, pattern: 'd MMM yyyy')}',
                                            style: AppTypography.bodyLarge.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.ink,
                                            ),
                                          ),
                                          const SizedBox(height: AppSpacing.xs4),
                                          Text(
                                            '${dep.spotsLeft} spots available',
                                            style: AppTypography.caption.copyWith(
                                              color: dep.spotsLeft < 5 ? AppColors.error : AppColors.forest,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      AppFormatters.formatNpr(adultPricePaisa),
                                      style: AppTypography.bodyLarge.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.forest,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.xl20),

                        // Guest Selection Section
                        Text(
                          'Number of Guests',
                          style: AppTypography.headingMedium.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm8),
                        AppCard(
                          child: Column(
                            children: [
                              CounterField(
                                label: 'Adults (18+ yrs)',
                                value: _adults,
                                min: 1,
                                max: maxSpots,
                                onChanged: (val) {
                                  setState(() {
                                    _adults = val;
                                    if (_adults + _children > maxSpots) {
                                      _children = maxSpots - _adults;
                                    }
                                  });
                                },
                              ),
                              const Divider(height: 24, color: AppColors.borderSubtle),
                              CounterField(
                                label: 'Children (0-17 yrs)',
                                value: _children,
                                min: 0,
                                max: maxSpots - _adults,
                                onChanged: (val) {
                                  setState(() {
                                    _children = val;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl20),

                        // Contact Information Form
                        Text(
                          'Primary Contact Info',
                          style: AppTypography.headingMedium.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm8),
                        AppCard(
                          child: Column(
                            children: [
                              AppTextField(
                                label: 'Full Name',
                                hint: 'e.g. Ram Bahadur Shrestha',
                                controller: _nameController,
                                prefixIcon: const Icon(Icons.person_outline, size: 20),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your full name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSpacing.md12),
                              AppTextField(
                                label: 'Nepali Phone Number',
                                hint: '98XXXXXXXX or +97798XXXXXXXX',
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                prefixIcon: const Icon(Icons.phone_android_outlined, size: 20),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter mobile number';
                                  }
                                  if (!AppFormatters.isNepaliPhone(value)) {
                                    return 'Must be valid 10-digit Nepali mobile number (98XXXXXXXX)';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSpacing.md12),
                              AppTextField(
                                label: 'Special Requirements / Notes (Optional)',
                                hint: 'Dietary preferences, pickup requests...',
                                controller: _notesController,
                                maxLines: 2,
                                prefixIcon: const Icon(Icons.note_alt_outlined, size: 20),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl20),

                        // Live Price Breakdown Section
                        // TEMP: client pricing, server re-price lands in Phase 7
                        Text(
                          'Price Breakdown',
                          style: AppTypography.headingMedium.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm8),
                        AppCard(
                          backgroundColor: AppColors.cardBackgroundAlt,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Adults ($_adults × ${AppFormatters.formatNpr(_selectedDeparture?.priceOverridePaisa ?? experience.pricePaisa)})',
                                    style: AppTypography.bodyMedium,
                                  ),
                                  Text(
                                    AppFormatters.formatNpr(_adults * (_selectedDeparture?.priceOverridePaisa ?? experience.pricePaisa)),
                                    style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              if (_children > 0) ...[
                                const SizedBox(height: AppSpacing.xs4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Children ($_children × ${AppFormatters.formatNpr(experience.childPricePaisa ?? ((_selectedDeparture?.priceOverridePaisa ?? experience.pricePaisa) * 0.75).toInt())})',
                                      style: AppTypography.bodyMedium,
                                    ),
                                    Text(
                                      AppFormatters.formatNpr(_children * (experience.childPricePaisa ?? ((_selectedDeparture?.priceOverridePaisa ?? experience.pricePaisa) * 0.75).toInt())),
                                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ],
                              const Divider(height: 20, color: AppColors.borderSubtle),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Subtotal', style: AppTypography.bodyMedium),
                                  Text(
                                    AppFormatters.formatNpr(subtotalPaisa),
                                    style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Service & Tech Fee (5%)', style: AppTypography.caption.copyWith(color: AppColors.disabledText)),
                                  Text(
                                    AppFormatters.formatNpr(feesPaisa),
                                    style: AppTypography.caption.copyWith(color: AppColors.disabledText),
                                  ),
                                ],
                              ),
                              const Divider(height: 20, color: AppColors.borderSubtle),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Payable',
                                    style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    AppFormatters.formatNpr(totalPaisa),
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
                        const SizedBox(height: AppSpacing.xxxl32),
                      ],
                    ),
                  ),
                ),
              ),
              PriceBottomBar(
                priceText: AppFormatters.formatNpr(totalPaisa),
                unitText: 'total',
                buttonLabel: 'Proceed to Pay',
                onPressed: () => _handleProceedToPayment(experience),
              ),
            ],
          );
        },
      ),
    );
  }
}
