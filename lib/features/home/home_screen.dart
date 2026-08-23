// PL-06 Home Screen
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/experience_presentation.dart';
import '../../l10n/app_localizations.dart';
import '../../models/experience.dart';
import '../../models/experience_family.dart';
import '../../models/promo_banner.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../experience/experience_strings.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final homeRailsAsync = ref.watch(homeRailsProvider);
    final savedIds = ref
        .watch(savedExperiencesProvider)
        .valueOrNull
        ?.map((experience) => experience.id)
        .toSet();
    final taxonomy = ref.watch(experienceTaxonomyProvider).valueOrNull;
    final profileAsync = ref.watch(profileProvider);
    final aiItineraryEnabled =
        ref.watch(featureFlagProvider('ai_itinerary')) ?? true;
    // Side-effect only — triggers the silent location auto-fetch once per
    // app session; the AsyncValue<void> result itself is never read.
    ref.watch(_homeLocationAutoFetchProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Status bar icons in dark mode default to black, invisible against
      // the hero's dark top wash. White icons read against it instead —
      // and statusBarColor must be explicit transparent, or Android draws
      // its own translucent scrim there that doesn't match the photo.
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: PlanEBackground(
          safeArea: false,
          // top: false — the hero photo goes edge-to-edge behind the status
          // bar; the *inner* SafeArea further down (wrapping just the header
          // row) is what protects that text from the status bar instead. With
          // this SafeArea also reserving top space, the hero was getting
          // pushed down by a statusbar-height strip of plain background
          // before it even started — that was the "doesn't blend" gap.
          child: SafeArea(
            top: false,
            bottom: false,
            child: RefreshIndicator(
              color: AppColors.forest,
              onRefresh: () async {
                ref.invalidate(homeRailsProvider);
                ref.invalidate(categoriesProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HomeHero(
                      points: profileAsync.value?.points ?? 0,
                      aiItineraryEnabled: aiItineraryEnabled,
                    ),
                    const SizedBox(height: 10),
                    const _PromoBanner(),

                    // Content Rails wrapped in AsyncValueView
                    AsyncValueView<Map<String, List<Experience>>>(
                      value: homeRailsAsync,
                      onRetry: () => ref.refresh(homeRailsProvider),
                      isEmpty: (data) =>
                          data.values.every((list) => list.isEmpty),
                      emptyView: const Padding(
                        padding: EdgeInsets.all(24),
                        child: EmptyStateView(
                          title: 'No Experiences Available',
                          description:
                              'Check back soon for new ways to experience Nepal.',
                        ),
                      ),
                      data: (railsMap) {
                        return Column(
                          children: [
                            if (railsMap['recommended']?.isNotEmpty ??
                                false) ...[
                              ContentRail(
                                height: 324,
                                title: l10n.recommendedForYou,
                                subtitle:
                                    'Handpicked experiences based on popular journeys',
                                actionLabel: l10n.seeAll,
                                onActionTap: () =>
                                    context.push('/collection/recommended'),
                                items: railsMap['recommended']!
                                    .map(
                                      (exp) => _buildExperienceCard(
                                        context,
                                        ref,
                                        exp,
                                        taxonomy,
                                        savedIds ?? const {},
                                      ),
                                    )
                                    .toList(),
                              ),
                              const SizedBox(height: 24),
                            ],
                            if (railsMap['trending']?.isNotEmpty ?? false) ...[
                              ContentRail(
                                height: 324,
                                title: l10n.trendingNow,
                                subtitle:
                                    'Experiences people are loving this week',
                                actionLabel: l10n.seeAll,
                                onActionTap: () =>
                                    context.push('/collection/trending'),
                                items: railsMap['trending']!
                                    .map(
                                      (exp) => _buildExperienceCard(
                                        context,
                                        ref,
                                        exp,
                                        taxonomy,
                                        savedIds ?? const {},
                                      ),
                                    )
                                    .toList(),
                              ),
                              const SizedBox(height: 24),
                            ],
                            for (final spec in _homeFamilyRails)
                              if (railsMap[spec.slug]?.isNotEmpty ?? false) ...[
                                ContentRail(
                                  height: 324,
                                  title: spec.title,
                                  subtitle: spec.subtitle,
                                  actionLabel: l10n.seeAll,
                                  onActionTap: () =>
                                      context.push('/collection/${spec.slug}'),
                                  items: railsMap[spec.slug]!
                                      .map(
                                        (exp) => _buildExperienceCard(
                                          context,
                                          ref,
                                          exp,
                                          taxonomy,
                                          savedIds ?? const {},
                                        ),
                                      )
                                      .toList(),
                                ),
                                const SizedBox(height: 24),
                              ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExperienceCard(
    BuildContext context,
    WidgetRef ref,
    Experience exp,
    ExperienceTaxonomy? taxonomy,
    Set<String> savedIds,
  ) {
    final presentation = ExperiencePresentation.from(exp, taxonomy);
    final isSaved = savedIds.contains(exp.id);
    return ExperienceCard(
      title: exp.title,
      location: _shortLocation(exp.locationName),
      rating: exp.ratingAvg,
      reviewCount: exp.ratingCount,
      priceText: AppFormatters.formatNpr(exp.pricePaisa),
      imageUrl: exp.coverImageUrl,
      typeLabel: presentation.typeLabel,
      detailText: presentation.detailText,
      isSaved: isSaved,
      onTap: () => context.push('/experience/${exp.id}'),
      onBookmarkTap: () => _toggleSaved(context, ref, exp.id, isSaved),
      variant: ExperienceCardVariant.poster,
      width: 148.0,
    );
  }

  Future<void> _toggleSaved(
    BuildContext context,
    WidgetRef ref,
    String experienceId,
    bool isSaved,
  ) async {
    if (ref.read(supabaseClientProvider).auth.currentUser == null) {
      ref
          .read(deferredActionProvider.notifier)
          .setPending(
            DeferredAction(
              screenId: 'PL-09',
              entityId: experienceId,
              action: 'save',
            ),
          );
      if (context.mounted) context.push('/auth/required');
      return;
    }

    try {
      await ref.read(savedRepositoryProvider).toggleSave(experienceId, isSaved);
      ref.invalidate(savedExperiencesProvider);
      if (context.mounted) {
        AppToast.show(
          context,
          message: isSaved
              ? ExperienceStrings.removedFromWishlist
              : ExperienceStrings.savedToWishlist,
          variant: AppToastVariant.success,
        );
      }
    } catch (error) {
      if (context.mounted) {
        AppToast.show(
          context,
          message: error.toString(),
          variant: AppToastVariant.error,
        );
      }
    }
  }

  /// "Lo Manthang / Mustang" → "Lo Manthang" — one or two words instead of
  /// the full descriptive location string, so a scanning eye takes in the
  /// rail faster. Splits on the same punctuation location_name already
  /// uses to separate a place from its region.
  String _shortLocation(String? locationName) {
    if (locationName == null || locationName.isEmpty) return 'Nepal';
    final firstSegment = locationName.split(RegExp(r'[/,\-]')).first.trim();
    final words = firstSegment.split(' ');
    return words.length > 2 ? words.take(2).join(' ') : firstSegment;
  }
}

class _HomeFamilyRailSpec {
  final String slug;
  final String title;
  final String subtitle;

  const _HomeFamilyRailSpec(this.slug, this.title, this.subtitle);
}

const _homeFamilyRails = [
  _HomeFamilyRailSpec(
    'live-like-a-local',
    'Live Like a Local',
    'Food, homes, villages, culture, and crafts',
  ),
  _HomeFamilyRailSpec(
    'mind-soul',
    'Mind & Soul',
    'Wellness, reflection, healing, and creativity',
  ),
  _HomeFamilyRailSpec(
    'meet-people',
    'Meet People',
    'Activities, events, and communities to join',
  ),
  _HomeFamilyRailSpec(
    'give-back',
    'Give Back',
    'Community, conservation, and meaningful impact',
  ),
  _HomeFamilyRailSpec(
    'trips-tours',
    'Trips & Tours',
    'Day trips, guided tours, packages, and sightseeing',
  ),
  _HomeFamilyRailSpec(
    'adventure-together',
    'Adventure Together',
    'Outdoor adventures made for sharing',
  ),
];

class _HomeHero extends ConsumerWidget {
  final int points;
  final bool aiItineraryEnabled;

  const _HomeHero({required this.points, required this.aiItineraryEnabled});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locating = ref.watch(homeLocationLoadingProvider);
    return SizedBox(
      height: 430,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Semantics(
            image: true,
            label:
                'Pottery, local food, wellness, and a countryside walk in Nepal',
            child: Image.asset(
              'assets/images/home_experiences_hero.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xA6000000),
                  Color(0x30000000),
                  Color(0xB800160F),
                  AppColors.ivory,
                ],
                stops: [0, 0.26, 0.78, 1],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const PlanELogo(
                              fontSize: 26,
                              centered: false,
                              color: AppColors.white,
                            ),
                            Semantics(
                              button: true,
                              label: locating
                                  ? 'Finding current location'
                                  : 'Use current location',
                              child: InkWell(
                                onTap: locating
                                    ? null
                                    : () => _useCurrentLocation(context, ref),
                                borderRadius: AppRadii.borderSm8,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                    horizontal: 2,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (locating)
                                        const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.white,
                                          ),
                                        )
                                      else
                                        const Icon(
                                          Icons.my_location,
                                          size: 16,
                                          color: AppColors.white,
                                        ),
                                      const SizedBox(width: 5),
                                      Flexible(
                                        child: Text(
                                          ref.watch(homeLocationLabelProvider),
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _NotificationBell(
                        unreadCount:
                            ref.watch(unreadNotificationCountProvider).value ??
                            0,
                        onTap: () => context.push('/notifications'),
                      ),
                      const SizedBox(width: 8),
                      Semantics(
                        label: '$points PLAN E points',
                        child: Container(
                          height: AppTouchTarget.minSize,
                          padding: const EdgeInsets.symmetric(horizontal: 13),
                          decoration: const BoxDecoration(
                            color: AppColors.forest,
                            borderRadius: AppRadii.borderPill,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_activity_outlined,
                                size: 17,
                                color: AppColors.gold,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$points pts',
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Text(
                    'Discover Nepal\nyour way.',
                    style: TextStyle(
                      fontFamily: 'serif',
                      color: AppColors.white,
                      fontSize: 31,
                      height: 1.02,
                      fontWeight: FontWeight.w700,
                      shadows: [
                        Shadow(
                          color: Color(0x99000000),
                          blurRadius: 12,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'From local tables to mountain trails, find experiences worth remembering.',
                    maxLines: 2,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      shadows: [
                        Shadow(color: Color(0x99000000), blurRadius: 8),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Semantics(
                    button: true,
                    label: 'Search experiences, places, or activities',
                    child: Material(
                      color: AppColors.white,
                      borderRadius: AppRadii.borderPill,
                      child: InkWell(
                        onTap: () => context.push('/search'),
                        borderRadius: AppRadii.borderPill,
                        child: const SizedBox(
                          height: AppTouchTarget.minSize,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Icon(Icons.search, color: AppColors.forest),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'What do you want to do?',
                                    style: TextStyle(
                                      color: AppColors.disabledText,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Explore Nepal',
                          minHeight: 46,
                          fontSize: 13,
                          onPressed: () => context.push('/explore'),
                        ),
                      ),
                      if (aiItineraryEnabled) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppButton.secondary(
                            label: 'Plan with AI',
                            icon: Icons.auto_awesome,
                            minHeight: 46,
                            fontSize: 13,
                            onPressed: () => context.push('/ai-planner'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One reverse-geocode call to a "City, Country" label, shared by the
/// explicit tap-to-locate flow and the silent auto-fetch on home load.
Future<String?> _labelFromPosition(Position position) async {
  final placemarks = await placemarkFromCoordinates(
    position.latitude,
    position.longitude,
  );
  final place = placemarks.isNotEmpty ? placemarks.first : null;
  final city = (place?.locality?.isNotEmpty ?? false)
      ? place!.locality!
      : ((place?.subAdministrativeArea?.isNotEmpty ?? false)
            ? place!.subAdministrativeArea!
            : null);
  final label = [
    city,
    place?.country,
  ].whereType<String>().where((s) => s.isNotEmpty).join(', ');
  return label.isNotEmpty ? label : null;
}

/// Fires once per app session (a plain, non-autoDispose FutureProvider
/// caches its result) to silently update the location label if permission
/// was already granted in a prior session — so returning users see their
/// real city without tapping anything. Never prompts: a screen the user
/// just opened is the wrong moment to surprise them with a permission
/// dialog, so this only proceeds when permission is already granted.
final _homeLocationAutoFetchProvider = FutureProvider<void>((ref) async {
  try {
    final permission = await Geolocator.checkPermission();
    final granted =
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
    if (!granted) return;
    if (!await Geolocator.isLocationServiceEnabled()) return;

    Position? position = await Geolocator.getLastKnownPosition();
    position ??= await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 8),
      ),
    );
    final label = await _labelFromPosition(position);
    if (label != null) {
      ref.read(homeLocationLabelProvider.notifier).state = label;
    }
  } catch (_) {
    // Silent — passive background refresh, not a user-initiated action.
  }
});

Future<void> _useCurrentLocation(BuildContext context, WidgetRef ref) async {
  ref.read(homeLocationLoadingProvider.notifier).state = true;
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Launch Android's own "turn on location" system screen instead of
      // just telling the user to go find it themselves.
      await Geolocator.openLocationSettings();
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Triggers the native Android permission dialog.
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      // Permanently denied — Android won't show the dialog again, so the
      // only way back in is the app's own system permission settings screen.
      await Geolocator.openAppSettings();
      return;
    }
    if (permission == LocationPermission.denied) {
      if (context.mounted) {
        AppToast.show(
          context,
          message: 'Location permission denied',
          variant: AppToastVariant.error,
        );
      }
      return;
    }

    // A cached last-known fix is near-instant and good enough for a city
    // label — only wait on a fresh GPS fix (which can take a while,
    // especially indoors) when there's no cached one at all.
    Position? position = await Geolocator.getLastKnownPosition();
    position ??= await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 8),
      ),
    );
    final label = await _labelFromPosition(position);

    ref.read(homeLocationLabelProvider.notifier).state =
        label ?? 'Current Location';
  } catch (_) {
    if (context.mounted) {
      AppToast.show(
        context,
        message: 'Could not detect your location',
        variant: AppToastVariant.error,
      );
    }
  } finally {
    ref.read(homeLocationLoadingProvider.notifier).state = false;
  }
}

class _NotificationBell extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;

  const _NotificationBell({required this.unreadCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: unreadCount > 0
          ? 'Notifications, $unreadCount unread'
          : 'Notifications',
      child: SizedBox(
        width: AppTouchTarget.minSize,
        height: AppTouchTarget.minSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Material(
              color: AppColors.sage,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: const SizedBox.expand(
                  child: Icon(
                    Icons.notifications_outlined,
                    size: 20,
                    color: AppColors.forest,
                  ),
                ),
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Reads `remote_content.promo_banner` — a slot nothing has configured yet,
/// so this renders nothing by default (fail-open: no content = no visible
/// change from before this existed). Expected payload shape:
/// `{"headline": "...", "subtitle": "...", "cta_label": "...", "cta_route": "..."}`
/// — subtitle/cta are both optional; a malformed payload also renders
/// nothing rather than crashing the home screen.
class _PromoBanner extends ConsumerWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final raw = ref.watch(remoteContentProvider('promo_banner'));
    final content = PromoBannerContent.tryParse(raw);
    if (content == null) return const SizedBox.shrink();

    final headline = content.headline;
    final subtitle = content.subtitle;
    final ctaLabel = content.ctaLabel;
    final ctaRoute = content.ctaRoute;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.forest, AppColors.deep],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headline,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.sage,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (ctaLabel != null &&
                ctaLabel.isNotEmpty &&
                ctaRoute != null) ...[
              const SizedBox(width: 12),
              AppButton.secondary(
                label: ctaLabel,
                minHeight: 38,
                onPressed: () => context.push(ctaRoute),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
