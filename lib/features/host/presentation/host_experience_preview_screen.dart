import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../theme/theme.dart';
import '../../../widgets/widgets.dart';
import '../domain/host_experience_validator.dart';
import 'host_mode_providers.dart';
import 'widgets/host_mode_scaffold.dart';

class HostExperiencePreviewScreen extends ConsumerStatefulWidget {
  const HostExperiencePreviewScreen({super.key});
  @override
  ConsumerState<HostExperiencePreviewScreen> createState() =>
      _HostExperiencePreviewScreenState();
}

class _HostExperiencePreviewScreenState
    extends ConsumerState<HostExperiencePreviewScreen> {
  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(hostCreateExperienceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Preview & Submit')),
      backgroundColor: const Color(0xFFF7F8F5),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
        children: [
          const Text(
            'Step 10 of 10',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.forest,
            ),
          ),
          const SizedBox(height: 7),
          const LinearProgressIndicator(
            value: 1,
            minHeight: 7,
            backgroundColor: AppColors.sage,
            color: AppColors.forest,
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (draft.photoAssets.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: _DraftPhoto(
                      path: draft.photoAssets.first,
                      height: 190,
                      width: double.infinity,
                    ),
                  ),
                Padding(
                  padding: AppSpacing.paddingLg16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        draft.title,
                        style: AppTypography.headingLarge.copyWith(
                          fontFamily: 'serif',
                        ),
                      ),
                      Text(
                        draft.location,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.disabledText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(draft.description),
                      const Divider(height: 26),
                      _PreviewRow(
                        'Dates',
                        draft.startDate == null
                            ? 'Not set'
                            : '${DateFormat('d MMM').format(draft.startDate!)} – ${DateFormat('d MMM y').format(draft.endDate!)}',
                      ),
                      _PreviewRow('Capacity', '${draft.capacity ?? 0} guests'),
                      _PreviewRow(
                        'Price',
                        'NPR ${NumberFormat('#,###').format(draft.priceNpr ?? 0)}',
                      ),
                      _PreviewRow('Meeting', draft.meetingPoint),
                      const SizedBox(height: 12),
                      Text(
                        'Itinerary',
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      ...draft.itinerary.asMap().entries.map(
                        (item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 13,
                            backgroundColor: AppColors.sage,
                            child: Text(
                              '${item.key + 1}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.forest,
                              ),
                            ),
                          ),
                          title: Text(
                            item.value,
                            style: AppTypography.bodyMedium,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'What’s included',
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      ...draft.included.map(
                        (item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.check_circle_outline,
                            color: AppColors.success,
                          ),
                          title: Text(item),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'What to bring',
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      ...draft.bring.map(
                        (item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.backpack_outlined,
                            color: AppColors.forest,
                          ),
                          title: Text(item),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: AppButton.secondary(
                  label: 'Back',
                  onPressed: () => context.pop(),
                  isFullWidth: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  label: 'Submit for review',
                  onPressed: _submit,
                  isFullWidth: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // H0 stopgap: submitting an experience for review is not wired to a backend
  // yet (see docs/H1_HOST_WRITE_PATH.md). Validate for feedback, then show a
  // clear notice instead of calling the repository, whose submitForReview
  // throws an unhandled StateError in production.
  void _submit() {
    final draft = ref.read(hostCreateExperienceProvider);
    final errors = HostExperienceValidator.validateForSubmission(draft);
    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errors.values.first)));
      return;
    }
    showUnavailableNotice(context, 'Submitting experiences for review');
  }
}

class _DraftPhoto extends StatelessWidget {
  const _DraftPhoto({required this.path, this.height, this.width});

  final String path;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    if (path.startsWith('assets/')) {
      return Image.asset(path, height: height, width: width, fit: BoxFit.cover);
    }
    return Image.file(
      File(path),
      height: height,
      width: width,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        height: height,
        width: width,
        color: AppColors.sage,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_outlined),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.disabledText,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
