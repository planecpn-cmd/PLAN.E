import 'package:flutter/material.dart';
import '../theme/theme.dart';
import 'section_header.dart';

class ContentRail extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final List<Widget> items;
  final double height;
  final double itemSpacing;
  final EdgeInsetsGeometry padding;

  const ContentRail({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onActionTap,
    required this.items,
    this.height = 240.0,
    this.itemSpacing = AppSpacing.md12,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.lg16),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: padding,
          child: SectionHeader(
            title: title,
            subtitle: subtitle,
            actionLabel: actionLabel,
            onActionTap: onActionTap,
          ),
        ),
        const SizedBox(height: AppSpacing.md12),
        SizedBox(
          height: height,
          child: ListView.separated(
            padding: padding,
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (context, index) => SizedBox(width: itemSpacing),
            itemBuilder: (context, index) => items[index],
          ),
        ),
      ],
    );
  }
}
