// RM-08 Map View
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'map_strings.dart';

class MapScreen extends StatefulWidget {
  final double? lat;
  final double? lng;
  final String? title;
  final String? meetingPoint;

  const MapScreen({
    super.key,
    this.lat,
    this.lng,
    this.title,
    this.meetingPoint,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  double _zoomLevel = 14.0;

  @override
  Widget build(BuildContext context) {
    // Extract values if passed via GoRouter extra Map argument
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final double lat = widget.lat ?? extra?['lat'] as double? ?? 27.7172;
    final double lng = widget.lng ?? extra?['lng'] as double? ?? 85.3240;
    final String experienceTitle = widget.title ?? extra?['title'] as String? ?? 'Experience Location';
    final String meetingText = widget.meetingPoint ?? extra?['meetingPoint'] as String? ?? MapStrings.defaultMeetingPoint;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          widget.title ?? MapStrings.pageTitle,
          style: AppTypography.headingMedium,
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Map Visual Viewport Shell
            Expanded(
              child: Stack(
                children: [
                  // Stylized Vector Topographic Map Shell
                  Container(
                    width: double.infinity,
                    color: AppColors.sage,
                    child: CustomPaint(
                      painter: _MapGridPainter(),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Animated Pin Marker
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.8, end: 1.1),
                              duration: const Duration(seconds: 1),
                              curve: Curves.easeInOut,
                              builder: (context, scale, child) {
                                return Transform.scale(
                                  scale: scale,
                                  child: Container(
                                    padding: AppSpacing.paddingSm8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.forest,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.overlay,
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.location_on,
                                      color: AppColors.ivory,
                                      size: 32,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: AppSpacing.sm8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md12,
                                vertical: AppSpacing.xs4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.deep.withValues(alpha: 0.9),
                                borderRadius: AppRadii.borderPill,
                              ),
                              child: Text(
                                experienceTitle,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.ivory,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs4),
                            Text(
                              '${MapStrings.coordinatesLabel}: ${lat.toStringAsFixed(4)}° N, ${lng.toStringAsFixed(4)}° E',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.ink.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Zoom Controls Overlay (min touch targets >= 48dp)
                  Positioned(
                    right: AppSpacing.lg16,
                    top: AppSpacing.lg16,
                    child: Column(
                      children: [
                        _buildControlButton(
                          icon: Icons.add,
                          onPressed: () {
                            setState(() {
                              _zoomLevel = (_zoomLevel + 1).clamp(1.0, 20.0);
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm8),
                        _buildControlButton(
                          icon: Icons.remove,
                          onPressed: () {
                            setState(() {
                              _zoomLevel = (_zoomLevel - 1).clamp(1.0, 20.0);
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm8),
                        _buildControlButton(
                          icon: Icons.my_location,
                          onPressed: () {
                            setState(() {
                              _zoomLevel = 14.0;
                            });
                            AppToast.show(
                              context,
                              message: 'Centered on meeting point',
                              variant: AppToastVariant.info,
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Zoom indicator pill
                  Positioned(
                    left: AppSpacing.lg16,
                    top: AppSpacing.lg16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.9),
                        borderRadius: AppRadii.borderPill,
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Text(
                        'Zoom: ${_zoomLevel.toInt()}x',
                        style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Text Meeting Point Card Fallback
            Container(
              width: double.infinity,
              padding: AppSpacing.paddingXl20,
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg24)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.overlay,
                    blurRadius: 12,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.place, color: AppColors.forest, size: 24),
                      SizedBox(width: AppSpacing.sm8),
                      Expanded(
                        child: Text(
                          MapStrings.meetingPointHeader,
                          style: AppTypography.headingMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm8),
                  Text(
                    meetingText,
                    style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpacing.md12),
                  Text(
                    MapStrings.landmarkHeader,
                    style: AppTypography.caption.copyWith(color: AppColors.disabledText),
                  ),
                  const SizedBox(height: AppSpacing.xs4),
                  const Text(
                    MapStrings.defaultLandmark,
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xl20),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton.secondary(
                          label: MapStrings.copyAddress,
                          icon: Icons.copy,
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: '$meetingText\n${MapStrings.defaultLandmark}'));
                            AppToast.show(
                              context,
                              message: MapStrings.addressCopied,
                              variant: AppToastVariant.success,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md12),
                      Expanded(
                        child: AppButton(
                          label: MapStrings.openExternalMaps,
                          icon: Icons.directions,
                          onPressed: () {
                            AppToast.show(
                              context,
                              message: 'Opening external map navigation...',
                              variant: AppToastVariant.info,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      width: AppTouchTarget.minSize,
      height: AppTouchTarget.minSize,
      decoration: const BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.overlay,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: AppColors.forest, size: 22),
        onPressed: onPressed,
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.borderSubtle.withValues(alpha: 0.5)
      ..strokeWidth = 1.0;

    const double step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw subtle mountain contour lines
    final contourPaint = Paint()
      ..color = AppColors.forest.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    path.moveTo(0, size.height * 0.4);
    path.cubicTo(
      size.width * 0.25, size.height * 0.2,
      size.width * 0.75, size.height * 0.6,
      size.width, size.height * 0.3,
    );
    canvas.drawPath(path, contourPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
