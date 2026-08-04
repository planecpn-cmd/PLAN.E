import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class PlanEBackground extends StatelessWidget {
  final Widget child;
  final bool safeArea;
  final EdgeInsets padding;

  const PlanEBackground({
    super.key,
    required this.child,
    this.safeArea = true,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return ColoredBox(
      color: AppColors.ivory,
      child: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _ContourPainter()),
            ),
          ),
          if (safeArea) SafeArea(child: content) else content,
        ],
      ),
    );
  }
}

class _ContourPainter extends CustomPainter {
  const _ContourPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold.withValues(alpha: .13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8;
    final origin = Offset(size.width * .84, size.height * .04);
    for (var ring = 0; ring < 7; ring++) {
      final path = Path();
      for (var i = 0; i <= 90; i++) {
        final angle = i / 90 * math.pi * 2;
        final wobble = 1 + .08 * math.sin(angle * 5 + ring);
        final rx = (44 + ring * 20) * wobble;
        final ry = (24 + ring * 13) * wobble;
        final point = Offset(origin.dx + math.cos(angle) * rx, origin.dy + math.sin(angle) * ry);
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
