// RM-10 Interactive Itinerary
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/format.dart';
import '../../core/experience_presentation.dart';
import '../../core/image_cache_manager.dart';
import '../../core/image_url.dart';
import '../../models/booking.dart';
import '../../models/experience.dart';
import '../../models/itinerary_item.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/empty_state_view.dart';
import '../booking/booking_providers.dart';
import '../experience/experience_detail_providers.dart';

class ItineraryScreen extends ConsumerWidget {
  final String bookingId;

  const ItineraryScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingDetailProvider(bookingId));

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: Text(
          'Experience Details',
          style: AppTypography.headingMedium.copyWith(color: AppColors.ink),
        ),
        backgroundColor: AppColors.ivory,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.emergency_outlined, color: AppColors.error),
            tooltip: 'Emergency',
            onPressed: () => context.push('/emergency'),
          ),
        ],
      ),
      body: SafeArea(
        child: AsyncValueView<Booking?>(
          value: bookingAsync,
          isEmpty: (data) => data == null,
          emptyView: EmptyStateView(
            title: 'Itinerary Not Found',
            description: 'We could not locate the details for this experience.',
            actionLabel: 'Back to Plans',
            onActionPressed: () => context.go('/plans'),
          ),
          onRetry: () => ref.invalidate(bookingDetailProvider(bookingId)),
          data: (booking) {
            final experienceId = booking!.experienceId;
            final experienceAsync = ref.watch(
              experienceDetailProvider(experienceId),
            );

            return AsyncValueView<Experience?>(
              value: experienceAsync,
              isEmpty: (data) => data == null,
              emptyView: EmptyStateView(
                title: 'Itinerary Not Found',
                description:
                    'We could not locate the details for this experience.',
                actionLabel: 'Back to Plans',
                onActionPressed: () => context.go('/plans'),
              ),
              onRetry: () =>
                  ref.invalidate(experienceDetailProvider(experienceId)),
              data: (experience) {
                final exp = experience!;
                final itineraryAsync = ref.watch(
                  experienceItineraryProvider(experienceId),
                );
                final taxonomy = ref
                    .watch(experienceTaxonomyProvider)
                    .valueOrNull;
                final presentation = ExperiencePresentation.from(exp, taxonomy);
                final isAdventure = familySupportsDifficulty(
                  presentation.familySlug,
                );

                return SingleChildScrollView(
                  padding: AppSpacing.screenPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Experience Banner Card
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: AppRadii.borderMd16,
                              child: SizedBox(
                                height: 160,
                                width: double.infinity,
                                child: exp.coverImageUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: resizedImageUrl(
                                          exp.coverImageUrl,
                                          width: 800,
                                        ),
                                        cacheManager:
                                            AppImageCacheManager.instance,
                                        fit: BoxFit.cover,
                                        errorWidget: (context, url, error) =>
                                            Container(
                                              color: AppColors.sage,
                                              child: const Icon(
                                                Icons.image_outlined,
                                                size: 48,
                                                color: AppColors.forest,
                                              ),
                                            ),
                                      )
                                    : Container(
                                        color: AppColors.sage,
                                        child: const Icon(
                                          Icons.image_outlined,
                                          size: 48,
                                          color: AppColors.forest,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md12),
                            Text(
                              exp.title,
                              style: AppTypography.headingMedium.copyWith(
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: AppColors.disabledText,
                                ),
                                const SizedBox(width: AppSpacing.xs4),
                                Expanded(
                                  child: Text(
                                    exp.locationName ?? 'Nepal',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.disabledText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm8),
                            Wrap(
                              spacing: AppSpacing.sm8,
                              runSpacing: AppSpacing.sm8,
                              children: [
                                _buildFeatureChip(
                                  Icons.timer_outlined,
                                  AppFormatters.formatDuration(
                                    exp.durationHours,
                                  ),
                                ),
                                if (isAdventure)
                                  _buildFeatureChip(
                                    Icons.signal_cellular_alt,
                                    exp.difficulty.name.toUpperCase(),
                                  ),
                                _buildFeatureChip(
                                  Icons.payments_outlined,
                                  AppFormatters.formatNpr(exp.pricePaisa),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg16),

                      // Quick Action Navigation Bar
                      Text(
                        'Experience Tools',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildToolkitButton(
                              context,
                              icon: Icons.chat_bubble_outline,
                              label: 'Messages',
                              onTap: () => context.push('/chat/$bookingId'),
                            ),
                          ),
                          if (isAdventure) ...[
                            const SizedBox(width: AppSpacing.sm8),
                            Expanded(
                              child: _buildToolkitButton(
                                context,
                                icon: Icons.checklist_outlined,
                                label: 'Gear List',
                                onTap: () => context.push('/gear/$bookingId'),
                              ),
                            ),
                          ],
                          if (isAdventure ||
                              presentation.familySlug == 'trips-tours') ...[
                            const SizedBox(width: AppSpacing.sm8),
                            Expanded(
                              child: _buildToolkitButton(
                                context,
                                icon: Icons.account_balance_wallet_outlined,
                                label: 'Budget',
                                onTap: () => context.push('/budget/$bookingId'),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: AppSpacing.xl20),

                      // Day-by-Day Itinerary Guide
                      Text(
                        'Experience Schedule',
                        style: AppTypography.headingMedium.copyWith(
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md12),

                      AsyncValueView<List<ItineraryItem>>(
                        value: itineraryAsync,
                        onRetry: () => ref.invalidate(
                          experienceItineraryProvider(experienceId),
                        ),
                        data: (items) {
                          final List<ItineraryItem> sortedItems = List.of(items)
                            ..sort((a, b) {
                              final dayCompare = a.dayNumber.compareTo(
                                b.dayNumber,
                              );
                              return dayCompare != 0
                                  ? dayCompare
                                  : a.sortOrder.compareTo(b.sortOrder);
                            });

                          final int itemCount = sortedItems.isNotEmpty
                              ? sortedItems.length
                              : 1;

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: itemCount,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: AppSpacing.md12),
                            itemBuilder: (context, index) {
                              if (sortedItems.isNotEmpty) {
                                final item = sortedItems[index];
                                return _buildDayCard(
                                  dayNum: item.dayNumber,
                                  title: item.title,
                                  description:
                                      item.description ??
                                      'More details will be shared by your host.',
                                );
                              }
                              final int dayNum = index + 1;
                              return _buildDayCard(
                                dayNum: dayNum,
                                title: exp.title,
                                description:
                                    exp.summary ??
                                    'Schedule details will be shared by your host.',
                              );
                            },
                          );
                        },
                      ),

                      if (exp.bringList.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl20),
                        Text(
                          'What to Bring',
                          style: AppTypography.headingMedium.copyWith(
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm8),
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: exp.bringList
                                .map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.xs4,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          size: 16,
                                          color: AppColors.forest,
                                        ),
                                        const SizedBox(width: AppSpacing.sm8),
                                        Expanded(
                                          child: Text(
                                            item,
                                            style: AppTypography.bodyMedium
                                                .copyWith(color: AppColors.ink),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],

                      const SizedBox(height: AppSpacing.xxl24),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm8,
        vertical: AppSpacing.xs4,
      ),
      decoration: const BoxDecoration(
        color: AppColors.sage,
        borderRadius: AppRadii.borderSm8,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.forest),
          const SizedBox(width: AppSpacing.xs4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.forest,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolkitButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: AppTouchTarget.minSize,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.forest,
          side: const BorderSide(color: AppColors.border),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadii.borderMd16,
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm8),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.forest),
            const SizedBox(width: AppSpacing.xs4),
            Flexible(
              child: Text(
                label,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.forest,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCard({
    required int dayNum,
    required String title,
    required String description,
  }) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.forest,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                'D$dayNum',
                style: AppTypography.caption.copyWith(
                  color: AppColors.ivory,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs4),
                Text(
                  description,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.ink.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
