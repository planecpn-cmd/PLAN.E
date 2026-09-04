// PL-09 Experience Details
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/experience_presentation.dart';
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
import 'limited_package_data.dart';
import 'limited_package_detail.dart';

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

    final experience = experienceAsync.asData?.value;
    final taxonomyAsync = ref.watch(experienceTaxonomyProvider);
    if (experience != null) {
      // Resolve taxonomy before rendering either mode: no flash of host data.
      if (!taxonomyAsync.hasValue) {
        return Scaffold(
          backgroundColor: AppColors.ivory,
          appBar: AppBar(title: const Text('Experience')),
          body: taxonomyAsync.hasError
              ? ErrorStateView(
                  title: 'Category could not be loaded',
                  message: 'Retry to view this experience.',
                  onRetry: () => ref.invalidate(experienceTaxonomyProvider),
                )
              : const Center(child: CircularProgressIndicator()),
        );
      }
      final category = taxonomyAsync.valueOrNull?.categoryFor(
        experience.categoryId,
      );
      if (detailPresentationFor(category) == DetailPresentationType.limited) {
        final regions = ref.watch(regionsProvider).valueOrNull ?? [];
        final region = regions
            .where((r) => r.id == experience.regionId)
            .firstOrNull;
        return LimitedPackageDetail(
          key: ValueKey(experience.id),
          data: LimitedPackageData.from(experience, category, region),
          content: ref.watch(limitedPackageContentProvider(experience.id)),
          departures: ref.watch(experienceDeparturesProvider(experience.id)),
          reviews: LimitedPackageDetail.reviewSummaries(
            ref.watch(experienceReviewsProvider(experience.id)),
          ),
          isSaved: isSaved,
          onBack: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
          onSave: () => _toggleOptimisticSave(experience.id, isSaved),
          onShare: () async {
            await Clipboard.setData(ClipboardData(text: experience.title));
            if (context.mounted) {
              AppToast.show(
                context,
                message: 'Experience title copied',
                variant: AppToastVariant.info,
              );
            }
          },
          onContinueStandard: () => context.push('/booking/${experience.id}'),
          onRetryDepartures: () =>
              ref.invalidate(experienceDeparturesProvider(experience.id)),
          onRetryReviews: () =>
              ref.invalidate(experienceReviewsProvider(experience.id)),
        );
      }
    }

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: PlanEBackground(
        safeArea: false,
        child: AsyncValueView<Experience?>(
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
                          label: ExperienceStrings.joinButtonLabel
                              .toUpperCase(),
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
    final taxonomy = ref.watch(experienceTaxonomyProvider).valueOrNull;
    final presentation = ExperiencePresentation.from(experience, taxonomy);
    final isAdventure = familySupportsDifficulty(presentation.familySlug);

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
                _buildTitleLocationRatingDateSection(experience, presentation),
                const SizedBox(height: 20),

                // Universal facts plus family-specific context.
                _buildQuickStatsSection(experience, isAdventure),
                const SizedBox(height: 20),

                _buildOverviewSection(experience),
                const SizedBox(height: 20),

                _buildOrganizerSection(context, hostProfile),
                if (itinerary.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildScheduleSection(itinerary),
                ],
                const SizedBox(height: 20),

                _buildPriceSection(experience),

                if (experience.included.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildIncludedSection(experience),
                ],

                if (experience.bringList.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildBringListSection(experience),
                ],

                const SizedBox(height: 20),
                _buildMeetingPointMapSection(context, experience),

                if (experience.thingsToKnow.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildThingsToKnowSection(experience),
                ],

                const SizedBox(height: 20),
                _buildReviewsSection(experience, reviews),
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
            imageRequestWidth: 900,
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
                  label: isSaved
                      ? 'Remove from saved experiences'
                      : 'Save experience',
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
            Expanded(
              child: Text(
                ExperienceStrings.instantConfirmation,
                style: TextStyle(
                  color: AppColors.forest,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
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
                  ? '${nextDeparture.spotsLeft} SPOTS LEFT for ${AppFormatters.formatTripDate(nextDeparture.startDate, pattern: 'd MMM')}'
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
    ExperiencePresentation presentation,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (presentation.familyLabel != null ||
            presentation.typeLabel != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.sage,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.explore_outlined,
                  size: 16,
                  color: AppColors.forest,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    [
                      if (presentation.familyLabel != null)
                        presentation.familyLabel!,
                      if (presentation.typeLabel != null)
                        presentation.typeLabel!,
                    ].join(' • ').toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.forest,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
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

  Widget _buildQuickStatsSection(Experience experience, bool isAdventure) {
    final facts = <_ExperienceFact>[
      _ExperienceFact(
        Icons.schedule,
        AppFormatters.formatDuration(experience.durationHours),
        'Duration',
      ),
      _ExperienceFact(
        Icons.groups_outlined,
        '${experience.groupSizeMin}-${experience.groupSizeMax}',
        'Group size',
      ),
      _ExperienceFact(Icons.person_outline, '${experience.minAge}+', 'Min age'),
      if (isAdventure)
        _ExperienceFact(
          Icons.signal_cellular_alt,
          experience.difficulty.name.toUpperCase(),
          'Difficulty',
        ),
      if (isAdventure && experience.maxAltitudeM != null)
        _ExperienceFact(
          Icons.filter_hdr,
          '${experience.maxAltitudeM} m',
          'Altitude',
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: facts
              .map(
                (fact) => SizedBox(
                  width: tileWidth,
                  child: _InfoTile(
                    icon: fact.icon,
                    value: fact.value,
                    label: fact.label,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildOverviewSection(Experience experience) {
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
                Icons.auto_stories_outlined,
                size: 20,
                color: AppColors.forest,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'About this experience',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
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

  Widget _buildScheduleSection(List<ItineraryItem> itinerary) {
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
                Icons.event_note_outlined,
                size: 20,
                color: AppColors.forest,
              ),
              SizedBox(width: 8),
              Text(
                'Schedule',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...itinerary.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    constraints: const BoxConstraints(minWidth: 52),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.sage,
                      borderRadius: AppRadii.borderSm8,
                    ),
                    child: Text(
                      item.startTime?.isNotEmpty == true
                          ? item.startTime!
                          : 'Day ${item.dayNumber}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.forest,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (item.description?.isNotEmpty == true)
                          Text(
                            item.description!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.disabledText,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 6,
            children: [
              Text(
                AppFormatters.formatNpr(experience.pricePaisa),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.forest,
                ),
              ),
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
          ...experience.included.map(
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
          ...experience.bringList.map(
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
              Expanded(
                child: Text(
                  'Meeting Point',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
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

  Widget _buildThingsToKnowSection(Experience experience) {
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
          ...experience.thingsToKnow.map(
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
              Icons.person_outline,
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
                  'Verified local host',
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

class _ExperienceFact {
  const _ExperienceFact(this.icon, this.value, this.label);

  final IconData icon;
  final String value;
  final String label;
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
      constraints: const BoxConstraints(minHeight: 80),
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
