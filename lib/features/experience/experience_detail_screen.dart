// PL-09 Experience Details
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/format.dart';
import '../../models/experience.dart';
import '../../models/experience_departure.dart';
import '../../models/itinerary_item.dart';
import '../../models/review.dart';
import '../../models/profile.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

import 'experience_detail_providers.dart';
import 'experience_strings.dart';

class ExperienceDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const ExperienceDetailScreen({super.key, required this.id});

  @override
  ConsumerState<ExperienceDetailScreen> createState() => _ExperienceDetailScreenState();
}

class _ExperienceDetailScreenState extends ConsumerState<ExperienceDetailScreen> {
  bool _isDescriptionExpanded = false;
  ExperienceDeparture? _selectedDeparture;
  bool _optimisticIsSaved = false;
  bool _hasLocalSaveState = false;

  @override
  Widget build(BuildContext context) {
    final experienceAsync = ref.watch(experienceDetailProvider(widget.id));
    final serverIsSavedAsync = ref.watch(isSavedExperienceProvider(widget.id));

    final bool isSaved = _hasLocalSaveState
        ? _optimisticIsSaved
        : (serverIsSavedAsync.asData?.value ?? false);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: AsyncValueView<Experience?>(
        value: experienceAsync,
        onRetry: () => ref.refresh(experienceDetailProvider(widget.id)),
        isEmpty: (data) => data == null,
        emptyView: const ErrorStateView(
          title: 'Experience Not Found',
          message: 'The requested experience could not be loaded.',
        ),
        data: (experience) {
          if (experience == null) {
            return const ErrorStateView(
              title: 'Experience Not Found',
              message: 'The requested experience could not be loaded.',
            );
          }
          return _buildDetailContent(context, experience, isSaved);
        },
      ),
      bottomNavigationBar: experienceAsync.asData?.value != null
          ? PriceBottomBar(
              priceText: AppFormatters.formatNpr(
                _selectedDeparture?.priceOverridePaisa ?? experienceAsync.asData!.value!.pricePaisa,
              ),
              unitText: ExperienceStrings.perPersonUnit,
              buttonLabel: ExperienceStrings.joinButtonLabel,
              onPressed: () {
                context.push('/booking/${widget.id}');
              },
            )
          : null,
    );
  }

  Widget _buildDetailContent(BuildContext context, Experience experience, bool isSaved) {
    final departuresAsync = ref.watch(experienceDeparturesProvider(experience.id));
    final itineraryAsync = ref.watch(experienceItineraryProvider(experience.id));
    final reviewsAsync = ref.watch(experienceReviewsProvider(experience.id));
    final hostAsync = experience.hostId != null
        ? ref.watch(hostProfileProvider(experience.hostId!))
        : null;

    final departures = departuresAsync.asData?.value ?? [];
    final itinerary = itineraryAsync.asData?.value ?? [];
    final reviews = reviewsAsync.asData?.value ?? [];
    final hostProfile = hostAsync?.asData?.value;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: cover
          _buildCoverSection(context, experience, isSaved),

          // Section 2: spots-left
          _buildSpotsLeftSection(departures),

          Padding(
            padding: AppSpacing.paddingLg16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section 3: title/location/rating/date
                _buildTitleLocationRatingDateSection(experience, departures),
                const SizedBox(height: AppSpacing.xxl24),

                // Section 4: duration/difficulty/altitude/group size
                _buildQuickStatsSection(experience),
                const SizedBox(height: AppSpacing.xxl24),

                // Section 5: overview
                _buildOverviewSection(experience, itinerary),
                const SizedBox(height: AppSpacing.xxl24),

                // Section 6: price
                _buildPriceSection(experience),
                const SizedBox(height: AppSpacing.xxl24),

                // Section 7: included
                _buildIncludedSection(experience),
                const SizedBox(height: AppSpacing.xxl24),

                // Section 8: bring list
                _buildBringListSection(experience),
                const SizedBox(height: AppSpacing.xxl24),

                // Section 9: meeting point + map
                _buildMeetingPointMapSection(context, experience),
                const SizedBox(height: AppSpacing.xxl24),

                // Section 10: participants
                _buildParticipantsSection(experience),
                const SizedBox(height: AppSpacing.xxl24),

                // Section 11: things to know
                _buildThingsToKnowSection(experience),
                const SizedBox(height: AppSpacing.xxl24),

                // Section 12: reviews
                _buildReviewsSection(experience, reviews),
                const SizedBox(height: AppSpacing.xxl24),

                // Section 13: organizer
                _buildOrganizerSection(context, hostProfile),
                const SizedBox(height: AppSpacing.huge40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Section 1: cover
  Widget _buildCoverSection(BuildContext context, Experience experience, bool isSaved) {
    final List<String> images = [
      experience.coverImageUrl,
      ...experience.gallery,
    ].where((img) => img.isNotEmpty).toList();

    return Stack(
      children: [
        SizedBox(
          height: 300.0,
          width: double.infinity,
          child: images.isNotEmpty
              ? PageView.builder(
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return CachedNetworkImage(
                      imageUrl: images[index],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.skeletonBase,
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.forest),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.sage,
                        child: const Center(
                          child: Icon(Icons.terrain, size: 64, color: AppColors.forest),
                        ),
                      ),
                    );
                  },
                )
              : Container(
                  color: AppColors.sage,
                  child: const Center(
                    child: Icon(Icons.landscape, size: 64, color: AppColors.forest),
                  ),
                ),
        ),

        // Gradient overlay for back/actions readability
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [
                  AppColors.black.withValues(alpha: 0.6),
                  AppColors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Action icons bar
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg16,
              vertical: AppSpacing.sm8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCircleIconButton(
                  icon: Icons.arrow_back,
                  onPressed: () => context.pop(),
                ),
                Row(
                  children: [
                    _buildCircleIconButton(
                      icon: Icons.share_outlined,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: experience.title));
                        AppToast.show(
                          context,
                          message: ExperienceStrings.linkCopied,
                          variant: AppToastVariant.info,
                        );
                      },
                    ),
                    const SizedBox(width: AppSpacing.sm8),
                    _buildCircleIconButton(
                      icon: isSaved ? Icons.favorite : Icons.favorite_border,
                      iconColor: isSaved ? AppColors.error : AppColors.deep,
                      onPressed: () => _toggleOptimisticSave(experience.id, isSaved),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCircleIconButton({
    required IconData icon,
    Color iconColor = AppColors.deep,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: AppTouchTarget.minSize,
      height: AppTouchTarget.minSize,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: AppColors.overlay,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: iconColor, size: 20),
        onPressed: onPressed,
      ),
    );
  }

  Future<void> _toggleOptimisticSave(String experienceId, bool currentlySaved) async {
    final client = ref.read(supabaseClientProvider);
    final user = client.auth.currentUser;

    if (user == null) {
      ref.read(deferredActionProvider.notifier).setPending(
        DeferredAction(screenId: 'PL-09', entityId: experienceId, action: 'save'),
      );
      AppToast.show(
        context,
        message: ExperienceStrings.loginRequiredToSave,
        variant: AppToastVariant.info,
      );
      context.push('/auth/required');
      return;
    }

    setState(() {
      _hasLocalSaveState = true;
      _optimisticIsSaved = !currentlySaved;
    });

    try {
      final savedRepo = ref.read(savedRepositoryProvider);
      await savedRepo.toggleSave(experienceId, currentlySaved);
      ref.invalidate(savedExperiencesProvider);
      ref.invalidate(isSavedExperienceProvider(experienceId));

      if (mounted) {
        AppToast.show(
          context,
          message: _optimisticIsSaved
              ? ExperienceStrings.savedToWishlist
              : ExperienceStrings.removedFromWishlist,
          variant: AppToastVariant.success,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _optimisticIsSaved = currentlySaved;
        });
        AppToast.show(
          context,
          message: e.toString(),
          variant: AppToastVariant.error,
        );
      }
    }
  }

  // Section 2: spots-left
  Widget _buildSpotsLeftSection(List<ExperienceDeparture> departures) {
    if (departures.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg16,
          vertical: AppSpacing.sm8,
        ),
        color: AppColors.sage,
        child: Row(
          children: [
            const Icon(Icons.flash_on, size: 16, color: AppColors.forest),
            const SizedBox(width: AppSpacing.sm8),
            Text(
              ExperienceStrings.instantConfirmation,
              style: AppTypography.caption.copyWith(
                color: AppColors.forest,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final upcoming = departures.where((d) => d.spotsLeft > 0).toList();
    if (upcoming.isEmpty) return const SizedBox.shrink();

    final nextDeparture = upcoming.first;
    final bool isLowSpot = nextDeparture.spotsLeft <= 5;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg16,
        vertical: AppSpacing.sm8,
      ),
      color: isLowSpot ? AppColors.warningContainer : AppColors.successContainer,
      child: Row(
        children: [
          Icon(
            isLowSpot ? Icons.local_fire_department : Icons.event_available,
            size: 18,
            color: isLowSpot ? AppColors.warning : AppColors.success,
          ),
          const SizedBox(width: AppSpacing.sm8),
          Expanded(
            child: Text(
              isLowSpot
                  ? '${ExperienceStrings.spotsLeftWarningPrefix}${nextDeparture.spotsLeft}${ExperienceStrings.spotsLeftWarningSuffix}${AppFormatters.formatTripDate(nextDeparture.startDate, pattern: 'd MMM')}'
                  : '${ExperienceStrings.spotsAvailablePrefix}${AppFormatters.formatTripDate(nextDeparture.startDate, pattern: 'd MMM')} • ${nextDeparture.spotsLeft}${ExperienceStrings.spotsAvailableSuffix}',
              style: AppTypography.caption.copyWith(
                color: isLowSpot ? AppColors.warning : AppColors.success,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Section 3: title/location/rating/date
  Widget _buildTitleLocationRatingDateSection(Experience experience, List<ExperienceDeparture> departures) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          experience.title,
          style: AppTypography.headingLarge.copyWith(height: 1.2),
        ),
        const SizedBox(height: AppSpacing.sm8),
        Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 18, color: AppColors.forest),
            const SizedBox(width: AppSpacing.xs4),
            Expanded(
              child: Text(
                experience.locationName ?? 'Nepal',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.forest,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm8),
        RatingStars(
          rating: experience.ratingAvg,
          reviewCount: experience.ratingCount,
          starSize: 16,
        ),
        if (departures.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg16),
          Text(
            'Select Departure Date',
            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm8),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: departures.length,
              separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm8),
              itemBuilder: (context, index) {
                final dep = departures[index];
                final isSelected = _selectedDeparture?.id == dep.id || (index == 0 && _selectedDeparture == null);
                return ChoiceChip(
                  label: Text(
                    '${AppFormatters.formatTripDate(dep.startDate, pattern: 'd MMM')} (${dep.spotsLeft} spots)',
                    style: AppTypography.caption.copyWith(
                      color: isSelected ? AppColors.ivory : AppColors.ink,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.forest,
                  backgroundColor: AppColors.sage,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedDeparture = dep;
                      });
                    }
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  // Section 4: duration/difficulty/altitude/group size
  Widget _buildQuickStatsSection(Experience experience) {
    return Container(
      padding: AppSpacing.paddingMd12,
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundAlt,
        borderRadius: AppRadii.borderMd16,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatTile(
            icon: Icons.schedule,
            label: ExperienceStrings.durationLabel,
            value: AppFormatters.formatDuration(experience.durationHours),
          ),
          _buildStatDivider(),
          _buildStatTile(
            icon: Icons.terrain,
            label: ExperienceStrings.difficultyLabel,
            value: experience.difficulty.name.toUpperCase(),
          ),
          if (experience.maxAltitudeM != null) ...[
            _buildStatDivider(),
            _buildStatTile(
              icon: Icons.filter_hdr,
              label: ExperienceStrings.altitudeLabel,
              value: '${experience.maxAltitudeM} m',
            ),
          ],
          _buildStatDivider(),
          _buildStatTile(
            icon: Icons.people_outline,
            label: ExperienceStrings.groupSizeLabel,
            value: '${experience.groupSizeMin}-${experience.groupSizeMax} max',
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Flexible(
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.forest),
          const SizedBox(height: AppSpacing.xs4),
          Text(
            label,
            style: AppTypography.caption.copyWith(color: AppColors.disabledText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs4),
          Text(
            value,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 32,
      width: 1,
      color: AppColors.borderSubtle,
    );
  }

  // Section 5: overview
  Widget _buildOverviewSection(Experience experience, List<ItineraryItem> itinerary) {
    final String descriptionText = experience.description ?? experience.summary ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: ExperienceStrings.overviewTitle),
        const SizedBox(height: AppSpacing.sm8),
        if (experience.summary != null && experience.summary!.isNotEmpty) ...[
          Text(
            experience.summary!,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.sm8),
        ],
        Text(
          descriptionText,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
          maxLines: _isDescriptionExpanded ? null : 4,
          overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        if (descriptionText.length > 180) ...[
          const SizedBox(height: AppSpacing.xs4),
          GestureDetector(
            onTap: () {
              setState(() {
                _isDescriptionExpanded = !_isDescriptionExpanded;
              });
            },
            child: Text(
              _isDescriptionExpanded ? ExperienceStrings.showLess : ExperienceStrings.readMore,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.forest,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        if (itinerary.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg16),
          Text(
            'Daily Itinerary',
            style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm8),
          ...itinerary.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: const BoxDecoration(
                        color: AppColors.sage,
                        borderRadius: AppRadii.borderSm8,
                      ),
                      child: Text(
                        'Day ${item.dayNumber}',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.forest,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (item.description != null)
                            Text(
                              item.description!,
                              style: AppTypography.caption.copyWith(color: AppColors.disabledText),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }

  // Section 6: price
  Widget _buildPriceSection(Experience experience) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: ExperienceStrings.pricingTitle),
        const SizedBox(height: AppSpacing.sm8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              AppFormatters.formatNpr(experience.pricePaisa),
              style: AppTypography.headingLarge.copyWith(
                color: AppColors.forest,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: AppSpacing.xs4),
            Text(
              ExperienceStrings.perPersonUnit,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.disabledText),
            ),
          ],
        ),
        if (experience.childPricePaisa != null) ...[
          const SizedBox(height: AppSpacing.xs4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                AppFormatters.formatNpr(experience.childPricePaisa!),
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.xs4),
              Text(
                ExperienceStrings.perChildUnit,
                style: AppTypography.caption.copyWith(color: AppColors.disabledText),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.xs4),
        Text(
          ExperienceStrings.taxesIncluded,
          style: AppTypography.caption.copyWith(color: AppColors.disabledText),
        ),
      ],
    );
  }

  // Section 7: included
  Widget _buildIncludedSection(Experience experience) {
    final List<String> includedItems = experience.included.isNotEmpty
        ? experience.included
        : ExperienceStrings.defaultIncluded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: ExperienceStrings.whatsIncludedTitle),
        const SizedBox(height: AppSpacing.sm8),
        ...includedItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
                  const SizedBox(width: AppSpacing.md12),
                  Expanded(
                    child: Text(
                      item,
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  // Section 8: bring list
  Widget _buildBringListSection(Experience experience) {
    final List<String> bringItems = experience.bringList.isNotEmpty
        ? experience.bringList
        : ExperienceStrings.defaultBringList;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: ExperienceStrings.whatsBringTitle),
        const SizedBox(height: AppSpacing.sm8),
        ...bringItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm8),
              child: Row(
                children: [
                  const Icon(Icons.check_box_outlined, color: AppColors.forest, size: 20),
                  const SizedBox(width: AppSpacing.md12),
                  Expanded(
                    child: Text(
                      item,
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  // Section 9: meeting point + map
  Widget _buildMeetingPointMapSection(BuildContext context, Experience experience) {
    final String meetingText = experience.meetingPoint ?? experience.locationName ?? 'Kathmandu, Nepal';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: ExperienceStrings.meetingPointTitle),
        const SizedBox(height: AppSpacing.sm8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.place_outlined, color: AppColors.forest, size: 22),
            const SizedBox(width: AppSpacing.sm8),
            Expanded(
              child: Text(
                meetingText,
                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md12),
        // Map preview card
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.sage,
            borderRadius: AppRadii.borderMd16,
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Stack(
            children: [
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_outlined, size: 40, color: AppColors.forest),
                    SizedBox(height: AppSpacing.xs4),
                    Text(
                      'Interactive Map View',
                      style: TextStyle(color: AppColors.forest, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: AppSpacing.sm8,
                right: AppSpacing.sm8,
                child: AppButton.secondary(
                  label: ExperienceStrings.viewOnMap,
                  icon: Icons.fullscreen,
                  onPressed: () {
                    context.push('/map', extra: {
                      'lat': experience.lat,
                      'lng': experience.lng,
                      'title': experience.title,
                      'meetingPoint': meetingText,
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Section 10: participants
  Widget _buildParticipantsSection(Experience experience) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: ExperienceStrings.participantsTitle),
        const SizedBox(height: AppSpacing.sm8),
        Row(
          children: [
            const Icon(Icons.face_outlined, color: AppColors.forest, size: 20),
            const SizedBox(width: AppSpacing.md12),
            Text(
              '${ExperienceStrings.minAgeLabel}: ${experience.minAge}+ years old',
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm8),
        Row(
          children: [
            const Icon(Icons.groups_outlined, color: AppColors.forest, size: 20),
            const SizedBox(width: AppSpacing.md12),
            Text(
              '${ExperienceStrings.groupSizeLabel}: ${experience.groupSizeMin} to ${experience.groupSizeMax} max',
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm8),
        Text(
          ExperienceStrings.suitabilityNote,
          style: AppTypography.caption.copyWith(color: AppColors.disabledText),
        ),
      ],
    );
  }

  // Section 11: things to know
  Widget _buildThingsToKnowSection(Experience experience) {
    final List<String> thingsList = [
      ExperienceStrings.cancellationPolicy,
      ...experience.thingsToKnow,
      ...experience.permitsRequired.map((p) => 'Permit required: $p'),
      if (experience.thingsToKnow.isEmpty && experience.permitsRequired.isEmpty)
        ...ExperienceStrings.defaultThingsToKnow,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: ExperienceStrings.thingsToKnowTitle),
        const SizedBox(height: AppSpacing.sm8),
        ...thingsList.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: AppColors.forest, size: 18),
                  const SizedBox(width: AppSpacing.md12),
                  Expanded(
                    child: Text(
                      item,
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  // Section 12: reviews
  Widget _buildReviewsSection(Experience experience, List<Review> reviews) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: ExperienceStrings.reviewsTitle),
        const SizedBox(height: AppSpacing.sm8),
        Row(
          children: [
            Text(
              experience.ratingAvg.toStringAsFixed(1),
              style: AppTypography.displayMedium.copyWith(color: AppColors.forest),
            ),
            const SizedBox(width: AppSpacing.md12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RatingStars(
                  rating: experience.ratingAvg,
                  reviewCount: experience.ratingCount,
                  starSize: 18,
                ),
                Text(
                  'Based on ${experience.ratingCount} guest reviews',
                  style: AppTypography.caption.copyWith(color: AppColors.disabledText),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg16),
        if (reviews.isEmpty)
          Text(
            ExperienceStrings.noReviewsYet,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.disabledText,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          ...reviews.take(3).map((review) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md12),
                child: Container(
                  padding: AppSpacing.paddingMd12,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackgroundAlt,
                    borderRadius: AppRadii.borderMd16,
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RatingStars(rating: review.rating.toDouble(), starSize: 14),
                          Text(
                            AppFormatters.formatTripDate(review.createdAt, pattern: 'd MMM yyyy'),
                            style: AppTypography.caption.copyWith(color: AppColors.disabledText),
                          ),
                        ],
                      ),
                      if (review.title != null) ...[
                        const SizedBox(height: AppSpacing.xs4),
                        Text(
                          review.title!,
                          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                      if (review.body != null) ...[
                        const SizedBox(height: AppSpacing.xs4),
                        Text(
                          review.body!,
                          style: AppTypography.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              )),
      ],
    );
  }

  // Section 13: organizer
  Widget _buildOrganizerSection(BuildContext context, Profile? hostProfile) {
    final String hostName = hostProfile?.fullName ?? 'Himalayan Adventure Guide';
    final String? avatarUrl = hostProfile?.avatarUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: ExperienceStrings.hostedByTitle),
        const SizedBox(height: AppSpacing.sm8),
        Container(
          padding: AppSpacing.paddingLg16,
          decoration: BoxDecoration(
            color: AppColors.cardBackgroundAlt,
            borderRadius: AppRadii.borderMd16,
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.sage,
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? CachedNetworkImageProvider(avatarUrl)
                    : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? const Icon(Icons.person, size: 32, color: AppColors.forest)
                    : null,
              ),
              const SizedBox(width: AppSpacing.lg16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hostName,
                      style: AppTypography.headingMedium.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: AppSpacing.xs4),
                    Row(
                      children: [
                        const Icon(Icons.verified, size: 16, color: AppColors.forest),
                        const SizedBox(width: AppSpacing.xs4),
                        Text(
                          ExperienceStrings.verifiedGuide,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.forest,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs4),
                    Text(
                      ExperienceStrings.responseRateText,
                      style: AppTypography.caption.copyWith(color: AppColors.disabledText),
                    ),
                  ],
                ),
              ),
              AppButton.secondary(
                label: ExperienceStrings.contactHost,
                onPressed: () {
                  AppToast.show(
                    context,
                    message: 'Host contact option coming soon',
                    variant: AppToastVariant.info,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
