// PL-06 Home Screen
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../l10n/app_localizations.dart';
import '../../models/experience.dart';
import '../../models/promo_banner.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final homeRailsAsync = ref.watch(homeRailsProvider);
    final profileAsync = ref.watch(profileProvider);
    final aiItineraryEnabled = ref.watch(featureFlagProvider('ai_itinerary')) ?? true;
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
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // One continuous photo behind logo, header, motto, heading
                  // and both CTAs — not a plain header band that hands off
                  // to a separate boxed photo below it. This is the same
                  // structural move the NAS reference makes: everything up
                  // to the fade-out sits on one hero image, edge to edge.
                  SizedBox(
                    height: 340,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/images/herosection.jpg',
                          fit: BoxFit.cover,
                          alignment: const Alignment(0, -0.45),
                        ),
                        // Light top wash, just enough for the header row —
                        // the buttons don't need this at all (they're
                        // opaque-filled already) and the heading uses a
                        // text shadow instead of a heavy backdrop, so the
                        // photo itself stays visible rather than getting
                        // washed out under a dark overlay.
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x66000000), Colors.transparent],
                              stops: [0.0, 0.22],
                            ),
                          ),
                        ),
                        // One continuous, light gradient fading into the
                        // page background at the bottom — no separate
                        // overlaid layer with its own stop range, which
                        // is what left a visible seam last time.
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Color(0x40000000),
                                AppColors.ivory,
                              ],
                              stops: [0.74, 0.88, 1.0],
                            ),
                          ),
                        ),
                        SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header Row — Logo, Location, Notifications & Points
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                          const SizedBox(height: 4),
                                          GestureDetector(
                                            onTap: ref.watch(homeLocationLoadingProvider)
                                                ? null
                                                : () => _useCurrentLocation(context, ref),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                ref.watch(homeLocationLoadingProvider)
                                                    ? const SizedBox(
                                                        width: 14,
                                                        height: 14,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          valueColor: AlwaysStoppedAnimation<Color>(
                                                            AppColors.white,
                                                          ),
                                                        ),
                                                      )
                                                    : const Icon(
                                                        Icons.my_location,
                                                        size: 16,
                                                        color: AppColors.white,
                                                      ),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    ref.watch(homeLocationLabelProvider),
                                                    overflow: TextOverflow.ellipsis,
                                                    style: AppTypography.bodyMedium.copyWith(
                                                      fontSize: 13,
                                                      color: AppColors.white,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    _NotificationBell(
                                      unreadCount:
                                          ref.watch(unreadNotificationCountProvider).value ?? 0,
                                      onTap: () => context.push('/notifications'),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      // Fixed height matching
                                      // _NotificationBell's 48px touch
                                      // target exactly — before this, the
                                      // pill's own vertical padding gave it
                                      // a shorter natural height than the
                                      // circular bell beside it.
                                      height: AppTouchTarget.minSize,
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: AppColors.forest,
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const CircleAvatar(
                                            radius: 12,
                                            backgroundColor: AppColors.white,
                                            child: Icon(
                                              Icons.local_activity,
                                              size: 14,
                                              color: AppColors.gold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${profileAsync.value?.points ?? 0} pts',
                                            style: const TextStyle(
                                              color: AppColors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Trek • Discover • Belong',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.4,
                                    color: AppColors.gold,
                                  ),
                                ),
                                // Fixed gap, not a Spacer — a Spacer
                                // stretches to whatever room the hero's
                                // height happens to leave, which is exactly
                                // what made this gap balloon whenever the
                                // hero got taller. A fixed value stays the
                                // same regardless.
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.gold,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'FEATURED',
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Discover\nNepal Himalayas',
                                  style: TextStyle(
                                    fontFamily: 'serif',
                                    color: AppColors.white,
                                    fontSize: 30,
                                    height: 1.05,
                                    shadows: [
                                      Shadow(color: Color(0x99000000), blurRadius: 10, offset: Offset(0, 2)),
                                    ],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                // Equal-width, equal-height pair — a Row of
                                // two Expanded buttons, not a Wrap of
                                // intrinsically-sized ones. Wrap let the two
                                // buttons size independently and sit
                                // unevenly; this locks them to one shared
                                // baseline and width, the way the reference
                                // pairs its two CTAs.
                                Row(
                                  children: [
                                    Expanded(
                                      child: AppButton(
                                        label: 'Search Treks',
                                        minHeight: 46,
                                        onPressed: () => context.push(
                                          Uri(
                                            path: '/search',
                                            queryParameters: const {
                                              'query': 'Trekking in Nepal',
                                            },
                                          ).toString(),
                                        ),
                                      ),
                                    ),
                                    // Remote kill switch (feature_flags.ai_itinerary)
                                    // — pulled from home entirely when the LLM
                                    // provider behind it is down, not just
                                    // disabled, so it doesn't invite a tap that
                                    // only leads to an error screen.
                                    if (aiItineraryEnabled) ...[
                                      const SizedBox(width: 10),
                                      // Lower-commitment path next to the hard
                                      // "book something" CTA — a guided quiz,
                                      // not a purchase decision.
                                      Expanded(
                                        child: AppButton.secondary(
                                          label: 'Plan with AI',
                                          icon: Icons.auto_awesome,
                                          minHeight: 46,
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
                            'Check back soon for new curated Nepal adventures.',
                      ),
                    ),
                    data: (railsMap) {
                      return Column(
                        children: [
                          if (railsMap['recommended']?.isNotEmpty ?? false) ...[
                            ContentRail(
                              height: 276,
                              title: l10n.recommendedForYou,
                              subtitle:
                                  'Handpicked experiences based on popular journeys',
                              actionLabel: l10n.seeAll,
                              onActionTap: () =>
                                  context.push('/collection/recommended'),
                              items: railsMap['recommended']!
                                  .map(
                                    (exp) => _buildExperienceCard(context, exp),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 24),
                          ],
                          if (railsMap['trending']?.isNotEmpty ?? false) ...[
                            ContentRail(
                              height: 276,
                              title: l10n.trendingNow,
                              subtitle:
                                  'Most booked trips this season in Nepal',
                              actionLabel: l10n.seeAll,
                              onActionTap: () =>
                                  context.push('/collection/trending'),
                              items: railsMap['trending']!
                                  .map(
                                    (exp) => _buildExperienceCard(context, exp),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 24),
                          ],
                          if (railsMap['homestays']?.isNotEmpty ?? false) ...[
                            ContentRail(
                              height: 276,
                              title: l10n.authenticHomestays,
                              subtitle: 'Immerse in local village hospitality',
                              actionLabel: l10n.seeAll,
                              onActionTap: () =>
                                  context.push('/collection/homestays'),
                              items: railsMap['homestays']!
                                  .map(
                                    (exp) => _buildExperienceCard(context, exp),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 24),
                          ],
                          if (railsMap['community']?.isNotEmpty ?? false) ...[
                            ContentRail(
                              height: 276,
                              title: l10n.communityLedTours,
                              subtitle:
                                  'Direct impact travel supporting local communities',
                              actionLabel: l10n.seeAll,
                              onActionTap: () =>
                                  context.push('/collection/community'),
                              items: railsMap['community']!
                                  .map(
                                    (exp) => _buildExperienceCard(context, exp),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 24),
                          ],
                          if (railsMap['adventure-together']?.isNotEmpty ??
                              false) ...[
                            ContentRail(
                              height: 276,
                              title: 'Adventure Together',
                              subtitle:
                                  'Made for couples, friends, families, and groups',
                              actionLabel: l10n.seeAll,
                              onActionTap: () => context.push(
                                '/collection/adventure-together',
                              ),
                              items: railsMap['adventure-together']!
                                  .map(
                                    (exp) => _buildExperienceCard(context, exp),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 24),
                          ],
                          if (railsMap['mind-soul']?.isNotEmpty ?? false) ...[
                            ContentRail(
                              height: 276,
                              title: 'Mind & Soul',
                              subtitle:
                                  'Wellness, reflection, nature, and deep relaxation',
                              actionLabel: l10n.seeAll,
                              onActionTap: () =>
                                  context.push('/collection/mind-soul'),
                              items: railsMap['mind-soul']!
                                  .map(
                                    (exp) => _buildExperienceCard(context, exp),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 24),
                          ],
                          if (railsMap['give-back']?.isNotEmpty ?? false) ...[
                            ContentRail(
                              height: 276,
                              title: 'Give Back',
                              subtitle:
                                  'Community, conservation, and positive local impact',
                              actionLabel: l10n.seeAll,
                              onActionTap: () =>
                                  context.push('/collection/give-back'),
                              items: railsMap['give-back']!
                                  .map(
                                    (exp) => _buildExperienceCard(context, exp),
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

  Widget _buildExperienceCard(BuildContext context, Experience exp) {
    return ExperienceCard(
      title: exp.title,
      location: _shortLocation(exp.locationName),
      rating: exp.ratingAvg,
      reviewCount: exp.ratingCount,
      priceText: AppFormatters.formatNpr(exp.pricePaisa),
      imageUrl: exp.coverImageUrl,
      categoryTag: exp.difficulty.name.toUpperCase(),
      onTap: () => context.push('/experience/${exp.id}'),
      variant: ExperienceCardVariant.poster,
      width: 148.0,
    );
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
    final granted = permission == LocationPermission.always ||
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
                  child: Icon(Icons.notifications_outlined, size: 20, color: AppColors.forest),
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
                  decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
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
            BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 4)),
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
                      style: const TextStyle(fontSize: 12, color: AppColors.sage),
                    ),
                  ],
                ],
              ),
            ),
            if (ctaLabel != null && ctaLabel.isNotEmpty && ctaRoute != null) ...[
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
