// RM-22 Host Step 1 Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.sage,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Step 1 of 4',
                    style: TextStyle(fontSize: 12, color: AppColors.forest, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Host Basic Details',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.forest,
                  ),
                ),
                const SizedBox(height: 16),
                const ProgressSteps(
                  steps: ['Basic Info', 'Experience', 'ID Verify', 'Bank Details'],
                  currentStep: 0,
                ),
                const SizedBox(height: 20),

                PlanECard(
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
                      const SizedBox(height: 16),

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
                      const SizedBox(height: 16),

                      const Text(
                        'District / Primary Region',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.forest),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedDistrict,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                        ),
                        items: _districts.map((d) {
                          return DropdownMenuItem(
                            value: d,
                            child: Text(d, style: const TextStyle(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedDistrict = val);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

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
                const SizedBox(height: 20),

                AppButton(
                  label: 'CONTINUE TO STEP 2',
                  icon: Icons.arrow_forward,
                  isFullWidth: true,
                  onPressed: _onNext,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
