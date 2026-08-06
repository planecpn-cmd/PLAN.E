// RM-08 Map View
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../models/experience.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'map_strings.dart';

enum MapStyle {
  topographic,
  satellite,
  terrain,
  standard;

  String get label {
    switch (this) {
      case MapStyle.topographic:
        return MapStrings.styleTopographic;
      case MapStyle.satellite:
        return MapStrings.styleSatellite;
      case MapStyle.terrain:
        return MapStrings.styleTerrain;
      case MapStyle.standard:
        return MapStrings.styleStandard;
    }
  }
}

class MapScreen extends ConsumerStatefulWidget {
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
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  static const double _defaultKathmanduLat = 27.7172;
  static const double _defaultKathmanduLng = 85.3240;

  double _zoomLevel = 14.0;
  double? _centerLat;
  double? _centerLng;
  Offset _panOffset = Offset.zero;
  MapStyle _currentMapStyle = MapStyle.topographic;
  Experience? _selectedExperience;

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final double initialLat = widget.lat ?? (extra?['lat'] as num?)?.toDouble() ?? _defaultKathmanduLat;
    final double initialLng = widget.lng ?? (extra?['lng'] as num?)?.toDouble() ?? _defaultKathmanduLng;

    _centerLat ??= initialLat;
    _centerLng ??= initialLng;

