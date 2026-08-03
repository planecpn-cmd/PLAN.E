// RM-23 Host Step 3 Screen
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
              currentStep: 2,
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
                      'Step 3: Identity Verification',
                      style: AppTypography.headingMedium.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: AppSpacing.xs4),
                    Text(
                      'To protect travelers, PLAN E requires verified Nepali citizenship or business registration.',
                      style: AppTypography.caption.copyWith(color: AppColors.disabledText),
                    ),
                    const SizedBox(height: AppSpacing.lg16),

                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Government Issued ID Type',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs4),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedIdType,
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
                            items: _idTypes.map((t) {
                              return DropdownMenuItem(
                                value: t,
                                child: Text(t, style: AppTypography.bodyMedium),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedIdType = val);
                              }
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg16),

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
                          const SizedBox(height: AppSpacing.xl20),

                          Text(
                            'Upload Front & Back Photo',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs4),
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
                              height: 120,
                              decoration: BoxDecoration(
                                color: _idImageUploaded ? AppColors.successContainer : AppColors.sage,
                                borderRadius: AppRadii.borderMd16,
                                border: Border.all(
                                  color: _idImageUploaded ? AppColors.success : AppColors.border,
                                  style: BorderStyle.solid,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _idImageUploaded ? Icons.check_circle : Icons.cloud_upload_outlined,
                                    size: 36,
                                    color: _idImageUploaded ? AppColors.success : AppColors.forest,
                                  ),
                                  const SizedBox(height: AppSpacing.xs4),
                                  Text(
                                    _idImageUploaded
                                        ? 'Document Attached (Tap to change)'
                                        : 'Tap to upload citizenship photo / PDF',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: _idImageUploaded ? AppColors.success : AppColors.forest,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl24),

                    AppButton(
                      label: 'Continue to Step 4',
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
