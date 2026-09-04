import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/format.dart';
import '../../models/experience_departure.dart';
import '../../models/review.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import 'limited_package_data.dart';

enum _PackageChoice { standard, custom }

class LimitedPackageDetail extends StatefulWidget {
  final LimitedPackageData data;
  final LimitedPackageContent content;
  final AsyncValue<List<ExperienceDeparture>> departures;
  // Ratings and dates only; unrestricted review text is not passed to widgets.
  final AsyncValue<List<({int rating, DateTime date})>> reviews;
  final bool isSaved;
  final VoidCallback onBack;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onContinueStandard;
  final VoidCallback onRetryDepartures;
  final VoidCallback onRetryReviews;
  const LimitedPackageDetail({
    super.key,
    required this.data,
    required this.content,
    required this.departures,
    required this.reviews,
    required this.isSaved,
    required this.onBack,
    required this.onSave,
    required this.onShare,
    required this.onContinueStandard,
    required this.onRetryDepartures,
    required this.onRetryReviews,
  });

  static AsyncValue<List<({int rating, DateTime date})>> reviewSummaries(
    AsyncValue<List<Review>> value,
  ) => value.whenData(
    (reviews) =>
        reviews.map((r) => (rating: r.rating, date: r.createdAt)).toList(),
  );

  @override
  State<LimitedPackageDetail> createState() => _LimitedPackageDetailState();
}

class _LimitedPackageDetailState extends State<LimitedPackageDetail> {
  final _packageKey = GlobalKey();
  final _selected = <String>{};
  _PackageChoice? _choice;
  int _photo = 0;
  final _photos = PageController();

  @override
  void dispose() {
    _photos.dispose();
    super.dispose();
  }

  String get _price => widget.data.currency == 'NPR'
      ? AppFormatters.formatNpr(widget.data.pricePaisa)
      : '${widget.data.currency} ${(widget.data.pricePaisa / 100).toStringAsFixed(2)}';

