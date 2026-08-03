// PL-19 Host Step 2 Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../theme/theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/counter_field.dart';
import '../../widgets/progress_steps.dart';
import 'host_provider.dart';

class HostStep2Screen extends ConsumerStatefulWidget {
  const HostStep2Screen({super.key});

  @override
  ConsumerState<HostStep2Screen> createState() => _HostStep2ScreenState();
}

class _HostStep2ScreenState extends ConsumerState<HostStep2Screen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _priceRupeesController;
  late TextEditingController _descController;
  String _selectedCategory = 'Trekking & Hiking';
  int _durationHours = 6;
  int _maxGroupSize = 8;

  final List<String> _categories = const [
    'Trekking & Hiking',
    'Homestay & Village Stay',
    'Culinary & Cooking',
    'Cultural & Heritage',
    'Handicrafts & Pottery',
    'Wildlife & Nature',
  ];

  @override
  void initState() {
    super.initState();
    final data = ref.read(hostApplicationProvider);
    _titleController = TextEditingController(
      text: data.experienceTitle.isNotEmpty
          ? data.experienceTitle
          : 'Kathmandu Valley Heritage Village Walk & Organic Lunch',
    );
    final int rupees = data.pricePaisa ~/ 100;
    _priceRupeesController = TextEditingController(text: rupees > 0 ? '$rupees' : '3500');
    _descController = TextEditingController(
      text: data.description.isNotEmpty
          ? data.description
          : 'Guided scenic walk through authentic Newari architecture, organic farm lunch, and traditional tea with host family.',
    );
    if (_categories.contains(data.category)) {
      _selectedCategory = data.category;
    }
    _durationHours = data.durationHours;
    _maxGroupSize = data.maxGroupSize;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceRupeesController.dispose();
    _descController.dispose();
    super.dispose();
  }

  int get _parsedPricePaisa {
    final int rupees = int.tryParse(_priceRupeesController.text.trim()) ?? 0;
    return rupees * 100;
  }

  void _onNext() {
    if (!_formKey.currentState!.validate()) return;

    ref.read(hostApplicationProvider.notifier).updateStep2(
          experienceTitle: _titleController.text.trim(),
          category: _selectedCategory,
          durationHours: _durationHours,
          maxGroupSize: _maxGroupSize,
          pricePaisa: _parsedPricePaisa,
          description: _descController.text.trim(),
        );

    context.push('/host/step-3');
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
              currentStep: 1,
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
                      'Step 2: Experience / Listing Details',
                      style: AppTypography.headingMedium.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: AppSpacing.xs4),
                    Text(
                      'Describe the experience or homestay service you plan to offer.',
                      style: AppTypography.caption.copyWith(color: AppColors.disabledText),
                    ),
                    const SizedBox(height: AppSpacing.lg16),

                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppTextField(
                            controller: _titleController,
                            label: 'Experience Title',
                            hint: 'e.g. Panauti Organic Homestay & Cooking Class',
                            prefixIcon: const Icon(Icons.explore_outlined),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Title is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg16),

                          Text(
                            'Category',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs4),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedCategory,
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
                            items: _categories.map((c) {
                              return DropdownMenuItem(
                                value: c,
                                child: Text(c, style: AppTypography.bodyMedium),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedCategory = val);
                              }
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg16),

                          Row(
                            children: [
                              Expanded(
                                child: CounterField(
                                  label: 'Duration (Hours)',
                                  value: _durationHours,
                                  min: 1,
                                  max: 72,
                                  onChanged: (val) => setState(() => _durationHours = val),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md12),
                              Expanded(
                                child: CounterField(
                                  label: 'Max Guests',
                                  value: _maxGroupSize,
                                  min: 1,
                                  max: 30,
                                  onChanged: (val) => setState(() => _maxGroupSize = val),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg16),

                          AppTextField(
                            controller: _priceRupeesController,
                            label: 'Price per Guest (in NPR)',
                            hint: '3500',
                            prefixIcon: const Icon(Icons.payments_outlined),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            validator: (val) {
                              final p = int.tryParse(val?.trim() ?? '');
                              if (p == null || p <= 0) {
                                return 'Enter a valid price in NPR';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.xs4),
                          Text(
                            'Formatted display: ${AppFormatters.formatNpr(_parsedPricePaisa)}',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.forest,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg16),

                          AppTextField(
                            controller: _descController,
                            label: 'Full Description',
                            hint: 'Explain what is included, schedule, guidelines...',
                            prefixIcon: const Icon(Icons.description_outlined),
                            maxLines: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl24),

                    AppButton(
                      label: 'Continue to Step 3',
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
