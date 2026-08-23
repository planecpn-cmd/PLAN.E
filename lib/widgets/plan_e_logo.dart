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
    final width = fontSize * 6.6;
    final height = fontSize * 1.2;
    final letterStyle = _style.copyWith(letterSpacing: 0, height: 1);

    Widget letter(String value, double center) => Positioned(
      left: width * center - fontSize * .5,
      top: 0,
      child: SizedBox(
        width: fontSize,
        height: height,
        child: Center(child: Text(value, style: letterStyle)),
      ),
    );

    final logo = Semantics(
      label: 'PLAN E logo',
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            letter('P', .076),
            letter('L', .254),
            Positioned(
              left: width * .482 - fontSize * .775,
              top: 0,
              child: MountainALetter(size: fontSize, color: color),
            ),
            letter('N', .730),
            letter('E', .924),
          ],
        ),
      ),
    );
    return centered ? Center(child: logo) : logo;
  }

  TextStyle get _style => TextStyle(
    fontFamily: 'serif',
    fontSize: fontSize,
    color: color,
    fontWeight: FontWeight.w700,
  );
}

/// The mountain-shaped "A" extracted from the supplied PLAN E artwork.
class MountainALetter extends StatelessWidget {
  final double size;
  final Color color;

  const MountainALetter({super.key, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: size * 1.55,
        height: size * 1.2,
        child: Image.asset(
          'assets/images/plan_e_mountain_a.png',
          fit: BoxFit.contain,
          color: color,
          colorBlendMode: BlendMode.srcIn,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
