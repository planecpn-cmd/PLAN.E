// RM-23 Host Step 3 Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'host_provider.dart';

class HostStep3Screen extends ConsumerStatefulWidget {
  const HostStep3Screen({super.key});

  @override
  ConsumerState<HostStep3Screen> createState() => _HostStep3ScreenState();
}

class _HostStep3ScreenState extends ConsumerState<HostStep3Screen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _idNumberController;
  String _selectedIdType = 'Citizenship Card (Nagarikta)';
  bool _idImageUploaded = false;

  final List<String> _idTypes = const [
    'Citizenship Card (Nagarikta)',
    'Nepali Passport',
    'PAN Card / Business License',
    'Voter ID Card',
  ];

  @override
  void initState() {
    super.initState();
    final data = ref.read(hostApplicationProvider);
    _idNumberController = TextEditingController(
      text: data.idNumber.isNotEmpty ? data.idNumber : '27-01-78-04829',
    );
    _idImageUploaded = data.idImageUploaded;
    if (_idTypes.contains(data.idType)) {
      _selectedIdType = data.idType;
    }
  }

  @override
  void dispose() {
    _idNumberController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (!_formKey.currentState!.validate()) return;
    if (!_idImageUploaded) {
      AppToast.show(context, message: 'Please upload a photo of your ID document');
      return;
    }

    ref.read(hostApplicationProvider.notifier).updateStep3(
          idType: _selectedIdType,
          idNumber: _idNumberController.text.trim(),
          idImageUploaded: true,
        );

    context.push('/host/step-4');
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
                    'Step 3 of 4',
                    style: TextStyle(fontSize: 12, color: AppColors.forest, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Identity Verification',
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
                  currentStep: 2,
                ),
                const SizedBox(height: 20),

                PlanECard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Government Issued ID Type',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.forest),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedIdType,
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
                        items: _idTypes.map((t) {
                          return DropdownMenuItem(
                            value: t,
                            child: Text(t, style: const TextStyle(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedIdType = val);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      AppTextField(
                        controller: _idNumberController,
                        label: 'Document Identification Number',
                        hint: 'e.g. 27-01-78-04829',
                        prefixIcon: const Icon(Icons.badge),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Document number is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        'Upload Front & Back Photo',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.forest),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () {
                          setState(() => _idImageUploaded = true);
                          AppToast.show(
                            context,
                            message: 'Document image uploaded successfully',
                            variant: AppToastVariant.success,
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          height: 110,
                          decoration: BoxDecoration(
                            color: _idImageUploaded ? AppColors.successContainer : AppColors.sage,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _idImageUploaded ? AppColors.success : AppColors.border,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _idImageUploaded ? Icons.check_circle : Icons.cloud_upload_outlined,
                                size: 32,
                                color: _idImageUploaded ? AppColors.success : AppColors.forest,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _idImageUploaded
                                    ? 'Document Attached (Tap to change)'
                                    : 'Tap to upload citizenship photo / PDF',
                                style: TextStyle(
                                  color: _idImageUploaded ? AppColors.success : AppColors.forest,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                AppButton(
                  label: 'CONTINUE TO STEP 4',
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
