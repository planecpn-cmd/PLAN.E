import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class PlanELogo extends StatelessWidget {
  final double fontSize;
  final bool centered;

  const PlanELogo({super.key, this.fontSize = 28, this.centered = true});

  @override
  Widget build(BuildContext context) {
    final logo = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('PL', style: _style),
        Icon(Icons.landscape_outlined, size: fontSize * .9, color: AppColors.forest),
        Text('N E', style: _style),
      ],
    );
    return centered ? Center(child: logo) : logo;
  }

  TextStyle get _style => TextStyle(
        fontFamily: 'serif',
        fontSize: fontSize,
        letterSpacing: fontSize * .16,
        color: AppColors.forest,
        fontWeight: FontWeight.w700,
      );
}
