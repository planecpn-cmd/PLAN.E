// PL-09 Experience Details
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  ConsumerState<ExperienceDetailScreen> createState() =>
      _ExperienceDetailScreenState();
}

class _ExperienceDetailScreenState
    extends ConsumerState<ExperienceDetailScreen> {
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
      backgroundColor: AppColors.ivory,
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
          ? SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: .09),
                      blurRadius: 18,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppFormatters.formatNpr(
                              _selectedDeparture?.priceOverridePaisa ??
                                  experienceAsync.asData!.value!.pricePaisa,
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.forest,
                            ),
                          ),
                          const Text(
                            ExperienceStrings.perPersonUnit,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.disabledText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: Semantics(
                        button: true,
                        label: 'Join experience action button',
                        child: AppButton(
                          label: ExperienceStrings.joinButtonLabel.toUpperCase(),
                          onPressed: () {
                            context.push('/booking/${widget.id}');
                          },
                          minHeight: 42,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildDetailContent(
    BuildContext context,
    Experience experience,
    bool isSaved,
  ) {
    final departuresAsync = ref.watch(
      experienceDeparturesProvider(experience.id),
    );
    final itineraryAsync = ref.watch(
      experienceItineraryProvider(experience.id),
    );
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section 3: title/location/rating/date
                _buildTitleLocationRatingDateSection(experience, departures),
                const SizedBox(height: 20),

                // Section 4: duration/difficulty/altitude/group size
                _buildQuickStatsSection(experience),
                const SizedBox(height: 20),

                // Section 5: overview
                _buildOverviewSection(experience, itinerary),
                const SizedBox(height: 20),

                // Section 6: price
                _buildPriceSection(experience),
                const SizedBox(height: 20),

                // Section 7: included
                _buildIncludedSection(experience),
                const SizedBox(height: 20),

                // Section 8: bring list
                _buildBringListSection(experience),
                const SizedBox(height: 20),

                // Section 9: meeting point + map
                _buildMeetingPointMapSection(context, experience),
                const SizedBox(height: 20),

                // Section 10: participants
                _buildParticipantsSection(experience),
                const SizedBox(height: 20),

                // Section 11: things to know
                _buildThingsToKnowSection(experience),
                const SizedBox(height: 20),

                // Section 12: reviews
                _buildReviewsSection(experience, reviews),
                const SizedBox(height: 20),

                // Section 13: organizer
                _buildOrganizerSection(context, hostProfile),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverSection(
    BuildContext context,
    Experience experience,
    bool isSaved,
  ) {
    return Stack(
      children: [
        Semantics(
          image: true,
          label: 'Cover image for ${experience.title}',
          child: PlanEPhoto(
            imageUrl: experience.coverImageUrl,
            height: 265,
            width: double.infinity,
            radius: 0,
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildCircleIconButton(
                  icon: Icons.chevron_left,
                  label: 'Go back',
                  onPressed: () => context.pop(),
                ),
                const Spacer(),
                _buildCircleIconButton(
                  icon: Icons.ios_share_outlined,
                  label: 'Share experience link',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: experience.title));
                    AppToast.show(
                      context,
                      message: ExperienceStrings.linkCopied,
                      variant: AppToastVariant.info,
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildCircleIconButton(
                  icon: isSaved ? Icons.favorite : Icons.favorite_border,
                  iconColor: isSaved ? AppColors.error : AppColors.ink,
                  label: isSaved ? 'Remove from saved experiences' : 'Save experience',
                  onPressed: () =>
                      _toggleOptimisticSave(experience.id, isSaved),
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
    Color iconColor = AppColors.ink,
    String? label,
    required VoidCallback onPressed,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: .94),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(icon, color: iconColor, size: 22),
          onPressed: onPressed,
        ),
      ),
    );
  }

  Future<void> _toggleOptimisticSave(
    String experienceId,
    bool currentlySaved,
  ) async {
    final client = ref.read(supabaseClientProvider);
    final user = client.auth.currentUser;

    if (user == null) {
      ref
          .read(deferredActionProvider.notifier)
          .setPending(
            DeferredAction(
              screenId: 'PL-09',
              entityId: experienceId,
              action: 'save',
            ),
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

  Widget _buildSpotsLeftSection(List<ExperienceDeparture> departures) {
    if (departures.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: AppColors.sage,
        child: const Row(
          children: [
            Icon(Icons.flash_on, size: 16, color: AppColors.forest),
            SizedBox(width: 8),
            Text(
              ExperienceStrings.instantConfirmation,
              style: TextStyle(
                color: AppColors.forest,
                fontSize: 12,
                fontWeight: FontWeight.w700,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isLowSpot
          ? AppColors.warningContainer
          : AppColors.successContainer,
      child: Row(
        children: [
          Icon(
            isLowSpot ? Icons.local_fire_department : Icons.event_available,
            size: 18,
            color: isLowSpot ? AppColors.warning : AppColors.success,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isLowSpot
                  ? '🔥  ${nextDeparture.spotsLeft} SPOTS LEFT for ${AppFormatters.formatTripDate(nextDeparture.startDate, pattern: 'd MMM')}'
                  : '${nextDeparture.spotsLeft} spots available on ${AppFormatters.formatTripDate(nextDeparture.startDate, pattern: 'd MMM')}',
              style: TextStyle(
                color: isLowSpot ? AppColors.warning : AppColors.success,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleLocationRatingDateSection(
    Experience experience,
    List<ExperienceDeparture> departures,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.sage,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hiking, size: 16, color: AppColors.forest),
              const SizedBox(width: 6),
              Text(
                experience.difficulty.name.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.forest,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          experience.title,
          style: const TextStyle(
            fontFamily: 'serif',
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.forest,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 18,
              color: AppColors.forest,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                experience.locationName ?? 'Nepal',
                style: const TextStyle(fontSize: 13, color: AppColors.ink),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.star, size: 18, color: AppColors.gold),
            const SizedBox(width: 4),
            Text(
              '${experience.ratingAvg} (${experience.ratingCount} reviews)',
              style: const TextStyle(fontSize: 13, color: AppColors.ink),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStatsSection(Experience experience) {
    return Row(
      children: [
        Expanded(
          child: _InfoTile(
            icon: Icons.schedule,
            value: AppFormatters.formatDuration(experience.durationHours),
            label: 'Duration',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _InfoTile(
            icon: Icons.signal_cellular_alt,
            value: experience.difficulty.name.toUpperCase(),
            label: 'Difficulty',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _InfoTile(
            icon: Icons.groups_outlined,
            value: '${experience.groupSizeMin}-${experience.groupSizeMax}',
            label: 'Group size',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _InfoTile(
            icon: Icons.filter_hdr,
            value: '${experience.maxAltitudeM ?? 2000} m',
            label: 'Altitude',
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewSection(
    Experience experience,
    List<ItineraryItem> itinerary,
  ) {
    final String descriptionText =
        experience.description ?? experience.summary ?? '';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: .93),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 20,
                color: AppColors.forest,
              ),
              SizedBox(width: 8),
              Text(
                'Trip Overview',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            descriptionText,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: AppColors.ink,
            ),
            maxLines: _isDescriptionExpanded ? null : 4,
            overflow: _isDescriptionExpanded
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
          ),
          if (descriptionText.length > 180) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isDescriptionExpanded = !_isDescriptionExpanded;
                });
              },
              child: Text(
                _isDescriptionExpanded
                    ? ExperienceStrings.showLess
                    : ExperienceStrings.readMore,
                style: const TextStyle(
                  color: AppColors.forest,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceSection(Experience experience) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sage.withValues(alpha: .5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.sell_outlined, color: AppColors.forest),
              SizedBox(width: 8),
              Text(
                'Price',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AppFormatters.formatNpr(experience.pricePaisa),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.forest,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                '/ person',
                style: TextStyle(fontSize: 12, color: AppColors.disabledText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncludedSection(Experience experience) {
    final List<String> includedItems = experience.included.isNotEmpty
        ? experience.included
        : ExperienceStrings.defaultIncluded;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: .93),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.card_giftcard, size: 20, color: AppColors.forest),
              SizedBox(width: 8),
              Text(
                "What's Included",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...includedItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(item, style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBringListSection(Experience experience) {
    final List<String> bringItems = experience.bringList.isNotEmpty
        ? experience.bringList
        : ExperienceStrings.defaultBringList;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: .93),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.backpack_outlined, size: 20, color: AppColors.forest),
              SizedBox(width: 8),
              Text(
                'What to Bring',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...bringItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_box_outlined,
                    color: AppColors.forest,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(item, style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingPointMapSection(
    BuildContext context,
    Experience experience,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.sage.withValues(alpha: .5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on, color: AppColors.forest),
              SizedBox(width: 8),
              Text(
                'Meeting Point',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            experience.meetingPoint ??
                experience.locationName ??
                'Kathmandu, Nepal',
            style: const TextStyle(fontSize: 13, color: AppColors.ink),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: AppButton(
              label: 'View on Map',
              onPressed: () => context.push('/map'),
              variant: AppButtonVariant.secondary,
              minHeight: 36,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsSection(Experience experience) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: .93),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.group, size: 20, color: AppColors.forest),
          SizedBox(width: 8),
          Text(
            "Who's Joining",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          Spacer(),
          Text(
            'Small Group Tour',
            style: TextStyle(fontSize: 12, color: AppColors.disabledText),
          ),
        ],
      ),
    );
  }

  Widget _buildThingsToKnowSection(Experience experience) {
    const items = [
      'Moderate fitness required',
      'Event runs rain or shine unless unsafe',
      'Arrive 15 minutes early',
      'No plastic littering',
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: .93),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: AppColors.forest),
              SizedBox(width: 8),
              Text(
                'Things to Know',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 8,
                    backgroundColor: AppColors.sage,
                    child: Icon(Icons.check, size: 10, color: AppColors.forest),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(item, style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(Experience experience, List<Review> reviews) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: .93),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, size: 20, color: AppColors.gold),
              const SizedBox(width: 8),
              Text(
                'Reviews (${experience.ratingCount})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (reviews.isNotEmpty)
            ...reviews
                .take(2)
                .map(
                  (rev) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            RatingStars(
                              rating: rev.rating.toDouble(),
                              starSize: 14,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppFormatters.formatTripDate(
                                rev.createdAt,
                                pattern: 'MMM d, yyyy',
                              ),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.disabledText,
                              ),
                            ),
                          ],
                        ),
                        if (rev.body != null && rev.body!.isNotEmpty)
                          Text(
                            rev.body!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.ink,
                            ),
                          ),
                      ],
                    ),
                  ),
                )
          else
            const Text(
              'No reviews yet. Be the first to join!',
              style: TextStyle(fontSize: 12, color: AppColors.disabledText),
            ),
        ],
      ),
    );
  }

  Widget _buildOrganizerSection(BuildContext context, Profile? hostProfile) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: .93),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.sage,
            child: Icon(
              Icons.landscape_outlined,
              size: 24,
              color: AppColors.forest,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hostProfile?.fullName ?? 'PLAN E Local Host',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Verified Himalayan Guide & Local Partner',
                  style: TextStyle(fontSize: 11, color: AppColors.disabledText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: AppColors.forest),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.disabledText),
          ),
        ],
      ),
    );
  }
}
