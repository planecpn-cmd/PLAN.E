// Low-commitment entry point: a short preference quiz that calls a real
// LLM (Claude, via the generate-itinerary Edge Function) to recommend a
// personalized plan built only from PLAN E's own catalog.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../models/generated_itinerary.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

const _tripTypes = ['Trekking', 'Wildlife', 'Culture', 'Wellness', 'Adventure'];
const _paces = ['Relaxed', 'Moderate', 'Intense'];
const _groupTypes = ['Solo', 'Couple', 'Family', 'Friends'];

class AiItineraryScreen extends ConsumerStatefulWidget {
  const AiItineraryScreen({super.key});

  @override
  ConsumerState<AiItineraryScreen> createState() => _AiItineraryScreenState();
}

class _AiItineraryScreenState extends ConsumerState<AiItineraryScreen> {
  String _tripType = _tripTypes.first;
  String _pace = _paces[1];
  String _groupType = _groupTypes.first;
  int _durationDays = 7;
  final _interestsController = TextEditingController();
  final _budgetController = TextEditingController();

  @override
  void dispose() {
    _interestsController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final budget = int.tryParse(_budgetController.text.trim());
    await ref.read(aiItineraryNotifierProvider.notifier).generate(
          tripType: _tripType,
          durationDays: _durationDays,
          pace: _pace,
          groupType: _groupType,
          budgetNpr: budget,
          interests: _interestsController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiItineraryNotifierProvider);
    final aiItineraryEnabled = ref.watch(featureFlagProvider('ai_itinerary')) ?? true;
    // No cache exists for this — it's a live LLM call — so offline isn't
    // "show stale data", it's "this genuinely cannot work right now".
    // Gating the button up front beats letting someone fill out the whole
    // quiz and only then get a raw network-exception error message.
    final isOffline = ref.watch(isOfflineProvider);

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: Text(
          'AI Trip Planner',
          style: AppTypography.headingMedium.copyWith(color: AppColors.ink),
        ),
        backgroundColor: AppColors.ivory,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          constraints: AppTouchTarget.minConstraints,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              // Home already pulls the entry CTA when this flag is off, but a
              // deep link, browser back, or an already-open screen when the
              // flag flips mid-session can still land here — so the screen
              // itself needs the same gate, not just its one entry point.
              child: !aiItineraryEnabled
                  ? const EmptyStateView(
                      icon: Icons.auto_awesome_outlined,
                      title: 'AI Planning Unavailable',
                      description:
                          'AI trip planning is temporarily offline. Try Search instead, or check back soon.',
                    )
                  : state.result != null
                      ? _ResultView(
                          result: state.result!,
                          onStartOver: () => ref.read(aiItineraryNotifierProvider.notifier).reset(),
                        )
                      : _QuizView(
                          tripType: _tripType,
                          pace: _pace,
                          groupType: _groupType,
                          durationDays: _durationDays,
                          interestsController: _interestsController,
                          budgetController: _budgetController,
                          isLoading: state.isLoading,
                          isOffline: isOffline,
                          errorMessage: state.errorMessage,
                          onTripTypeChanged: (v) => setState(() => _tripType = v),
                          onPaceChanged: (v) => setState(() => _pace = v),
                          onGroupTypeChanged: (v) => setState(() => _groupType = v),
                          onDurationChanged: (v) => setState(() => _durationDays = v),
                          onSubmit: _generate,
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizView extends StatelessWidget {
  final String tripType;
  final String pace;
  final String groupType;
  final int durationDays;
  final TextEditingController interestsController;
  final TextEditingController budgetController;
  final bool isLoading;
  final bool isOffline;
  final String? errorMessage;
  final ValueChanged<String> onTripTypeChanged;
  final ValueChanged<String> onPaceChanged;
  final ValueChanged<String> onGroupTypeChanged;
  final ValueChanged<int> onDurationChanged;
  final VoidCallback onSubmit;

  const _QuizView({
    required this.tripType,
    required this.pace,
    required this.groupType,
    required this.durationDays,
    required this.interestsController,
    required this.budgetController,
    required this.isLoading,
    required this.isOffline,
    required this.errorMessage,
    required this.onTripTypeChanged,
    required this.onPaceChanged,
    required this.onGroupTypeChanged,
    required this.onDurationChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.gold, size: 22),
              const SizedBox(width: AppSpacing.sm8),
              Text('Tell us about your trip', style: AppTypography.headingMedium.copyWith(fontSize: 20)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs4),
          Text(
            "We'll match you to real experiences from our catalog — no generic suggestions.",
            style: AppTypography.bodyMedium.copyWith(color: AppColors.disabledText),
          ),
          const SizedBox(height: AppSpacing.xxl24),

          Text('Trip type', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm8),
          Wrap(
            spacing: AppSpacing.sm8,
            runSpacing: AppSpacing.sm8,
            children: _tripTypes
                .map((t) => FilterChipPill(
                      label: t,
                      isSelected: tripType == t,
                      onSelected: (_) => onTripTypeChanged(t),
                    ))
                .toList(),
          ),
          const SizedBox(height: AppSpacing.xl20),

          Text('Duration', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm8),
          AppCard(
            child: CounterField(
              label: '$durationDays days',
              value: durationDays,
              min: 1,
              max: 21,
              onChanged: onDurationChanged,
            ),
          ),
          const SizedBox(height: AppSpacing.xl20),

          Text('Pace', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm8),
          Wrap(
            spacing: AppSpacing.sm8,
            children: _paces
                .map((p) => FilterChipPill(
                      label: p,
                      isSelected: pace == p,
                      onSelected: (_) => onPaceChanged(p),
                    ))
                .toList(),
          ),
          const SizedBox(height: AppSpacing.xl20),

          Text('Who is going', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm8),
          Wrap(
            spacing: AppSpacing.sm8,
            children: _groupTypes
                .map((g) => FilterChipPill(
                      label: g,
                      isSelected: groupType == g,
                      onSelected: (_) => onGroupTypeChanged(g),
                    ))
                .toList(),
          ),
          const SizedBox(height: AppSpacing.xl20),

          AppTextField(
            label: 'Budget in NPR (optional)',
            hint: 'e.g. 150000',
            controller: budgetController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.lg16),

          AppTextField(
            label: 'Anything specific? (optional)',
            hint: 'e.g. photography, local food, monasteries',
            controller: interestsController,
          ),
          const SizedBox(height: AppSpacing.xxl24),

          if (isOffline) ...[
            Container(
              padding: AppSpacing.paddingMd12,
              decoration: const BoxDecoration(
                color: AppColors.warningContainer,
                borderRadius: AppRadii.borderSm8,
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 18, color: AppColors.warning),
                  const SizedBox(width: AppSpacing.sm8),
                  Expanded(
                    child: Text(
                      'AI planning needs an internet connection — there\'s no offline fallback for this one.',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md12),
          ] else if (errorMessage != null) ...[
            Text(errorMessage!, style: AppTypography.bodyMedium.copyWith(color: AppColors.error)),
            const SizedBox(height: AppSpacing.md12),
          ],

          AppButton(
            label: 'Generate My Plan',
            icon: Icons.auto_awesome,
            isFullWidth: true,
            isLoading: isLoading,
            onPressed: (isLoading || isOffline) ? null : onSubmit,
          ),
          const SizedBox(height: AppSpacing.lg16),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final GeneratedItinerary result;
  final VoidCallback onStartOver;

  const _ResultView({required this.result, required this.onStartOver});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.gold, size: 22),
              const SizedBox(width: AppSpacing.sm8),
              Text('Your Personalized Plan', style: AppTypography.headingMedium.copyWith(fontSize: 20)),
            ],
          ),
          const SizedBox(height: AppSpacing.md12),
          Text(result.summary, style: AppTypography.bodyLarge),
          if (result.notes != null && result.notes!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm8),
            Container(
              padding: AppSpacing.paddingMd12,
              decoration: const BoxDecoration(
                color: AppColors.warningContainer,
                borderRadius: AppRadii.borderSm8,
              ),
              child: Text(
                result.notes!,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.warning),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl20),

          if (result.picks.isEmpty)
            const EmptyStateView(
              title: 'No Matching Experiences',
              description: 'Try adjusting your preferences and generate again.',
              icon: Icons.explore_off_outlined,
            )
          else
            ...result.picks.map(
              (pick) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md12),
                child: AppCard(
                  onTap: () => context.push('/experience/${pick.experienceId}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pick.title, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                      if (pick.region != null) ...[
                        const SizedBox(height: 2),
                        Text(pick.region!, style: AppTypography.caption.copyWith(color: AppColors.disabledText)),
                      ],
                      const SizedBox(height: AppSpacing.sm8),
                      Text(pick.reason, style: AppTypography.bodyMedium.copyWith(fontStyle: FontStyle.italic)),
                      const SizedBox(height: AppSpacing.sm8),
                      Row(
                        children: [
                          if (pick.durationDays > 0) ...[
                            const Icon(Icons.schedule, size: 14, color: AppColors.disabledText),
                            const SizedBox(width: 4),
                            Text('${pick.durationDays}d', style: AppTypography.caption),
                            const SizedBox(width: AppSpacing.md12),
                          ],
                          if (pick.priceNpr > 0)
                            Text(
                              AppFormatters.formatNpr(pick.priceNpr * 100),
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
              ),
            ),

          const SizedBox(height: AppSpacing.md12),
          AppButton.secondary(
            label: 'Start Over',
            isFullWidth: true,
            onPressed: onStartOver,
          ),
        ],
      ),
    );
  }
}
