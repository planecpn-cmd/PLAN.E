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
    _paintOrganicWash(canvas, size);
    _paintWaveLine(canvas, size, size.height * .30, 6);
    _paintSparkles(canvas, size);
  }

  // Soft abstract fields retain PLAN E's organic character without making
  // every screen look like a topographic map or mountain product.
  void _paintOrganicWash(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(size.width * .93, size.height * .03),
      size.width * .34,
      Paint()..color = AppColors.sage.withValues(alpha: .16),
    );
    canvas.drawCircle(
      Offset(size.width * .04, size.height * .92),
      size.width * .26,
      Paint()..color = AppColors.gold.withValues(alpha: .035),
    );
  }

  // A single flowing river/contour line drifting across the canvas —
  // the wave doodle seen on the confirmation and application screens.
  void _paintWaveLine(
    Canvas canvas,
    Size size,
    double centerY,
    double amplitude,
  ) {
    final paint = Paint()
      ..color = AppColors.gold.withValues(alpha: .14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .9;
    final path = Path()..moveTo(0, centerY);
    const steps = 40;
    for (var i = 1; i <= steps; i++) {
      final x = size.width * i / steps;
      final y = centerY + amplitude * math.sin(i / steps * math.pi * 3);
      path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  // Small scattered dot/diamond accents, deterministic (seeded by index, not
  // math.Random) so every rebuild paints identical marks — no flicker.
  void _paintSparkles(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.gold.withValues(alpha: .28);
    const positions = [
      Offset(.14, .09),
      Offset(.72, .16),
      Offset(.90, .30),
      Offset(.06, .34),
      Offset(.55, .06),
      Offset(.28, .46),
      Offset(.86, .58),
      Offset(.10, .62),
      Offset(.46, .72),
      Offset(.68, .84),
      Offset(.20, .90),
      Offset(.92, .88),
    ];
    for (var i = 0; i < positions.length; i++) {
      final p = positions[i];
      final center = Offset(p.dx * size.width, p.dy * size.height);
      if (i.isEven) {
        canvas.drawCircle(center, 1.6, paint);
      } else {
        _drawDiamond(canvas, center, 3.2, paint);
      }
    }
  }

  void _drawDiamond(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - r)
      ..lineTo(center.dx + r, center.dy)
      ..lineTo(center.dx, center.dy + r)
      ..lineTo(center.dx - r, center.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
