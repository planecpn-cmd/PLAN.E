// RM-24 Host Step 4 Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
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
      text: data.accountNumber.isNotEmpty
          ? data.accountNumber
          : '01901010023849',
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
      body: PlanEBackground(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.ink),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Host Application',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.forest,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.sage,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Step 4 of 4',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.forest,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Bank Payout Details',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.forest,
                  ),
                ),
                const SizedBox(height: 16),
                const ProgressSteps(
                  steps: [
                    'Basic Info',
                    'Experience',
                    'ID Verify',
                    'Bank Details',
                  ],
                  currentStep: 3,
                ),
                const SizedBox(height: 20),

                PlanECard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bank / Payout Partner',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.forest,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedBank,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                        ),
                        items: _banks.map((b) {
                          return DropdownMenuItem(
                            value: b,
                            child: Text(
                              b,
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedBank = val);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

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
                      const SizedBox(height: 16),

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
                      const SizedBox(height: 16),

                      AppTextField(
                        controller: _branchController,
                        label: 'Bank Branch Location',
                        hint: 'e.g. Kantipath Branch, Kathmandu',
                        prefixIcon: const Icon(Icons.location_city_outlined),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                AppButton(
                  label: 'SUBMIT HOST APPLICATION',
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
    );
  }
}
