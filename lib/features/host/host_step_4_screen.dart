// RM-24 Host Step 4 Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/progress_steps.dart';
import 'host_provider.dart';

class HostStep4Screen extends ConsumerStatefulWidget {
  const HostStep4Screen({super.key});

  @override
  ConsumerState<HostStep4Screen> createState() => _HostStep4ScreenState();
}

class _HostStep4ScreenState extends ConsumerState<HostStep4Screen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _holderController;
  late TextEditingController _accountNoController;
  late TextEditingController _branchController;
  String _selectedBank = 'Global IME Bank Ltd.';
  bool _isSubmitting = false;

  final List<String> _banks = const [
    'Global IME Bank Ltd.',
    'Nabil Bank Ltd.',
    'NIC Asia Bank Ltd.',
    'Rastriya Banijya Bank',
    'Nepal Investment Mega Bank',
    'eSewa Merchant Wallet Payout',
    'Khalti Merchant Wallet Payout',
  ];

  @override
  void initState() {
    super.initState();
    final data = ref.read(hostApplicationProvider);
    _holderController = TextEditingController(
      text: data.accountName.isNotEmpty ? data.accountName : 'Siddharth Gurung',
    );
    _accountNoController = TextEditingController(
      text: data.accountNumber.isNotEmpty ? data.accountNumber : '01901010023849',
    );
    _branchController = TextEditingController(
      text: data.branch.isNotEmpty ? data.branch : 'Kantipath Main Branch',
    );
    if (_banks.contains(data.bankName)) {
      _selectedBank = data.bankName;
    }
  }

  @override
  void dispose() {
    _holderController.dispose();
    _accountNoController.dispose();
    _branchController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final notifier = ref.read(hostApplicationProvider.notifier);
      notifier.updateStep4(
        bankName: _selectedBank,
        accountName: _holderController.text.trim(),
        accountNumber: _accountNoController.text.trim(),
        branch: _branchController.text.trim(),
      );

      final success = await notifier.submitApplication();
      if (success && mounted) {
        AppToast.show(
          context,
          message: 'Host application submitted for review!',
          variant: AppToastVariant.success,
        );
        context.go('/host/submitted');
      }
    } catch (_) {
      if (mounted) {
        AppToast.show(
          context,
          message: 'Submission failed. Please check your network connection.',
          variant: AppToastVariant.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: Text(
          'Host Application',
          style: AppTypography.headingMedium.copyWith(color: AppColors.ink),
        ),
        backgroundColor: AppColors.ivory,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          constraints: AppTouchTarget.minConstraints,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg16),
            child: ProgressSteps(
              steps: ['Basic Info', 'Experience', 'ID Verify', 'Bank Details'],
              currentStep: 3,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step 4: Bank Payout Details',
                      style: AppTypography.headingMedium.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: AppSpacing.xs4),
                    Text(
                      'Direct earnings from bookings will be transferred to this account.',
                      style: AppTypography.caption.copyWith(color: AppColors.disabledText),
                    ),
                    const SizedBox(height: AppSpacing.lg16),

                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bank / Payout Partner',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs4),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedBank,
                            decoration: const InputDecoration(
                              filled: true,
                              fillColor: AppColors.white,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg16,
                                vertical: AppSpacing.md12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: AppRadii.borderMd16,
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: AppRadii.borderMd16,
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: AppRadii.borderMd16,
                                borderSide: BorderSide(color: AppColors.forest, width: 2),
                              ),
                            ),
                            items: _banks.map((b) {
                              return DropdownMenuItem(
                                value: b,
                                child: Text(b, style: AppTypography.bodyMedium),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedBank = val);
                              }
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg16),

                          AppTextField(
                            controller: _holderController,
                            label: 'Account Holder Full Name',
                            hint: 'Must match citizenship name exactly',
                            prefixIcon: const Icon(Icons.account_box_outlined),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Account holder name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg16),

                          AppTextField(
                            controller: _accountNoController,
                            label: 'Account Number / Wallet ID',
                            hint: '01901010023849',
                            prefixIcon: const Icon(Icons.numbers),
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Account number is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg16),

                          AppTextField(
                            controller: _branchController,
                            label: 'Bank Branch Location',
                            hint: 'e.g. Kantipath Branch, Kathmandu',
                            prefixIcon: const Icon(Icons.location_city_outlined),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl24),

                    AppButton(
                      label: 'Submit Host Application',
                      icon: Icons.check_circle_outline,
                      isFullWidth: true,
                      isLoading: _isSubmitting,
                      onPressed: _onSubmit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
