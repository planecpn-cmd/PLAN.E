import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../theme/theme.dart';
import '../../../widgets/widgets.dart';
import '../domain/host_experience_validator.dart';
import '../domain/host_mode_models.dart';
import 'host_mode_providers.dart';

class CreateHostExperienceScreen extends ConsumerStatefulWidget {
  const CreateHostExperienceScreen({super.key, this.experienceId});
  final String? experienceId;
  @override
  ConsumerState<CreateHostExperienceScreen> createState() =>
      _CreateHostExperienceScreenState();
}

class _CreateHostExperienceScreenState
    extends ConsumerState<CreateHostExperienceScreen> {
  int step = 0;
  bool dirty = false;
  late final Map<String, TextEditingController> controllers;
  static const titles = [
    'Basic Information',
    'Photos',
    'Trip Details',
    'Itinerary',
    'What’s Included',
    'What to Bring',
    'Dates & Availability',
    'Pricing',
    'Meeting Point',
  ];

  @override
  void initState() {
    super.initState();
    final draft = ref.read(hostCreateExperienceProvider);
    controllers = {
      'title': TextEditingController(text: draft.title),
      'location': TextEditingController(text: draft.location),
      'description': TextEditingController(text: draft.description),
      'tripDetails': TextEditingController(text: draft.tripDetails),
      'capacity': TextEditingController(text: draft.capacity?.toString() ?? ''),
      'price': TextEditingController(text: draft.priceNpr?.toString() ?? ''),
      'meetingPoint': TextEditingController(text: draft.meetingPoint),
    };
    if (widget.experienceId != null && draft.id != widget.experienceId) {
      Future.microtask(_seedEdit);
    }
  }

  Future<void> _seedEdit() async {
    final item = await ref
        .read(hostModeRepositoryProvider)
        .getExperience(widget.experienceId!);
    if (item == null || !mounted) return;
    ref.read(hostCreateExperienceProvider.notifier).seed(item);
    final seeded = ref.read(hostCreateExperienceProvider);
    controllers['title']!.text = seeded.title;
    controllers['location']!.text = seeded.location;
    controllers['description']!.text = seeded.description;
    controllers['capacity']!.text = seeded.capacity?.toString() ?? '';
    controllers['price']!.text = seeded.priceNpr?.toString() ?? '';
    setState(() {});
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _commit() {
    final current = ref.read(hostCreateExperienceProvider);
    ref
        .read(hostCreateExperienceProvider.notifier)
        .update(
          current.copyWith(
            title: controllers['title']!.text.trim(),
            location: controllers['location']!.text.trim(),
            description: controllers['description']!.text.trim(),
            tripDetails: controllers['tripDetails']!.text.trim(),
            itinerary: current.itinerary,
            included: current.included,
            bring: current.bring,
            capacity: int.tryParse(controllers['capacity']!.text.trim()),
            priceNpr: int.tryParse(controllers['price']!.text.trim()),
            meetingPoint: controllers['meetingPoint']!.text.trim(),
          ),
        );
  }

  bool _validateStep() {
    _commit();
    final draft = ref.read(hostCreateExperienceProvider);
    String? error;
    switch (step) {
      case 0:
        error =
            HostExperienceValidator.title(draft.title) ??
            HostExperienceValidator.location(draft.location) ??
            HostExperienceValidator.description(draft.description);
        break;
      case 1:
        if (draft.photoAssets.isEmpty) error = 'Add at least one photo';
        break;
      case 2:
        if (draft.tripDetails.length < 20) {
          error = 'Add at least 20 characters of trip details';
        }
        break;
      case 3:
        if (draft.itinerary.isEmpty) error = 'Add at least one itinerary item';
        break;
      case 4:
        if (draft.included.isEmpty) error = 'Add at least one included item';
        break;
      case 5:
        if (draft.bring.isEmpty) {
          error = 'Add at least one item guests should bring';
        }
        break;
      case 6:
        if (draft.startDate == null || draft.endDate == null) {
          error = 'Select both departure dates';
        } else if (draft.endDate!.isBefore(draft.startDate!)) {
          error = 'End date must be after start date';
        } else if (draft.capacity == null ||
            draft.capacity! < 1 ||
            draft.capacity! > 100) {
          error = 'Capacity must be between 1 and 100';
        }
        break;
      case 7:
        error = HostExperienceValidator.positiveInteger(
          controllers['price']!.text,
          field: 'price',
          max: 10000000,
        );
        break;
      case 8:
        if (draft.meetingPoint.length < 5) error = 'Add a clear meeting point';
        break;
    }
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
    return error == null;
  }

  Future<void> _saveDraft() async {
    _commit();
    final saved = await ref
        .read(hostModeRepositoryProvider)
        .saveDraft(ref.read(hostCreateExperienceProvider));
    ref
        .read(hostCreateExperienceProvider.notifier)
        .update(ref.read(hostCreateExperienceProvider).copyWith(id: saved.id));
    ref.invalidate(hostExperiencesProvider);
    if (mounted) {
      setState(() => dirty = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Draft saved locally for this app session.'),
        ),
      );
    }
  }

  Future<bool> _confirmExit() async {
    if (!dirty) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave this draft?'),
        content: const Text(
          'Unsaved changes will be lost. You can save a local draft first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (result == true) {
      ref.read(hostCreateExperienceProvider.notifier).reset();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(hostCreateExperienceProvider);
    return PopScope(
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && await _confirmExit() && context.mounted) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.experienceId == null
                ? 'Create Experience'
                : 'Edit Experience',
          ),
          actions: [
            TextButton(onPressed: _saveDraft, child: const Text('Save draft')),
          ],
        ),
        backgroundColor: const Color(0xFFF7F8F5),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
          children: [
            Row(
              children: [
                Text(
                  'Step ${step + 1} of 10',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.forest,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text('${((step + 1) * 10)}%', style: AppTypography.caption),
              ],
            ),
            const SizedBox(height: 7),
            ClipRRect(
              borderRadius: AppRadii.borderPill,
              child: LinearProgressIndicator(
                value: (step + 1) / 10,
                minHeight: 7,
                backgroundColor: AppColors.sage,
                color: AppColors.forest,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              titles[step],
              style: AppTypography.headingLarge.copyWith(fontFamily: 'serif'),
            ),
            const SizedBox(height: 14),
            _stepBody(draft),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(top: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: AppButton.secondary(
                    label: step == 0 ? 'Cancel' : 'Back',
                    onPressed: () async {
                      if (step > 0) {
                        setState(() => step--);
                      } else if (await _confirmExit() && context.mounted) {
                        context.pop();
                      }
                    },
                    isFullWidth: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    label: step == 8 ? 'Preview' : 'Next',
                    onPressed: () {
                      if (!_validateStep()) return;
                      if (step == 8) {
                        context.push('/host/experiences/create/preview');
                      } else {
                        setState(() => step++);
                      }
                    },
                    isFullWidth: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepBody(HostExperienceDraft draft) {
    void changed(String _) {
      dirty = true;
      _commit();
    }

    switch (step) {
      case 0:
        return Column(
          children: [
            AppTextField(
              controller: controllers['title'],
              label: 'Experience title',
              hint: 'e.g. Mardi Himal Trek',
              onChanged: changed,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: controllers['location'],
              label: 'Location',
              hint: 'District, Nepal',
              onChanged: changed,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: controllers['description'],
              label: 'Description',
              hint: 'What makes this experience special?',
              maxLines: 5,
              onChanged: changed,
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose clear photos that accurately represent your experience.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 10),
            AppButton.secondary(
              label: 'Open image picker',
              icon: Icons.add_photo_alternate_outlined,
              isFullWidth: true,
              onPressed: _showImagePicker,
            ),
            const SizedBox(height: 12),
            ...draft.photoAssets
                .where((photo) => !photo.startsWith('assets/'))
                .map(
                  (photo) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: AppRadii.borderMd16,
                          child: Image.file(
                            File(photo),
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  height: 150,
                                  color: AppColors.sage,
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.broken_image_outlined,
                                  ),
                                ),
                          ),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: IconButton.filled(
                            tooltip: 'Remove photo',
                            onPressed: () => _removePhoto(photo),
                            icon: const Icon(Icons.close),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ...[
              'assets/images/welcome_hero.jpg',
              'assets/images/herosection.jpg',
              'assets/images/explore_header_mountains.png',
            ].indexed.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Semantics(
                  button: true,
                  selected: draft.photoAssets.contains(entry.$2),
                  label: 'Experience photo ${entry.$1 + 1}',
                  child: InkWell(
                    onTap: () {
                      final photos = [...draft.photoAssets];
                      photos.contains(entry.$2)
                          ? photos.remove(entry.$2)
                          : photos.add(entry.$2);
                      ref
                          .read(hostCreateExperienceProvider.notifier)
                          .update(draft.copyWith(photoAssets: photos));
                      setState(() => dirty = true);
                    },
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: AppRadii.borderMd16,
                          child: Image.asset(
                            entry.$2,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: 10,
                          top: 10,
                          child: CircleAvatar(
                            backgroundColor:
                                draft.photoAssets.contains(entry.$2)
                                ? AppColors.forest
                                : AppColors.white,
                            child: Icon(
                              draft.photoAssets.contains(entry.$2)
                                  ? Icons.check
                                  : Icons.add,
                              color: draft.photoAssets.contains(entry.$2)
                                  ? Colors.white
                                  : AppColors.forest,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      case 2:
        return AppTextField(
          controller: controllers['tripDetails'],
          label: 'Trip details',
          hint:
              'Difficulty, duration, transport, accommodation and hosting style',
          maxLines: 7,
          onChanged: changed,
        );
      case 3:
        return _StructuredListEditor(
          title: 'Itinerary days',
          items: draft.itinerary,
          addLabel: 'Add itinerary day',
          onAdd: () => _addListItem(
            'Itinerary day',
            draft.itinerary,
            (items) => draft.copyWith(itinerary: items),
          ),
          onRemove: (index) => _removeListItem(
            draft.itinerary,
            index,
            (items) => draft.copyWith(itinerary: items),
          ),
        );
      case 4:
        return _StructuredListEditor(
          title: 'Included items',
          items: draft.included,
          addLabel: 'Add included item',
          onAdd: () => _addListItem(
            'Included item',
            draft.included,
            (items) => draft.copyWith(included: items),
          ),
          onRemove: (index) => _removeListItem(
            draft.included,
            index,
            (items) => draft.copyWith(included: items),
          ),
        );
      case 5:
        return _StructuredListEditor(
          title: 'Equipment and essentials',
          items: draft.bring,
          addLabel: 'Add equipment item',
          onAdd: () => _addListItem(
            'Equipment item',
            draft.bring,
            (items) => draft.copyWith(bring: items),
          ),
          onRemove: (index) => _removeListItem(
            draft.bring,
            index,
            (items) => draft.copyWith(bring: items),
          ),
        );
      case 6:
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _DateTile(
                    label: 'Start date',
                    value: draft.startDate,
                    onTap: () => _pickDate(true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DateTile(
                    label: 'End date',
                    value: draft.endDate,
                    onTap: () => _pickDate(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: controllers['capacity'],
              label: 'Guest capacity',
              keyboardType: TextInputType.number,
              onChanged: changed,
            ),
          ],
        );
      case 7:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              controller: controllers['price'],
              label: 'Price per guest (NPR)',
              keyboardType: TextInputType.number,
              onChanged: changed,
            ),
            const SizedBox(height: 10),
            Text(
              'Pricing is validated here for feedback. A future backend must authoritatively validate and calculate all payable amounts.',
              style: AppTypography.caption.copyWith(
                color: AppColors.disabledText,
              ),
            ),
          ],
        );
      default:
        return Column(
          children: [
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.sage,
                borderRadius: AppRadii.borderMd16,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.map_outlined,
                    size: 48,
                    color: AppColors.forest,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    draft.meetingPoint.isEmpty
                        ? 'Meeting-point map preview'
                        : draft.meetingPoint,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _chooseMeetingPin,
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: const Text('Choose map pin'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: controllers['meetingPoint'],
              label: 'Meeting instructions',
              hint: 'Exact landmark and arrival instructions',
              maxLines: 4,
              onChanged: changed,
            ),
          ],
        );
    }
  }

  Future<void> _pickDate(bool start) async {
    final draft = ref.read(hostCreateExperienceProvider);
    final result = await showDatePicker(
      context: context,
      initialDate:
          (start ? draft.startDate : draft.endDate) ?? DateTime(2027, 1, 1),
      firstDate: DateTime.now(),
      lastDate: DateTime(2032),
    );
    if (result == null) return;
    ref
        .read(hostCreateExperienceProvider.notifier)
        .update(
          start
              ? draft.copyWith(startDate: result)
              : draft.copyWith(endDate: result),
        );
    setState(() => dirty = true);
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from library'),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhotos(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhotos(ImageSource.camera);
                },
              ),
              const Text(
                'Choose photos that accurately represent your experience.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPhotos(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final List<XFile> selected;
      if (source == ImageSource.gallery) {
        selected = await picker.pickMultiImage(
          maxWidth: 2000,
          imageQuality: 88,
          requestFullMetadata: false,
        );
      } else {
        final photo = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 2000,
          imageQuality: 88,
          requestFullMetadata: false,
        );
        selected = photo == null ? const [] : [photo];
      }
      if (selected.isEmpty || !mounted) return;

      final draft = ref.read(hostCreateExperienceProvider);
      final photos = [...draft.photoAssets];
      for (final photo in selected) {
        if (!photos.contains(photo.path)) photos.add(photo.path);
      }
      ref
          .read(hostCreateExperienceProvider.notifier)
          .update(draft.copyWith(photoAssets: photos));
      setState(() => dirty = true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open the image picker. Check photo and camera permissions.',
          ),
        ),
      );
    }
  }

  void _removePhoto(String photo) {
    final draft = ref.read(hostCreateExperienceProvider);
    ref
        .read(hostCreateExperienceProvider.notifier)
        .update(
          draft.copyWith(
            photoAssets: draft.photoAssets
                .where((candidate) => candidate != photo)
                .toList(),
          ),
        );
    setState(() => dirty = true);
  }

  Future<void> _addListItem(
    String label,
    List<String> existing,
    HostExperienceDraft Function(List<String>) update,
  ) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add $label'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 160,
          decoration: InputDecoration(hintText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.isEmpty) return;
    ref
        .read(hostCreateExperienceProvider.notifier)
        .update(update([...existing, value]));
    setState(() => dirty = true);
  }

  void _removeListItem(
    List<String> existing,
    int index,
    HostExperienceDraft Function(List<String>) update,
  ) {
    final items = [...existing]..removeAt(index);
    ref.read(hostCreateExperienceProvider.notifier).update(update(items));
    setState(() => dirty = true);
  }

  void _chooseMeetingPin() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined, size: 54, color: AppColors.forest),
              const SizedBox(height: 10),
              const Text('Map pin preview', style: AppTypography.headingMedium),
              const SizedBox(height: 8),
              const Text(
                'Interactive map selection is not available yet. The current meeting point is Lakeside, Pokhara.',
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Use Lakeside meeting point',
                isFullWidth: true,
                onPressed: () {
                  controllers['meetingPoint']!.text =
                      'Lakeside Bus Stop, Pokhara · beside the tourism office';
                  _commit();
                  setState(() => dirty = true);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StructuredListEditor extends StatelessWidget {
  const _StructuredListEditor({
    required this.title,
    required this.items,
    required this.addLabel,
    required this.onAdd,
    required this.onRemove,
  });

  final String title;
  final List<String> items;
  final String addLabel;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          const AppCard(child: Text('No items added yet.'))
        else
          ...items.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: AppColors.sage,
                      child: Text(
                        '${entry.key + 1}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.forest,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(entry.value)),
                    IconButton(
                      onPressed: () => onRemove(entry.key),
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: AppColors.error,
                      ),
                      tooltip: 'Remove item',
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 6),
        AppButton.secondary(
          label: addLabel,
          icon: Icons.add,
          isFullWidth: true,
          onPressed: onAdd,
        ),
      ],
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: AppRadii.borderSm8,
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_month_outlined),
      ),
      child: Text(
        value == null ? 'Select' : DateFormat('d MMM y').format(value!),
        style: TextStyle(
          color: value == null ? AppColors.disabledText : AppColors.ink,
        ),
      ),
    ),
  );
}
