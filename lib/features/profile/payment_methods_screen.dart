// RM-17 Payment Methods Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/async_value_view.dart';

class PaymentMethodItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isDefault;

  const PaymentMethodItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isDefault = false,
  });
}

final paymentMethodsProvider = FutureProvider<List<PaymentMethodItem>>((ref) async {
  // Simulating async loading of saved payment methods
  await Future.delayed(const Duration(milliseconds: 300));
  return const [
    PaymentMethodItem(
      id: 'khalti',
      title: 'Khalti Wallet',
      subtitle: 'Primary payment gateway (+977 9800000000)',
      icon: Icons.account_balance_wallet,
      isDefault: true,
    ),
    PaymentMethodItem(
      id: 'esewa',
      title: 'eSewa Mobile Wallet',
      subtitle: 'Instant online payout & booking',
      icon: Icons.account_balance_wallet_outlined,
      isDefault: false,
    ),
    PaymentMethodItem(
      id: 'cash',
      title: 'Cash on Arrival',
      subtitle: 'Pay directly to local host at check-in',
      icon: Icons.payments_outlined,
      isDefault: false,
    ),
  ];
});

class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  ConsumerState<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
  String _selectedId = 'khalti';

  @override
  Widget build(BuildContext context) {
    final methodsAsync = ref.watch(paymentMethodsProvider);

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: Text(
          'Payment Methods',
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
      body: AsyncValueView<List<PaymentMethodItem>>(
        value: methodsAsync,
        onRetry: () => ref.refresh(paymentMethodsProvider),
        data: (methods) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saved Payment Gateways',
                  style: AppTypography.headingMedium.copyWith(fontSize: 18),
                ),
                const SizedBox(height: AppSpacing.xs4),
                Text(
                  'Choose your preferred payment method for booking local experiences.',
                  style: AppTypography.caption.copyWith(color: AppColors.disabledText),
                ),
                const SizedBox(height: AppSpacing.lg16),
                Expanded(
                  child: ListView.separated(
                    itemCount: methods.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md12),
                    itemBuilder: (context, index) {
                      final item = methods[index];
                      final bool isSelected = _selectedId == item.id;

                      return InkWell(
                        onTap: () {
                          setState(() => _selectedId = item.id);
                          AppToast.show(
                            context,
                            message: '${item.title} set as default payment method',
                          );
                        },
                        borderRadius: AppRadii.borderMd16,
                        child: AppCard(
                          borderColor: isSelected ? AppColors.forest : AppColors.borderSubtle,
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.sage : AppColors.cardBackgroundAlt,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  item.icon,
                                  color: AppColors.forest,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          item.title,
                                          style: AppTypography.bodyLarge.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (item.isDefault && isSelected) ...[
                                          const SizedBox(width: AppSpacing.sm8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.xs4 + 2,
                                              vertical: 2,
                                            ),
                                            decoration: const BoxDecoration(
                                              color: AppColors.forest,
                                              borderRadius: AppRadii.borderPill,
                                            ),
                                            child: Text(
                                              'DEFAULT',
                                              style: AppTypography.caption.copyWith(
                                                color: AppColors.ivory,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.xs4),
                                    Text(
                                      item.subtitle,
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.disabledText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                color: isSelected ? AppColors.forest : AppColors.border,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                AppButton.secondary(
                  label: 'Add Payment Gateway',
                  icon: Icons.add,
                  isFullWidth: true,
                  onPressed: () {
                    AppToast.show(context, message: 'Payment gateway integration mode active');
                  },
                ),
                const SizedBox(height: AppSpacing.md12),
              ],
            ),
          );
        },
      ),
    );
  }
}
