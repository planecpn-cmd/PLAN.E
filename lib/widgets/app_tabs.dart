import 'package:flutter/material.dart';
import '../theme/theme.dart';

class AppTabs extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final bool isScrollable;

  const AppTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.isScrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabWidgets = List.generate(tabs.length, (index) {
      final bool isSelected = index == selectedIndex;
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppTouchTarget.minSize),
          child: InkWell(
            onTap: () => onTabSelected(index),
            borderRadius: AppRadii.borderPill,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl20,
                vertical: AppSpacing.sm8,
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.forest : AppColors.transparent,
                borderRadius: AppRadii.borderPill,
              ),
              child: Text(
                tabs[index],
                style: AppTypography.bodyMedium.copyWith(
                  color: isSelected ? AppColors.ivory : AppColors.ink,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      );
    });

    final Widget tabContainer = Container(
      padding: const EdgeInsets.all(AppSpacing.xs4),
      decoration: const BoxDecoration(
        color: AppColors.sage,
        borderRadius: AppRadii.borderPill,
      ),
      child: isScrollable
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: tabWidgets),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: tabWidgets
                  .map((w) => Expanded(child: Center(child: w)))
                  .toList(),
            ),
    );

    return tabContainer;
  }
}
