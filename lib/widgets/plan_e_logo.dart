import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class PlanELogo extends StatelessWidget {
  final double fontSize;
  final bool centered;
  final Color color;

  const PlanELogo({
    super.key,
    this.fontSize = 28,
    this.centered = true,
    this.color = AppColors.forest,
  });

  @override
  Widget build(BuildContext context) {
    final logo = Semantics(
      label: 'PLAN E logo',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('PL', style: _style),
          Icon(Icons.landscape_outlined, size: fontSize * .9, color: color),
          Text('N E', style: _style),
        ],
      ),
    );
    return centered ? Center(child: logo) : logo;
  }

  TextStyle get _style => TextStyle(
        fontFamily: 'serif',
        fontSize: fontSize,
        letterSpacing: fontSize * .16,
        color: color,
        fontWeight: FontWeight.w700,
      );
}
