// RM-12 Gear Checklist
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/gear_checklist_item.dart';
import '../../providers/trip_tools_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/empty_state_view.dart';
import 'trip_tools_strings.dart';

class GearChecklistScreen extends ConsumerWidget {
  final String bookingId;

  const GearChecklistScreen({
    super.key,
    required this.bookingId,
  });

  void _showAddCustomItemDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadii.borderMd16,
          ),
          title: Text(
            TripToolsStrings.addGearDialogTitle,
            style: AppTypography.headingMedium.copyWith(color: AppColors.ink),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
            decoration: InputDecoration(
              hintText: TripToolsStrings.gearItemLabelHint,
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
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (controller.text.trim().isNotEmpty) {
                ref
                    .read(gearChecklistProvider(bookingId).notifier)
                    .addItem(controller.text.trim());
                Navigator.of(dialogContext).pop();
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                TripToolsStrings.cancelAction,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.disabledText,
                ),
              ),
            ),
            AppButton(
              label: TripToolsStrings.addAction,
              variant: AppButtonVariant.primary,
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  ref
                      .read(gearChecklistProvider(bookingId).notifier)
                      .addItem(controller.text.trim());
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gearAsync = ref.watch(gearChecklistProvider(bookingId));

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: Text(
          TripToolsStrings.gearChecklistTitle,
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
            tooltip: TripToolsStrings.addGearButton,
            onPressed: () => _showAddCustomItemDialog(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: AsyncValueView<List<GearChecklistItem>>(
          value: gearAsync,
          isEmpty: (items) => items.isEmpty,
          emptyView: EmptyStateView(
            title: TripToolsStrings.gearEmptyTitle,
            description: TripToolsStrings.gearEmptyDesc,
            actionLabel: TripToolsStrings.addGearButton,
            onActionPressed: () => _showAddCustomItemDialog(context, ref),
          ),
          onRetry: () => ref.invalidate(gearChecklistProvider(bookingId)),
          data: (items) {
            final int total = items.length;
            final int checkedCount = items.where((i) => i.isChecked).length;
            final double progress = total > 0 ? checkedCount / total : 0.0;

            return SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress Card
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              TripToolsStrings.gearProgressLabel,
                              style: AppTypography.bodyLarge.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$checkedCount / $total (${(progress * 100).round()}%)',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.forest,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md12),
                        ClipRRect(
                          borderRadius: AppRadii.borderPill,
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: AppColors.sage,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.forest,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg16),

                  // Add Custom Item Button
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
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      label: Text(
                        TripToolsStrings.addGearButton,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.forest,
                        ),
                      ),
                      onPressed: () => _showAddCustomItemDialog(context, ref),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg16),

                  // Checklist List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.sm8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildChecklistItem(context, ref, item);
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

  Widget _buildChecklistItem(
    BuildContext context,
    WidgetRef ref,
    GearChecklistItem item,
  ) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md12,
        vertical: AppSpacing.sm8,
      ),
      child: Row(
        children: [
          Checkbox(
            value: item.isChecked,
            activeColor: AppColors.forest,
            checkColor: AppColors.ivory,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            onChanged: (_) {
              ref
                  .read(gearChecklistProvider(bookingId).notifier)
                  .toggleItem(item.id);
            },
          ),
          const SizedBox(width: AppSpacing.sm8),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.label,
                    style: AppTypography.bodyMedium.copyWith(
                      color: item.isChecked
                          ? AppColors.disabledText
                          : AppColors.ink,
                      decoration: item.isChecked
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                ),
                if (item.isCustom) ...[
                  const SizedBox(width: AppSpacing.xs4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs4,
                      vertical: 2,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.sage,
                      borderRadius: AppRadii.borderSm8,
                    ),
                    child: Text(
                      TripToolsStrings.customBadge,
                      style: AppTypography.caption.copyWith(
                        fontSize: 10,
                        color: AppColors.forest,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (item.isCustom)
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                size: 20,
                color: AppColors.disabledText,
              ),
              onPressed: () {
                ref
                    .read(gearChecklistProvider(bookingId).notifier)
                    .deleteItem(item.id);
              },
            ),
        ],
      ),
    );
  }
}
