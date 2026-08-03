// RM-22 Host Step 1 Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/progress_steps.dart';
import 'host_provider.dart';

class HostStep1Screen extends ConsumerStatefulWidget {
  const HostStep1Screen({super.key});

  @override
  ConsumerState<HostStep1Screen> createState() => _HostStep1ScreenState();
}

class _HostStep1ScreenState extends ConsumerState<HostStep1Screen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  String _selectedDistrict = 'Kathmandu';

  final List<String> _districts = const [
    'Kathmandu',
    'Lalitpur',
    'Bhaktapur',
    'Kaski (Pokhara)',
    'Solukhumbu (Everest)',
    'Kavre (Panauti)',
    'Mustang',
    'Chitwan',
    'Sankhuwasabha',
  ];

  @override
  void initState() {
    super.initState();
    final data = ref.read(hostApplicationProvider);
    _nameController = TextEditingController(text: data.fullName.isNotEmpty ? data.fullName : 'Siddharth Gurung');
    _phoneController = TextEditingController(text: data.phone.isNotEmpty ? data.phone : '+977 9849123456');
    _bioController = TextEditingController(
      text: data.bio.isNotEmpty
          ? data.bio
          : 'Local trekking guide with 8 years of experience leading cultural heritage homestays across Nepal.',
    );
    if (_districts.contains(data.district)) {
      _selectedDistrict = data.district;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (!_formKey.currentState!.validate()) return;

    ref.read(hostApplicationProvider.notifier).updateStep1(
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          district: _selectedDistrict,
          bio: _bioController.text.trim(),
        );

    context.push('/host/step-2');
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
              currentStep: 0,
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
                      'Step 1: Host Basic Details',
                      style: AppTypography.headingMedium.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: AppSpacing.xs4),
                    Text(
                      'Provide your contact and location details for host verification.',
                      style: AppTypography.caption.copyWith(color: AppColors.disabledText),
                    ),
                    const SizedBox(height: AppSpacing.lg16),

                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppTextField(
                            controller: _nameController,
                            label: 'Host / Business Name',
                            hint: 'e.g. Siddharth Gurung / Mountain View Homestay',
                            prefixIcon: const Icon(Icons.badge_outlined),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Host name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg16),

                          AppTextField(
                            controller: _phoneController,
                            label: 'Mobile Number',
                            hint: '+977 98XXXXXXXX',
                            prefixIcon: const Icon(Icons.phone_outlined),
                            keyboardType: TextInputType.phone,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Phone number is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg16),

                          Text(
                            'District / Primary Region',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs4),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedDistrict,
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
                            items: _districts.map((d) {
                              return DropdownMenuItem(
                                value: d,
                                child: Text(d, style: AppTypography.bodyMedium),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedDistrict = val);
                              }
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg16),

                          AppTextField(
                            controller: _bioController,
                            label: 'Host Background & Bio',
                            hint: 'Share your background, experience with travelers...',
                            prefixIcon: const Icon(Icons.notes),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl24),

                    AppButton(
                      label: 'Continue to Step 2',
                      icon: Icons.arrow_forward,
                      isFullWidth: true,
                      onPressed: _onNext,
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
