// RM-17 Payment Methods Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
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

final paymentMethodsProvider = FutureProvider.family<List<PaymentMethodItem>, AppLocalizations>((ref, l10n) async {
  // Simulating async loading of saved payment methods
  await Future.delayed(const Duration(milliseconds: 300));
  return [
    PaymentMethodItem(
      id: 'khalti',
      title: l10n.khaltiWalletTitle,
      subtitle: l10n.khaltiWalletSub,
      icon: Icons.account_balance_wallet,
      isDefault: true,
    ),
    PaymentMethodItem(
      id: 'esewa',
      title: l10n.esewaWalletTitle,
      subtitle: l10n.esewaWalletSub,
      icon: Icons.account_balance_wallet_outlined,
      isDefault: false,
    ),
    PaymentMethodItem(
      id: 'cash',
      title: l10n.cashOnArrivalTitle,
      subtitle: l10n.cashOnArrivalSub,
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
    final l10n = AppLocalizations.of(context)!;
    final methodsAsync = ref.watch(paymentMethodsProvider(l10n));

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: Text(
          l10n.paymentMethods,
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
        onRetry: () => ref.refresh(paymentMethodsProvider(l10n)),
        data: (methods) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.savedPaymentGateways,
                  style: AppTypography.headingMedium.copyWith(fontSize: 18),
                ),
                const SizedBox(height: AppSpacing.xs4),
                Text(
                  l10n.paymentMethodsPageSub,
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
                                              l10n.defaultTag,
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
                  label: l10n.addPaymentGatewayBtn,
                  icon: Icons.add,
                  isFullWidth: true,
                  onPressed: () {
                    AppToast.show(context, message: l10n.paymentGatewayModeActive);
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
