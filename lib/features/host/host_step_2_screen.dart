// PL-19 Host Step 2 Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
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
    _priceRupeesController = TextEditingController(
      text: rupees > 0 ? '$rupees' : '3500',
    );
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

    ref
        .read(hostApplicationProvider.notifier)
        .updateStep2(
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
                    'Step 2 of 4',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.forest,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Experience Details',
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
                  currentStep: 1,
                ),
                const SizedBox(height: 20),

                PlanECard(
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
                      const SizedBox(height: 16),

                      const Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.forest,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
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
                        items: _categories.map((c) {
                          return DropdownMenuItem(
                            value: c,
                            child: Text(
                              c,
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCategory = val);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: CounterField(
                              label: 'Duration (Hours)',
                              value: _durationHours,
                              min: 1,
                              max: 72,
                              onChanged: (val) =>
                                  setState(() => _durationHours = val),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CounterField(
                              label: 'Max Guests',
                              value: _maxGroupSize,
                              min: 1,
                              max: 30,
                              onChanged: (val) =>
                                  setState(() => _maxGroupSize = val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

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
                      const SizedBox(height: 4),
                      Text(
                        'Formatted display: ${AppFormatters.formatNpr(_parsedPricePaisa)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.forest,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      AppTextField(
                        controller: _descController,
                        label: 'Full Description',
                        hint:
                            'Explain what is included, schedule, guidelines...',
                        prefixIcon: const Icon(Icons.description_outlined),
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                AppButton(
                  label: 'CONTINUE TO STEP 3',
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