    final experiencesAsync = ref.watch(experiencesProvider(const {}));

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
        child: AsyncValueView<List<Experience>>(
          value: experiencesAsync,
          onRetry: () => ref.refresh(experiencesProvider(const {})),
          error: (err, stack) => _buildMapBody(
            context,
            experiences: const [],
            initialLat: initialLat,
            initialLng: initialLng,
          ),
          data: (experiences) => _buildMapBody(
            context,
            experiences: experiences,
            initialLat: initialLat,
            initialLng: initialLng,
          ),
        ),
      ),
    );
  }

  Widget _buildMapBody(
    BuildContext context, {
    required List<Experience> experiences,
    required double initialLat,
    required double initialLng,
  }) {
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final String experienceTitle = widget.title ?? extra?['title'] as String? ?? (_selectedExperience?.title ?? MapStrings.mapShellTitle);
    final String meetingText = _selectedExperience?.meetingPoint ??
        widget.meetingPoint ??
        (extra?['meetingPoint'] as String?) ??
        MapStrings.defaultMeetingPoint;

    final publishedExperiences = experiences
        .where((e) => e.status == ExperienceStatus.published || experiences.length <= 3)
        .toList();

    return Column(
      children: [
        // Interactive Map Viewport Shell
        Expanded(
          child: Stack(
            children: [
              // Stylized Map Canvas Viewport with Pan Gesture
              GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _panOffset += details.delta;
                  });
                },
                child: Container(
                  width: double.infinity,
                  color: _getBackgroundColorForStyle(_currentMapStyle),
                  child: CustomPaint(
                    painter: _MapStylePainter(mapStyle: _currentMapStyle),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            // Render Pin Markers for Published Experiences
                            ...publishedExperiences.map((exp) {
                              return _buildExperienceMarker(
                                context,
                                experience: exp,
                                size: constraints.biggest,
                              );
                            }),

                            // Render Selected / Center Pin Marker if no experience matched
                            if (publishedExperiences.isEmpty || _selectedExperience == null)
                              _buildDefaultCenterMarker(
                                size: constraints.biggest,
                                title: experienceTitle,
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Map Control Buttons Overlay (Zoom In, Zoom Out, Recenter, Map Style Toggle)
              Positioned(
                right: AppSpacing.lg16,
                top: AppSpacing.lg16,
                child: Column(
                  children: [
                    _buildControlButton(
                      icon: Icons.add,
                      tooltip: 'Zoom In',
                      onPressed: () {
                        setState(() {
                          _zoomLevel = (_zoomLevel + 1.0).clamp(6.0, 24.0);
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm8),
                    _buildControlButton(
                      icon: Icons.remove,
                      tooltip: 'Zoom Out',
                      onPressed: () {
                        setState(() {
                          _zoomLevel = (_zoomLevel - 1.0).clamp(6.0, 24.0);
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm8),
                    _buildControlButton(
                      icon: Icons.my_location,
                      tooltip: MapStrings.recenterMap,
                      onPressed: () {
                        setState(() {
                          _centerLat = initialLat;
                          _centerLng = initialLng;
                          _zoomLevel = 14.0;
                          _panOffset = Offset.zero;
                        });
                        AppToast.show(
                          context,
                          message: MapStrings.recenterKathmandu,
                          variant: AppToastVariant.info,
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm8),
                    _buildControlButton(
                      icon: Icons.layers_outlined,
                      tooltip: 'Map Style Toggle',
                      onPressed: () {
                        setState(() {
                          final nextIndex = (_currentMapStyle.index + 1) % MapStyle.values.length;
                          _currentMapStyle = MapStyle.values[nextIndex];
                        });
                        AppToast.show(
                          context,
                          message: '${MapStrings.styleToggledPrefix} ${_currentMapStyle.label}',
                          variant: AppToastVariant.info,
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Zoom Level & Style Indicator Pill
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.map_outlined, size: 14, color: AppColors.forest),
                      const SizedBox(width: 4),
                      Text(
                        '${_currentMapStyle.label} • ${_zoomLevel.toInt()}x',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Experience Card Preview Overlay (when a pin marker is tapped)
              if (_selectedExperience != null)
                Positioned(
                  left: AppSpacing.lg16,
                  right: AppSpacing.lg16,
                  bottom: AppSpacing.lg16,
                  child: _buildExperienceCardPreview(context, _selectedExperience!),
                ),
            ],
          ),
        ),

        // Text Meeting Point Card Fallback Section
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
              Row(
                children: [
                  const Icon(Icons.place, color: AppColors.forest, size: 24),
                  const SizedBox(width: AppSpacing.sm8),
                  const Expanded(
                    child: Text(
                      MapStrings.meetingPointHeader,
                      style: AppTypography.headingMedium,
                    ),
                  ),
                  Text(
                    '${(_centerLat ?? initialLat).toStringAsFixed(3)}° N, ${(_centerLng ?? initialLng).toStringAsFixed(3)}° E',
                    style: AppTypography.caption.copyWith(color: AppColors.disabledText),
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
                        AppStubSheet.show(
                          context,
                          title: MapStrings.openExternalMaps,
                          featureName: 'Google Maps / Apple Maps Directions (Stage B)',
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
    );
  }

  Widget _buildExperienceMarker(
    BuildContext context, {
    required Experience experience,
    required Size size,
  }) {
    final double expLat = experience.lat ?? _defaultKathmanduLat;
    final double expLng = experience.lng ?? _defaultKathmanduLng;

    final double centerLat = _centerLat ?? _defaultKathmanduLat;
    final double centerLng = _centerLng ?? _defaultKathmanduLng;

    final double dLat = expLat - centerLat;
    final double dLng = expLng - centerLng;

    final double scaleFactor = _zoomLevel * 350.0;
    final double posX = (size.width / 2) + (dLng * scaleFactor) + _panOffset.dx;
    final double posY = (size.height / 2) - (dLat * scaleFactor) + _panOffset.dy;

    final bool isSelected = _selectedExperience?.id == experience.id;

    return Positioned(
      left: posX.clamp(16.0, size.width - 120.0),
      top: posY.clamp(16.0, size.height - 80.0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedExperience = experience;
            _centerLat = expLat;
            _centerLng = expLng;
          });
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.forest : AppColors.deep,
                borderRadius: AppRadii.borderPill,
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.overlay,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on,
                    size: isSelected ? 16 : 14,
                    color: AppColors.ivory,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      experience.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.ivory,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: const BoxDecoration(
                color: AppColors.gold,
                borderRadius: AppRadii.borderSm8,
              ),
              child: Text(
                AppFormatters.formatNpr(experience.pricePaisa),
                style: AppTypography.caption.copyWith(
                  color: AppColors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultCenterMarker({
    required Size size,
    required String title,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.9, end: 1.1),
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
              title,
              style: AppTypography.caption.copyWith(
                color: AppColors.ivory,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceCardPreview(BuildContext context, Experience exp) {
    return Card(
      elevation: 8,
      shadowColor: AppColors.overlay,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.borderMd16),
      color: AppColors.white,
      child: Padding(
        padding: AppSpacing.paddingMd12,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: AppRadii.borderSm8,
                  child: SizedBox(
                    width: 70,
                    height: 70,
                    child: PlanEPhoto(
                      imageUrl: exp.coverImageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exp.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        exp.locationName ?? MapStrings.defaultMeetingPoint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(color: AppColors.disabledText),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: AppColors.gold),
                          const SizedBox(width: 2),
                          Text(
                            exp.ratingAvg.toStringAsFixed(1),
                            style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${exp.ratingCount})',
                            style: AppTypography.caption.copyWith(color: AppColors.disabledText),
                          ),
                          const Spacer(),
                          Text(
                            AppFormatters.formatNpr(exp.pricePaisa),
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.forest,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.disabledText, size: 20),
                  onPressed: () {
                    setState(() {
                      _selectedExperience = null;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md12),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: MapStrings.viewExperience,
                icon: Icons.arrow_forward,
                onPressed: () => context.push('/experience/${exp.id}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
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
      ),
    );
  }

  Color _getBackgroundColorForStyle(MapStyle style) {
    switch (style) {
      case MapStyle.topographic:
        return AppColors.sage;
      case MapStyle.satellite:
        return AppColors.deep;
      case MapStyle.terrain:
        return AppColors.cardBackgroundAlt;
      case MapStyle.standard:
        return AppColors.ivory;
    }
  }
}

class _MapStylePainter extends CustomPainter {
  final MapStyle mapStyle;

  _MapStylePainter({required this.mapStyle});

  @override
  void paint(Canvas canvas, Size size) {
    final Color gridColor = mapStyle == MapStyle.satellite
        ? AppColors.borderSubtle.withValues(alpha: 0.15)
        : AppColors.borderSubtle.withValues(alpha: 0.5);

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;

    const double step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final Color contourColor = mapStyle == MapStyle.satellite
        ? AppColors.ivory.withValues(alpha: 0.15)
        : (mapStyle == MapStyle.terrain
            ? AppColors.gold.withValues(alpha: 0.15)
            : AppColors.forest.withValues(alpha: 0.10));

    final contourPaint = Paint()
      ..color = contourColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path1 = Path();
    path1.moveTo(0, size.height * 0.4);
    path1.cubicTo(
      size.width * 0.25,
      size.height * 0.2,
      size.width * 0.75,
      size.height * 0.6,
      size.width,
      size.height * 0.3,
    );
    canvas.drawPath(path1, contourPaint);

    final path2 = Path();
    path2.moveTo(0, size.height * 0.7);
    path2.cubicTo(
      size.width * 0.35,
      size.height * 0.85,
      size.width * 0.65,
      size.height * 0.5,
      size.width,
      size.height * 0.75,
    );
    canvas.drawPath(path2, contourPaint);
  }

  @override
  bool shouldRepaint(covariant _MapStylePainter oldDelegate) {
    return oldDelegate.mapStyle != mapStyle;
  }
}
