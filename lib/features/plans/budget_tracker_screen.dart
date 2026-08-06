// RM-13 Budget Tracker
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../models/budget_entry.dart';
import '../../providers/trip_tools_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/empty_state_view.dart';
import 'trip_tools_strings.dart';

class BudgetTrackerScreen extends ConsumerWidget {
  final String bookingId;

  const BudgetTrackerScreen({
    super.key,
    required this.bookingId,
  });

  void _showAddExpenseModal(BuildContext context, WidgetRef ref) {
    final labelController = TextEditingController();
    final amountController = TextEditingController();
    String selectedCategory = TripToolsStrings.expenseCategories.first;
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.lg16,
                right: AppSpacing.lg16,
                top: AppSpacing.xl20,
                bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TripToolsStrings.addExpenseDialogTitle,
                    style: AppTypography.headingMedium.copyWith(color: AppColors.ink),
                  ),
                  const SizedBox(height: AppSpacing.lg16),

                  // Label Field
                  TextField(
                    controller: labelController,
                    autofocus: true,
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
                    decoration: InputDecoration(
                      labelText: 'Expense Name',
                      hintText: TripToolsStrings.expenseLabelHint,
                      hintStyle: AppTypography.bodyMedium.copyWith(
                        color: AppColors.disabledText,
                      ),
                      filled: true,
                      fillColor: AppColors.sage,
                      border: const OutlineInputBorder(
                        borderRadius: AppRadii.borderSm8,
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md12),

                  // Amount NPR Field
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
                    decoration: InputDecoration(
                      labelText: 'Amount (NPR / Rs.)',
                      hintText: TripToolsStrings.expenseAmountHint,
                      prefixText: 'Rs. ',
                      prefixStyle: AppTypography.bodyMedium.copyWith(
                        color: AppColors.forest,
                        fontWeight: FontWeight.bold,
                      ),
                      filled: true,
                      fillColor: AppColors.sage,
                      border: const OutlineInputBorder(
                        borderRadius: AppRadii.borderSm8,
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md12),

                  // Category Dropdown
                  Text(
                    TripToolsStrings.categoryLabel,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md12),
                    decoration: const BoxDecoration(
                      color: AppColors.sage,
                      borderRadius: AppRadii.borderSm8,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCategory,
                        isExpanded: true,
                        dropdownColor: AppColors.cardBackground,
                        items: TripToolsStrings.expenseCategories
                            .map(
                              (cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(
                                  cat,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              selectedCategory = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl20),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: TripToolsStrings.saveExpenseAction,
                      variant: AppButtonVariant.primary,
                      onPressed: () {
                        final label = labelController.text.trim();
                        final amountRupees = double.tryParse(amountController.text.trim());

                        if (label.isEmpty || amountRupees == null || amountRupees <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(TripToolsStrings.invalidAmountError),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }

                        final int amountPaisa = (amountRupees * 100).round();

                        ref.read(budgetTrackerProvider(bookingId).notifier).addExpense(
                              label: label,
                              amountPaisa: amountPaisa,
                              category: selectedCategory,
                              spentOn: selectedDate,
                            );

                        Navigator.of(sheetContext).pop();
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetAsync = ref.watch(budgetTrackerProvider(bookingId));

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: Text(
          TripToolsStrings.budgetTrackerTitle,
          style: AppTypography.headingMedium.copyWith(color: AppColors.ink),
        ),
        backgroundColor: AppColors.ivory,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.forest),
            tooltip: TripToolsStrings.addExpenseButton,
            onPressed: () => _showAddExpenseModal(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: AsyncValueView<List<BudgetEntry>>(
          value: budgetAsync,
          isEmpty: (entries) => entries.isEmpty,
          emptyView: EmptyStateView(
            title: TripToolsStrings.budgetEmptyTitle,
            description: TripToolsStrings.budgetEmptyDesc,
            actionLabel: TripToolsStrings.addExpenseButton,
            onActionPressed: () => _showAddExpenseModal(context, ref),
          ),
          onRetry: () => ref.invalidate(budgetTrackerProvider(bookingId)),
          data: (entries) {
            final int totalPaisa = entries.fold<int>(
              0,
              (sum, item) => sum + item.amountPaisa,
            );

            // Group expenses by category
            final Map<String, int> categoryTotals = {};
            for (final entry in entries) {
              categoryTotals[entry.category] =
                  (categoryTotals[entry.category] ?? 0) + entry.amountPaisa;
            }

            return SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total Spent Card
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          TripToolsStrings.totalSpentLabel,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.disabledText,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs4),
                        Text(
                          AppFormatters.formatNpr(totalPaisa),
                          style: AppTypography.headingLarge.copyWith(
                            color: AppColors.forest,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs4),
                        Text(
                          'Total of ${entries.length} logged ${entries.length == 1 ? "expense" : "expenses"}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.ink.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg16),

                  // Category Breakdown Section
                  if (categoryTotals.isNotEmpty) ...[
                    Text(
                      TripToolsStrings.categoryBreakdownTitle,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm8),
                    AppCard(
                      child: Column(
                        children: categoryTotals.entries.map((catEntry) {
                          final String categoryName = catEntry.key;
                          final int catPaisa = catEntry.value;
                          final double pct =
                              totalPaisa > 0 ? catPaisa / totalPaisa : 0;

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xs4,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          _getCategoryIcon(categoryName),
                                          size: 16,
                                          color: AppColors.forest,
                                        ),
                                        const SizedBox(width: AppSpacing.xs4),
                                        Text(
                                          categoryName,
                                          style: AppTypography.bodyMedium.copyWith(
                                            color: AppColors.ink,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      AppFormatters.formatNpr(catPaisa),
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: AppColors.forest,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xs4),
                                ClipRRect(
                                  borderRadius: AppRadii.borderPill,
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    minHeight: 4,
                                    backgroundColor: AppColors.sage,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                      AppColors.forest,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs4),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg16),
                  ],

                  // Log Expense Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.forest,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md12,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadii.borderMd16,
                        ),
                      ),
                      icon: const Icon(Icons.account_balance_wallet_outlined, size: 20),
                      label: Text(
                        TripToolsStrings.addExpenseButton,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.forest,
                        ),
                      ),
                      onPressed: () => _showAddExpenseModal(context, ref),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg16),

                  // Recent Expenses Header
                  Text(
                    TripToolsStrings.recentExpensesTitle,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm8),

                  // Expense Items List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: entries.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.sm8),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return _buildExpenseItem(context, ref, entry);
                    },
                  ),

                  const SizedBox(height: AppSpacing.xxl24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildExpenseItem(
    BuildContext context,
    WidgetRef ref,
    BudgetEntry entry,
  ) {
    final String formattedDate = AppFormatters.formatTripDate(
      entry.spentOn,
      pattern: 'd MMM yyyy',
    );

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.sage,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                _getCategoryIcon(entry.category),
                color: AppColors.forest,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.label,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs4),
                Row(
                  children: [
                    Text(
                      entry.category,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs4),
                    Text(
                      '• $formattedDate',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.disabledText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AppFormatters.formatNpr(entry.amountPaisa),
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.forest,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: AppColors.disabledText,
                ),
                onPressed: () {
                  ref
                      .read(budgetTrackerProvider(bookingId).notifier)
                      .deleteExpense(entry.id);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case TripToolsStrings.categoryFood:
        return Icons.restaurant;
      case TripToolsStrings.categoryTransport:
        return Icons.directions_bus;
      case TripToolsStrings.categoryPermits:
        return Icons.assignment_outlined;
      case TripToolsStrings.categoryGear:
        return Icons.backpack_outlined;
      case TripToolsStrings.categoryStay:
        return Icons.hotel_outlined;
      case TripToolsStrings.categoryTips:
        return Icons.volunteer_activism_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }
}
