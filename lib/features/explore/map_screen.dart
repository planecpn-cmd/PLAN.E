// RM-08 Map View
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/format.dart';
import '../../core/native_intents.dart';
import '../../models/experience.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'map_strings.dart';

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
  static const double _initialZoom = 14.0;

  final MapController _mapController = MapController();
  double _currentZoom = _initialZoom;
  double? _centerLat;
  double? _centerLng;
  Experience? _selectedExperience;
  LatLng? _myLocation;
  bool _locatingMe = false;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _goToMyLocation() async {
    setState(() => _locatingMe = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        return;
      }
      if (permission == LocationPermission.denied) {
        if (mounted) {
          AppToast.show(
            context,
            message: 'Location permission denied',
            variant: AppToastVariant.error,
          );
        }
        return;
      }

      Position? position = await Geolocator.getLastKnownPosition();
      position ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      final here = LatLng(position.latitude, position.longitude);
      _mapController.move(here, 15);
      setState(() {
        _myLocation = here;
        _centerLat = here.latitude;
        _centerLng = here.longitude;
      });
    } catch (_) {
      if (mounted) {
        AppToast.show(
          context,
          message: 'Could not detect your location',
          variant: AppToastVariant.error,
        );
      }
    } finally {
      if (mounted) setState(() => _locatingMe = false);
    }
  }

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
        // Interactive Map Viewport
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(initialLat, initialLng),
                  initialZoom: _initialZoom,
                  minZoom: 4,
                  maxZoom: 18,
                  onTap: (_, __) => setState(() => _selectedExperience = null),
                  onMapEvent: (event) {
                    final zoom = event.camera.zoom;
                    if (zoom != _currentZoom) {
                      setState(() => _currentZoom = zoom);
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.plane.plan_e',
                    maxZoom: 19,
                  ),
                  MarkerLayer(
                    markers: [
                      if (_myLocation != null)
                        Marker(
                          point: _myLocation!,
                          width: 22,
                          height: 22,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.forest,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppColors.overlay,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (publishedExperiences.isEmpty || _selectedExperience == null)
                        Marker(
                          point: LatLng(initialLat, initialLng),
                          width: 200,
                          height: 96,
                          alignment: Alignment.bottomCenter,
                          child: _buildDefaultCenterMarker(title: experienceTitle),
                        ),
                      ...publishedExperiences.map((exp) {
                        final double expLat = exp.lat ?? _defaultKathmanduLat;
                        final double expLng = exp.lng ?? _defaultKathmanduLng;
                        return Marker(
                          point: LatLng(expLat, expLng),
                          width: 160,
                          height: 72,
                          alignment: Alignment.bottomCenter,
                          child: _buildExperienceMarker(context, experience: exp),
                        );
                      }),
                    ],
                  ),
                  const RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution('OpenStreetMap contributors'),
                    ],
                  ),
                ],
              ),

              // Map Control Buttons Overlay (Zoom In, Zoom Out, Recenter)
              Positioned(
                right: AppSpacing.lg16,
                top: AppSpacing.lg16,
                child: Column(
                  children: [
                    _buildControlButton(
                      icon: Icons.add,
                      tooltip: 'Zoom In',
                      onPressed: () {
                        final camera = _mapController.camera;
                        _mapController.move(
                          camera.center,
                          (camera.zoom + 1.0).clamp(4.0, 18.0),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm8),
                    _buildControlButton(
                      icon: Icons.remove,
                      tooltip: 'Zoom Out',
                      onPressed: () {
                        final camera = _mapController.camera;
                        _mapController.move(
                          camera.center,
                          (camera.zoom - 1.0).clamp(4.0, 18.0),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm8),
                    _buildControlButton(
                      icon: _locatingMe ? Icons.gps_not_fixed : Icons.my_location,
                      tooltip: 'My Location',
                      onPressed: _locatingMe ? () {} : _goToMyLocation,
                    ),
                    const SizedBox(height: AppSpacing.sm8),
                    _buildControlButton(
                      icon: Icons.place_outlined,
                      tooltip: MapStrings.recenterMap,
                      onPressed: () {
                        _mapController.move(LatLng(initialLat, initialLng), _initialZoom);
                        setState(() {
                          _centerLat = initialLat;
                          _centerLng = initialLng;
                        });
                        AppToast.show(
                          context,
                          message: MapStrings.recenterKathmandu,
                          variant: AppToastVariant.info,
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Zoom Level Indicator Pill
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
                        '${_currentZoom.toInt()}x',
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
                        NativeIntents.openDirections(
                          lat: _centerLat ?? initialLat,
                          lng: _centerLng ?? initialLng,
                          label: meetingText,
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
  }) {
    final bool isSelected = _selectedExperience?.id == experience.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedExperience = experience;
          _centerLat = experience.lat ?? _defaultKathmanduLat;
          _centerLng = experience.lng ?? _defaultKathmanduLng;
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
    );
  }

  Widget _buildDefaultCenterMarker({required String title}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: AppColors.ivory,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
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
}
