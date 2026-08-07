// PL-10 Booking Form

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/supabase_client.dart';
import '../../l10n/app_localizations.dart';
import '../../models/booking_intent.dart';
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
import '../../widgets/offline_banner.dart';
import 'booking_providers.dart';
import 'payment_webview_screen.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final String experienceId;

  const BookingScreen({super.key, required this.experienceId});

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
  bool _isCreatingIntent = false;
  final String _selectedGateway = 'khalti';

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
      if (_adults + _children > departure.spotsLeft) {
        _adults = 1;
        _children = 0;
      }
    });
  }

  int _calculateSubtotalPaisa(Experience experience) {
    if (_selectedDeparture == null) return 0;
    final int adultRatePaisa =
        _selectedDeparture!.priceOverridePaisa ?? experience.pricePaisa;
    final int childRatePaisa =
        experience.childPricePaisa ?? (adultRatePaisa * 0.75).toInt();
    return (_adults * adultRatePaisa) + (_children * childRatePaisa);
  }

  int _calculateFeesPaisa(int subtotalPaisa) {
    return (subtotalPaisa * 0.05).round(); // 5% platform service fee
  }

  Future<void> _handleProceedToPayment(Experience experience) async {
    if (_selectedDeparture == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.selectDepartureDate),
        ),
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isCreatingIntent = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final repo = ref.read(bookingFeatureRepositoryProvider);
      final intent = await repo.createBookingIntent(
        experienceId: experience.id,
        departureId: _selectedDeparture!.id,
        adults: _adults,
        children: _children,
        contactName: _nameController.text.trim(),
        contactPhone: _phoneController.text.trim(),
        paymentProvider: _selectedGateway,
      );

      if (mounted) {
        setState(() => _isCreatingIntent = false);
        _showPaymentIntentModalSheet(experience, intent);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreatingIntent = false);
        messenger.showSnackBar(
          SnackBar(content: Text('Booking intent failed: $e')),
        );
      }
    }
  }

  void _showPaymentIntentModalSheet(
    Experience experience,
    BookingIntentResult intent,
  ) {
    String currentGateway = _selectedGateway;
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.lg24),
        ),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.lg16,
                right: AppSpacing.lg16,
                top: AppSpacing.xxl24,
                bottom:
                    MediaQuery.of(bottomSheetContext).viewInsets.bottom +
                    AppSpacing.xxl24,
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
                        Icons.verified_user_outlined,
                        color: AppColors.forest,
                        size: 28,
                      ),
                      const SizedBox(width: AppSpacing.sm8),
                      Text(
                        'Payment Intent Checkout',
                        style: AppTypography.headingMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.forest,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs4),
                  Text(
                    'Server re-priced quote created. Complete payment to lock your spot.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg16),

                  // Order Summary Card
                  AppCard(
                    backgroundColor: AppColors.cardBackgroundAlt,
                    padding: AppSpacing.paddingLg16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          experience.title,
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs4),
                        if (_selectedDeparture != null)
                          Text(
                            'Departure: ${AppFormatters.formatTripDate(_selectedDeparture!.startDate, pattern: 'd MMM yyyy')}',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.forest,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        const SizedBox(height: AppSpacing.xs4),
                        Text(
                          'Guests: $_adults Adult${_adults > 1 ? "s" : ""}${_children > 0 ? ", $_children Child${_children > 1 ? "ren" : ""}" : ""}',
                          style: AppTypography.bodyMedium,
                        ),
                        const Divider(
                          height: 20,
                          color: AppColors.borderSubtle,
                        ),

                        // Only customer-relevant quote metadata belongs here.
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm8),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(AppRadii.sm8),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                size: 14,
                                color: AppColors.forest,
                              ),
                              const SizedBox(width: AppSpacing.xs4),
                              Expanded(
                                child: Text(
                                  'Quote valid for 15 mins (expires ${AppFormatters.formatTripDate(intent.quoteExpiresAt, pattern: 'HH:mm')})',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.forest,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md12),

                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Total Amount (Server Quote):',
                                style: AppTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm8),
                            Text(
                              AppFormatters.formatNpr(intent.totalPaisa),
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
                  const SizedBox(height: AppSpacing.lg16),

                  // Gateway Selection
                  Text(
                    'Select Payment Gateway',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm8),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setModalState(() => currentGateway = 'khalti'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md12,
                              horizontal: AppSpacing.sm8,
                            ),
                            decoration: BoxDecoration(
                              color: currentGateway == 'khalti'
                                  ? AppColors.sage
                                  : AppColors.white,
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(
                                color: currentGateway == 'khalti'
                                    ? AppColors.forest
                                    : AppColors.borderSubtle,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  currentGateway == 'khalti'
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: currentGateway == 'khalti'
                                      ? AppColors.forest
                                      : AppColors.disabledText,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSpacing.xs4),
                                Text(
                                  'Khalti Pay',
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: currentGateway == 'khalti'
                                        ? AppColors.forest
                                        : AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setModalState(() => currentGateway = 'esewa'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md12,
                              horizontal: AppSpacing.sm8,
                            ),
                            decoration: BoxDecoration(
                              color: currentGateway == 'esewa'
                                  ? AppColors.sage
                                  : AppColors.white,
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(
                                color: currentGateway == 'esewa'
                                    ? AppColors.forest
                                    : AppColors.borderSubtle,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  currentGateway == 'esewa'
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: currentGateway == 'esewa'
                                      ? AppColors.forest
                                      : AppColors.disabledText,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSpacing.xs4),
                                Text(
                                  'eSewa Pay',
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: currentGateway == 'esewa'
                                        ? AppColors.forest
                                        : AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl24),

                  AppButton(
                    label:
                        'Pay ${AppFormatters.formatNpr(intent.totalPaisa)} via ${currentGateway.toUpperCase()}',
                    isFullWidth: true,
                    isLoading: isProcessing,
                    onPressed: () async {
                      setModalState(() => isProcessing = true);

                      final navigator = Navigator.of(bottomSheetContext);
                      final messenger = ScaffoldMessenger.of(context);
                      final router = GoRouter.of(context);
                      final pageNavigator = Navigator.of(context);
                      final repo = ref.read(bookingFeatureRepositoryProvider);

                      try {
                        final paymentUrl = await repo.initiatePayment(
                          bookingId: intent.bookingId,
                          provider: currentGateway,
                        );

                        if (modalCtx.mounted) navigator.pop();

                        final returnUri = await pageNavigator.push<Uri>(
                          MaterialPageRoute(
                            builder: (_) => PaymentWebviewScreen(
                              paymentUrl: paymentUrl,
                              returnUrlPrefix:
                                  '${AppSupabaseClient.baseUrl}/functions/v1/payment-return',
                            ),
                          ),
                        );

                        if (returnUri == null) {
                          // User closed the checkout without completing payment.
                          return;
                        }

                        final bool confirmed = await repo.verifyPayment(
                          bookingId: intent.bookingId,
                          idempotencyKey: intent.idempotencyKey,
                          provider: currentGateway,
                          pidx: returnUri.queryParameters['pidx'],
                          transactionUuid:
                              returnUri.queryParameters['transaction_uuid'],
                        );

                        if (confirmed) {
                          router.go(
                            '/booking/confirmation/${intent.bookingId}',
                          );
                        } else {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Payment verification failed. Please try again.',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (modalCtx.mounted) {
                          setModalState(() => isProcessing = false);
                        }
                        messenger.showSnackBar(
                          SnackBar(content: Text('Payment failed: $e')),
                        );
                      }
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
        title: Text(AppLocalizations.of(context)!.bookingForm),
        backgroundColor: AppColors.white,
        elevation: 0,
      ),
      body: AsyncValueView<BookingFormData>(
        value: asyncData,
        data: (formData) {
          final experience = formData.experience;
          final departures = formData.departures;

          if (_selectedDeparture == null && departures.isNotEmpty) {
            _selectedDeparture = departures.first;
          }

          final int subtotalPaisa = _calculateSubtotalPaisa(experience);
          final int feesPaisa = _calculateFeesPaisa(subtotalPaisa);
          final int totalPaisa = subtotalPaisa + feesPaisa;

          final int maxSpots =
              _selectedDeparture?.spotsLeft ?? experience.groupSizeMax;

          return Column(
            children: [
              const OfflineBanner(),
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
                                style: AppTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (experience.locationName != null) ...[
                                const SizedBox(height: AppSpacing.xs4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 16,
                                      color: AppColors.forest,
                                    ),
                                    const SizedBox(width: AppSpacing.xs4),
                                    Text(
                                      experience.locationName!,
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: AppColors.ink,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: AppSpacing.md12),
                              Text(
                                'Price per adult: ${AppFormatters.formatNpr(experience.pricePaisa)}',
                                style: AppTypography.caption.copyWith(
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
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm8),
                        Column(
                          children: departures.map((dep) {
                            final bool isSelected =
                                _selectedDeparture?.id == dep.id;
                            final int adultPricePaisa =
                                dep.priceOverridePaisa ?? experience.pricePaisa;

                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm8,
                              ),
                              child: AppCard(
                                onTap: () => _onDepartureSelected(dep),
                                borderColor: isSelected
                                    ? AppColors.forest
                                    : AppColors.borderSubtle,
                                backgroundColor: isSelected
                                    ? AppColors.sage
                                    : AppColors.white,
                                child: Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        right: AppSpacing.sm8,
                                      ),
                                      child: Icon(
                                        isSelected
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_unchecked,
                                        color: isSelected
                                            ? AppColors.forest
                                            : AppColors.disabledText,
                                        size: 24,
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${AppFormatters.formatTripDate(dep.startDate, pattern: 'd MMM yyyy')} - ${AppFormatters.formatTripDate(dep.endDate, pattern: 'd MMM yyyy')}',
                                            style: AppTypography.bodyMedium
                                                .copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.ink,
                                                ),
                                          ),
                                          const SizedBox(
                                            height: AppSpacing.xs4,
                                          ),
                                          Text(
                                            '${dep.spotsLeft} spots available',
                                            style: AppTypography.caption
                                                .copyWith(
                                                  color: dep.spotsLeft < 5
                                                      ? AppColors.error
                                                      : AppColors.forest,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      AppFormatters.formatNpr(adultPricePaisa),
                                      style: AppTypography.bodyMedium.copyWith(
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
                          style: AppTypography.bodyMedium.copyWith(
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
                              const Divider(
                                height: 24,
                                color: AppColors.borderSubtle,
                              ),
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
                          style: AppTypography.bodyMedium.copyWith(
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
                                prefixIcon: const Icon(
                                  Icons.person_outline,
                                  size: 20,
                                ),
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
                                prefixIcon: const Icon(
                                  Icons.phone_android_outlined,
                                  size: 20,
                                ),
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
                                label:
                                    'Special Requirements / Notes (Optional)',
                                hint: 'Dietary preferences, pickup requests...',
                                controller: _notesController,
                                maxLines: 2,
                                prefixIcon: const Icon(
                                  Icons.note_alt_outlined,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl20),

                        // Estimated Price Breakdown Section
                        Text(
                          'Price Breakdown',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm8),
                        AppCard(
                          backgroundColor: AppColors.cardBackgroundAlt,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Adults ($_adults × ${AppFormatters.formatNpr(_selectedDeparture?.priceOverridePaisa ?? experience.pricePaisa)})',
                                    style: AppTypography.bodyMedium,
                                  ),
                                  Text(
                                    AppFormatters.formatNpr(
                                      _adults *
                                          (_selectedDeparture
                                                  ?.priceOverridePaisa ??
                                              experience.pricePaisa),
                                    ),
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              if (_children > 0) ...[
                                const SizedBox(height: AppSpacing.xs4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Children ($_children × ${AppFormatters.formatNpr(experience.childPricePaisa ?? ((_selectedDeparture?.priceOverridePaisa ?? experience.pricePaisa) * 0.75).toInt())})',
                                      style: AppTypography.bodyMedium,
                                    ),
                                    Text(
                                      AppFormatters.formatNpr(
                                        _children *
                                            (experience.childPricePaisa ??
                                                ((_selectedDeparture
                                                                ?.priceOverridePaisa ??
                                                            experience
                                                                .pricePaisa) *
                                                        0.75)
                                                    .toInt()),
                                      ),
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const Divider(
                                height: 20,
                                color: AppColors.borderSubtle,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.subtotal,
                                    style: AppTypography.bodyMedium,
                                  ),
                                  Text(
                                    AppFormatters.formatNpr(subtotalPaisa),
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.serviceFee,
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.disabledText,
                                    ),
                                  ),
                                  Text(
                                    AppFormatters.formatNpr(feesPaisa),
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.disabledText,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(
                                height: 20,
                                color: AppColors.borderSubtle,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Estimated Total',
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    AppFormatters.formatNpr(totalPaisa),
                                    style: AppTypography.bodyLarge.copyWith(
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
                buttonLabel: _isCreatingIntent
                    ? 'Creating Quote...'
                    : 'Proceed to Pay',
                onPressed: _isCreatingIntent
                    ? () {}
                    : () => _handleProceedToPayment(experience),
              ),
            ],
          );
        },
      ),
    );
  }
}
