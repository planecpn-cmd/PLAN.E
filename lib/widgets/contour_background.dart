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
    final corner = Offset(size.width * .84, size.height * .04);
    _paintContourRings(canvas, corner);
    _paintRadialTicks(canvas, corner);
    _paintWaveLine(canvas, size, size.height * .30, 6);
    _paintSparkles(canvas, size);
    _paintMountainSilhouette(canvas, size);
  }

  // Nested wobbly rings — reads as a topographic map contour around a peak
  // just off-canvas, matching the corner motif used across every mockup.
  void _paintContourRings(Canvas canvas, Offset origin) {
    final paint = Paint()
      ..color = AppColors.gold.withValues(alpha: .16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8;
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

  // Short radial ticks between the contour rings — gives the corner motif
  // the mandala/compass-rose texture seen behind the trip-detail header.
  void _paintRadialTicks(Canvas canvas, Offset origin) {
    final paint = Paint()
      ..color = AppColors.gold.withValues(alpha: .18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8;
    for (var i = 0; i < 16; i++) {
      final angle = i / 16 * math.pi * 2;
      final dir = Offset(math.cos(angle), math.sin(angle) * .6);
      final inner = origin + dir * 150;
      final outer = origin + dir * 172;
      canvas.drawLine(inner, outer, paint);
    }
  }

  // A single flowing river/contour line drifting across the canvas —
  // the wave doodle seen on the confirmation and application screens.
  void _paintWaveLine(Canvas canvas, Size size, double centerY, double amplitude) {
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
      Offset(.14, .09), Offset(.72, .16), Offset(.90, .30),
      Offset(.06, .34), Offset(.55, .06), Offset(.28, .46),
      Offset(.86, .58), Offset(.10, .62), Offset(.46, .72),
      Offset(.68, .84), Offset(.20, .90), Offset(.92, .88),
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

  // Faint mountain-range line art anchored to the bottom edge.
  void _paintMountainSilhouette(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.forest.withValues(alpha: .09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    final baseY = size.height * .97;
    final path = Path()..moveTo(0, baseY);
    const peaks = [.18, .34, .5, .66, .82, 1.0];
    for (var i = 0; i < peaks.length; i++) {
      final x = peaks[i] * size.width;
      final peakHeight = (i.isEven ? 34.0 : 20.0);
      path.lineTo(x, baseY - peakHeight);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
