// RM-19 Language & Region Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_toast.dart';

class LanguageRegionScreen extends ConsumerStatefulWidget {
  const LanguageRegionScreen({super.key});

  @override
  ConsumerState<LanguageRegionScreen> createState() => _LanguageRegionScreenState();
}

class _LanguageRegionScreenState extends ConsumerState<LanguageRegionScreen> {
  String _selectedLanguage = 'en';
  String _selectedCurrency = 'npr';

  final List<Map<String, String>> _languages = const [
    {'code': 'en', 'name': 'English', 'native': 'English (Default)'},
    {'code': 'ne', 'name': 'Nepali', 'native': 'नेपाली'},
    {'code': 'new', 'name': 'Nepal Bhasa', 'native': 'नेपाल भाषा'},
    {'code': 'ta', 'name': 'Tamang', 'native': 'तामाङ'},
  ];

  final List<Map<String, String>> _currencies = const [
    {'code': 'npr', 'symbol': 'Rs.', 'name': 'Nepalese Rupee (NPR)'},
    {'code': 'usd', 'symbol': '\$', 'name': 'US Dollar (USD)'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: Text(
          'Language & Region',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'App Language',
              style: AppTypography.headingMedium.copyWith(fontSize: 18),
            ),
            const SizedBox(height: AppSpacing.xs4),
            Text(
              'Select your preferred display language.',
              style: AppTypography.caption.copyWith(color: AppColors.disabledText),
            ),
            const SizedBox(height: AppSpacing.md12),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: List.generate(_languages.length, (index) {
                  final lang = _languages[index];
                  final bool isSelected = _selectedLanguage == lang['code'];
                  final bool isLast = index == _languages.length - 1;

                  return Column(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() => _selectedLanguage = lang['code']!);
                          AppToast.show(
                            context,
                            message: 'Language changed to ${lang['name']}',
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg16,
                            vertical: AppSpacing.md12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lang['name']!,
                                      style: AppTypography.bodyLarge.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      lang['native']!,
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.disabledText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle, color: AppColors.forest, size: 22)
                              else
                                const Icon(Icons.radio_button_unchecked, color: AppColors.border, size: 22),
                            ],
                          ),
                        ),
                      ),
                      if (!isLast) const Divider(height: 1, color: AppColors.borderSubtle),
                    ],
                  );
                }),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl24),

            Text(
              'Currency Display',
              style: AppTypography.headingMedium.copyWith(fontSize: 18),
            ),
            const SizedBox(height: AppSpacing.xs4),
            Text(
              'Prices are calculated in paisa (NPR) and formatted via AppFormatters.',
              style: AppTypography.caption.copyWith(color: AppColors.disabledText),
            ),
            const SizedBox(height: AppSpacing.md12),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: List.generate(_currencies.length, (index) {
                  final curr = _currencies[index];
                  final bool isSelected = _selectedCurrency == curr['code'];
                  final bool isLast = index == _currencies.length - 1;

                  return Column(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() => _selectedCurrency = curr['code']!);
                          AppToast.show(context, message: 'Currency preference updated');
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg16,
                            vertical: AppSpacing.md12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: AppColors.sage,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  curr['symbol']!,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.forest,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md12),
                              Expanded(
                                child: Text(
                                  curr['name']!,
                                  style: AppTypography.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle, color: AppColors.forest, size: 22)
                              else
                                const Icon(Icons.radio_button_unchecked, color: AppColors.border, size: 22),
                            ],
                          ),
                        ),
                      ),
                      if (!isLast) const Divider(height: 1, color: AppColors.borderSubtle),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