  void _choosePackage() {
    final target = _packageKey.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 300),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final content = widget.content;
    final duration = data.durationHours > 0
        ? AppFormatters.formatDuration(data.durationHours)
        : null;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: _DetailTextScaler(MediaQuery.textScalerOf(context)),
      ),
      child: Scaffold(
        backgroundColor: AppColors.ivory,
        body: PlanEBackground(
          safeArea: false,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _hero(),
                _availability(),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.sage,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                data.category.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.forest,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            data.title,
                            style: const TextStyle(
                              fontFamily: 'serif',
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.forest,
                            ),
                          ),
                          const SizedBox(height: 8),
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
                                  data.region ??
                                      'Region details will be available soon.',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Icon(
                                Icons.star,
                                color: AppColors.gold,
                                size: 20,
                              ),
                              Text(
                                data.reviewCount > 0
                                    ? '${data.rating} (${data.reviewCount} reviews)'
                                    : 'No reviews yet',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _summaryGrid(duration),
                          const SizedBox(height: 20),
                          _section(
                            'Basic Info',
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final columns =
                                    constraints.maxWidth >= 300 &&
                                        MediaQuery.textScalerOf(
                                              context,
                                            ).scale(14) <=
                                            21
                                    ? 2
                                    : 1;
                                final facts = {
                                  'Best Season': data.bestSeason.isEmpty
                                      ? null
                                      : data.bestSeason
                                            .map(
                                              (m) => DateFormat.MMM().format(
                                                DateTime(2026, m),
                                              ),
                                            )
                                            .join(', '),
                                  'Starting Point': content.startingPoint,
                                  'Total Distance': content.totalDistance,
                                  'Maximum Altitude':
                                      data.maxAltitudeM != null &&
                                          data.maxAltitudeM! > 0
                                      ? '${data.maxAltitudeM} m'
                                      : null,
                                  'Duration': duration,
                                };
                                return Wrap(
                                  spacing: 16,
                                  runSpacing: 20,
                                  children: facts.entries
                                      .map(
                                        (entry) => SizedBox(
                                          width:
                                              (constraints.maxWidth -
                                                  (columns - 1) * 16) /
                                              columns,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                entry.key,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: AppColors.forest,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                entry.value
                                                            ?.trim()
                                                            .isNotEmpty ==
                                                        true
                                                    ? entry.value!
                                                    : 'Details coming soon',
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                );
                              },
                            ),
                          ),
                          _section(
                            'Schedule',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Basic Itinerary',
                                  style: TextStyle(color: AppColors.forest),
                                ),
                                if (content.stages.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 12),
                                    child: Text(
                                      'The trip overview will be available soon.',
                                    ),
                                  ),
                                ...content.stages.asMap().entries.map((entry) {
                                  final stage = entry.value;
                                  return ExpansionTile(
                                    key: PageStorageKey('stage-${entry.key}'),
                                    tilePadding: EdgeInsets.zero,
                                    title: Text(
                                      'Day ${stage.day}  ${stage.route}',
                                    ),
                                    childrenPadding: const EdgeInsets.only(
                                      bottom: 16,
                                    ),
                                    expandedCrossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (stage.distance != null)
                                        Text('Distance: ${stage.distance}'),
                                      if (stage.altitude != null)
                                        Text('Altitude: ${stage.altitude}'),
                                      if (stage.walkingTime != null)
                                        Text(
                                          'Walking time: ${stage.walkingTime}',
                                        ),
                                      ...stage.highlights.map(
                                        (h) => Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: Text(h),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ),
                          _section(
                            'Checklist',
                            child: _list(
                              content.checklist,
                              'Your preparation checklist will be available soon.',
                            ),
                          ),
                          _section(
                            'Things to Know',
                            child: _list([
                              if (data.minAge > 0)
                                'Minimum age: ${data.minAge} years',
                              ...content.thingsToKnow,
                            ], 'Journey requirements will be available soon.'),
                          ),
                          _section(
                            'Download Itinerary',
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Keep the trip overview with you for easy planning.',
                                ),
                                SizedBox(height: 12),
                                AppButton.secondary(
                                  label: 'Download Itinerary',
                                  icon: Icons.download_outlined,
                                ),
                                SizedBox(height: 8),
                                Text('Download is not available yet.'),
                              ],
                            ),
                          ),
                          Container(
                            key: _packageKey,
                            child: _section(
                              'Choose Your Package',
                              child: RadioGroup<_PackageChoice>(
                                groupValue: _choice,
                                onChanged: (value) =>
                                    setState(() => _choice = value),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    RadioListTile<_PackageChoice>(
                                      value: _PackageChoice.standard,
                                      contentPadding: EdgeInsets.zero,
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      title: const Text(
                                        'Standard Package',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Ready to Go',
                                            style: TextStyle(
                                              color: AppColors.forest,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '$_price / person',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              color: AppColors.forest,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'The pre-designed Plan E package. Final price depends on your departure.',
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_choice == _PackageChoice.standard)
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          16,
                                          8,
                                          16,
                                          12,
                                        ),
                                        child: _list(
                                          content.inclusions,
                                          'Package inclusions will be available soon.',
                                        ),
                                      ),
                                    const Divider(height: 24),
                                    const RadioListTile<_PackageChoice>(
                                      value: _PackageChoice.custom,
                                      contentPadding: EdgeInsets.zero,
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      title: Text(
                                        'Plan It Your Own Style',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      subtitle: Padding(
                                        padding: EdgeInsets.only(top: 8),
                                        child: Text(
                                          'Adjust selected parts of the journey to suit how you want to travel.',
                                        ),
                                      ),
                                    ),
                                    if (_choice == _PackageChoice.custom) ...[
                                      const Divider(height: 24),
                                      _customization(),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                          _section(
                            'Reviews (${data.reviewCount})',
                            child: widget.reviews.when(
                              loading: () => const LinearProgressIndicator(),
                              error: (error, stack) => Column(
                                children: [
                                  const Text('Reviews could not be loaded.'),
                                  TextButton(
                                    onPressed: widget.onRetryReviews,
                                    child: const Text('Retry reviews'),
                                  ),
                                ],
                              ),
                              data: (reviews) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (reviews.isEmpty)
                                    const Text('No reviews yet.'),
                                  ...reviews
                                      .take(2)
                                      .map(
                                        (review) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: Wrap(
                                            spacing: 12,
                                            runSpacing: 4,
                                            children: [
                                              RatingStars(
                                                rating: review.rating
                                                    .toDouble(),
                                              ),
                                              Text(
                                                DateFormat.yMMMd().format(
                                                  review.date,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  if (reviews.isNotEmpty)
                                    const Text(
                                      'Customer ratings shown. Written reviews are awaiting a privacy review.',
                                    ),
                                ],
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
        ),
        bottomNavigationBar: SafeArea(
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
                  flex: 4,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _choice == _PackageChoice.custom
                            ? 'Customized Plan'
                            : _price,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.forest,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (_choice != _PackageChoice.custom)
                        const Text(
                          '/ person',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.disabledText,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 5,
                  child: _button(
                    _choice == null ? 'CHOOSE PACKAGE' : 'CONTINUE',
                    _choice == null
                        ? _choosePackage
                        : _choice == _PackageChoice.standard
                        ? widget.onContinueStandard
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hero() => SizedBox(
    height: (MediaQuery.sizeOf(context).height * .38).clamp(265.0, 380.0),
    child: Stack(
      fit: StackFit.expand,
      children: [
        if (widget.data.photos.isEmpty)
          const PlanEPhoto(radius: 0, width: double.infinity)
        else
          PageView.builder(
            controller: _photos,
            itemCount: widget.data.photos.length,
            onPageChanged: (index) => setState(() => _photo = index),
            itemBuilder: (context, index) => Semantics(
              image: true,
              label: 'Journey photo ${index + 1}',
              child: PlanEPhoto(
                imageUrl: widget.data.photos[index],
                radius: 0,
                imageRequestWidth: 900,
              ),
            ),
          ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(10.8),
              child: Row(
                children: [
                  _circle(Icons.chevron_left, 'Go back', widget.onBack),
                  const SizedBox(width: 7.2),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5.4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: .94),
                          borderRadius: BorderRadius.circular(14.4),
                        ),
                        child: Text(
                          widget.data.category,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.forest,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 7.2),
                  _circle(
                    Icons.ios_share_outlined,
                    'Share experience',
                    widget.onShare,
                  ),
                  const SizedBox(width: 7.2),
                  _circle(
                    widget.isSaved ? Icons.favorite : Icons.favorite_border,
                    widget.isSaved
                        ? 'Remove from saved experiences'
                        : 'Save experience',
                    widget.onSave,
                    color: widget.isSaved ? AppColors.error : AppColors.ink,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.data.photos.length > 1)
          Positioned(
            bottom: 12,
            right: 12,
            child: Material(
              color: AppColors.white.withValues(alpha: .94),
              borderRadius: BorderRadius.circular(24),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Previous photo',
                    onPressed: _photo > 0
                        ? () => _photos.jumpToPage(_photo - 1)
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(
                    '${_photo + 1} / ${widget.data.photos.length}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  IconButton(
                    tooltip: 'Next photo',
                    onPressed: _photo + 1 < widget.data.photos.length
                        ? () => _photos.jumpToPage(_photo + 1)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );

  Widget _circle(
    IconData icon,
    String label,
    VoidCallback action, {
    Color color = AppColors.ink,
  }) => SizedBox(
    width: 48,
    height: 48,
    // Keep the 48px touch target while reducing the visible control by 10%.
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          left: 2.4,
          top: 2.4,
          right: 2.4,
          bottom: 2.4,
          child: Material(
            color: AppColors.white.withValues(alpha: .94),
            shape: const CircleBorder(),
          ),
        ),
        IconButton(
          tooltip: label,
          onPressed: action,
          icon: Icon(icon, color: color, size: 19.8),
        ),
      ],
    ),
  );

  Widget _availability() => Container(
    color: AppColors.sage,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      children: [
        const Icon(Icons.event_available, size: 18, color: AppColors.forest),
        const SizedBox(width: 8),
        Expanded(
          child: DefaultTextStyle(
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.forest,
              fontWeight: FontWeight.w600,
            ),
            child: widget.departures.when(
              loading: () => const Text('Checking availability…'),
              error: (error, stack) => Column(
                children: [
                  const Text('Availability could not be loaded.'),
                  TextButton(
                    onPressed: widget.onRetryDepartures,
                    child: const Text('Retry availability'),
                  ),
                ],
              ),
              data: (departures) {
                final next = nextPackageDeparture(departures, DateTime.now());
                return Text(
                  next == null
                      ? 'No upcoming departures available.'
                      : '${next.spotsLeft} spots available on ${AppFormatters.formatTripDate(next.startDate, pattern: 'd MMM yyyy')}',
                  style: const TextStyle(
                    color: AppColors.forest,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    ),
  );

  Widget _customization() {
    final options = widget.content.options;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (options.isEmpty)
          const Text(
            'Customization options are not available for this package yet.',
          ),
        for (final group in options.map((o) => o.group).toSet()) ...[
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              group,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          for (final option in options.where((o) => o.group == group))
            if (option.required)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.lock_outline,
                  color: AppColors.forest,
                ),
                title: Text(option.label),
                subtitle: const Text('Included / Required'),
              )
            else if (option.exclusiveGroup != null)
              RadioGroup<String>(
                groupValue: options
                    .where(
                      (o) =>
                          o.exclusiveGroup == option.exclusiveGroup &&
                          _selected.contains(o.id),
                    )
                    .firstOrNull
                    ?.id,
                onChanged: (id) => setState(() {
                  _selected.removeAll(
                    options
                        .where((o) => o.exclusiveGroup == option.exclusiveGroup)
                        .map((o) => o.id),
                  );
                  if (id != null) _selected.add(id);
                }),
                child: RadioListTile<String>(
                  value: option.id,
                  toggleable: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(option.label),
                ),
              )
            else ...[
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(option.label),
                subtitle: option.exclusiveGroup == null
                    ? null
                    : const Text('Choose one option in this group'),
                value: _selected.contains(option.id),
                onChanged: (checked) => setState(() {
                  if (checked == true) {
                    if (option.exclusiveGroup != null) {
                      _selected.removeAll(
                        options
                            .where(
                              (o) => o.exclusiveGroup == option.exclusiveGroup,
                            )
                            .map((o) => o.id),
                      );
                    }
                    _selected.add(option.id);
                  } else {
                    _selected.remove(option.id);
                  }
                }),
              ),
              if (option.allowsNote && _selected.contains(option.id))
                TextFormField(
                  key: ValueKey('note-${option.id}'),
                  maxLines: 3,
                  maxLength: 500,
                  decoration: InputDecoration(
                    labelText: '${option.label} — optional note',
                    border: const OutlineInputBorder(),
                  ),
                ),
            ],
        ],
        const SizedBox(height: 16),
        const Text('Your Plan', style: TextStyle(fontWeight: FontWeight.bold)),
        Text('Base package: $_price / person'),
        ...options
            .where((o) => o.required || _selected.contains(o.id))
            .map((o) => Text(o.label)),
        const SizedBox(height: 8),
        const Text('Final price will be confirmed after customization review.'),
        const SizedBox(height: 12),

        const SizedBox(height: 8),
        const Text(
          'Customized plan requests are not available yet. You can continue with the Standard Package.',
        ),
      ],
    );
  }

  Widget _summaryGrid(String? duration) => LayoutBuilder(
    builder: (context, constraints) {
      final facts = <({IconData icon, String value, String label})>[
        if (duration != null)
          (icon: Icons.schedule, value: duration, label: 'Duration'),
        if (widget.data.groupMin > 0 &&
            widget.data.groupMax >= widget.data.groupMin)
          (
            icon: Icons.groups_outlined,
            value: '${widget.data.groupMin}–${widget.data.groupMax}',
            label: 'Group size',
          ),
        (
          icon: Icons.signal_cellular_alt,
          value:
              widget.data.difficulty[0].toUpperCase() +
              widget.data.difficulty.substring(1),
          label: 'Difficulty',
        ),
      ];
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: facts
            .map(
              (fact) => SizedBox(
                width:
                    (constraints.maxWidth - 8 * (facts.length - 1)) /
                    facts.length,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 72),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Icon(fact.icon, size: 18, color: AppColors.forest),
                      const SizedBox(height: 4),
                      Text(
                        fact.value,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        fact.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.disabledText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      );
    },
  );

  IconData _sectionIcon(String title) => switch (title) {
    'Choose Your Package' => Icons.checklist_outlined,
    'Basic Info' => Icons.auto_stories_outlined,
    'Schedule' => Icons.event_note_outlined,
    'Checklist' => Icons.backpack_outlined,
    'Things to Know' => Icons.info_outline,
    'Download Itinerary' => Icons.download_outlined,
    'Standard Package' => Icons.sell_outlined,
    'Plan It Your Own Style' => Icons.tune,
    _ => Icons.star_outline,
  };

  Widget _section(
    String title, {
    required Widget child,
    bool selected = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: AppCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 18,
      backgroundColor: selected
          ? AppColors.sage.withValues(alpha: .5)
          : AppColors.white.withValues(alpha: .93),
      borderColor: selected ? AppColors.forest : AppColors.border,
      child: Material(
        color: AppColors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              selected: selected,
              child: Row(
                children: [
                  Icon(_sectionIcon(title), size: 20, color: AppColors.forest),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.forest,
                      ),
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_circle_outline,
                      color: AppColors.forest,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    ),
  );

  Widget _list(List<String> items, String empty) => items.isEmpty
      ? Text(empty)
      : Column(
          children: items
              .map(
                (text) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 20,
                        color: AppColors.forest,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(text)),
                    ],
                  ),
                ),
              )
              .toList(),
        );

  // Native wrapping label avoids truncating the required long CTA on small phones.
  Widget _button(String label, VoidCallback? onPressed) => ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.forest,
      foregroundColor: AppColors.ivory,
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    child: Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    ),
  );
}

// Reduce this screen's typography while preserving the user's system scaling.
class _DetailTextScaler extends TextScaler {
  const _DetailTextScaler(this.systemScaler);

  final TextScaler systemScaler;

  @override
  double scale(double fontSize) => systemScaler.scale(fontSize * .9);

  @override
  double get textScaleFactor => scale(14) / 14;
}
