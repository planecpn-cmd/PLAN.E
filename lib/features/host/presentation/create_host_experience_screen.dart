import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

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
  int _photoUploads = 0;
  // Groups this session's uploads under <host_id>/<_photoKey>/... in the
  // experience-photos bucket. In edit mode it is the real experience id.
  late final String _photoKey;
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
    _photoKey = widget.experienceId ?? const Uuid().v4();
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
    final messenger = ScaffoldMessenger.of(context);
    try {
      final saved = await ref
          .read(hostModeRepositoryProvider)
          .saveDraft(ref.read(hostCreateExperienceProvider));
      ref
          .read(hostCreateExperienceProvider.notifier)
          .update(ref.read(hostCreateExperienceProvider).copyWith(id: saved.id));
      ref.invalidate(hostExperiencesProvider);
      if (!mounted) return;
      setState(() => dirty = false);
      messenger.showSnackBar(const SnackBar(content: Text('Draft saved.')));
    } catch (error) {
      if (!mounted) return;
      // Surface the backend's actionable message (e.g. "This listing already
      // has changes awaiting review.") rather than a generic retry prompt.
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            error is PostgrestException
                ? error.message
                : 'Could not save the draft. Try again.',
          ),
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
        final photos = draft.photoAssets
            .where((photo) => !photo.startsWith('assets/'))
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add clear photos that accurately represent your experience. '
              'The first photo is the cover. JPG, PNG or WebP, up to 5 MB each.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 10),
            AppButton.secondary(
              label: _photoUploads > 0 ? 'Uploading…' : 'Add photos',
              icon: Icons.add_photo_alternate_outlined,
              isFullWidth: true,
              onPressed: _photoUploads > 0 ? null : _showImagePicker,
            ),
            if (_photoUploads > 0) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Uploading $_photoUploads photo${_photoUploads == 1 ? '' : 's'}…',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            if (photos.isEmpty && _photoUploads == 0)
              const AppCard(child: Text('No photos yet.')),
            ...photos.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: AppRadii.borderMd16,
                      child: _UploadedPhoto(path: entry.value, height: 150),
                    ),
                    if (entry.key == 0)
                      const Positioned(
                        left: 8,
                        top: 8,
                        child: Chip(
                          label: Text('Cover'),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: IconButton.filled(
                        tooltip: 'Remove photo',
                        onPressed: () => _removePhoto(entry.value),
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ],
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
    final List<XFile> selected;
    try {
      final picker = ImagePicker();
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
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open the image picker. Check photo and camera permissions.',
          ),
        ),
      );
      return;
    }
    if (selected.isEmpty || !mounted) return;

    final repo = ref.read(hostModeRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _photoUploads += selected.length);
    for (final file in selected) {
      try {
        final bytes = await file.readAsBytes();
        final path = await repo.uploadExperiencePhoto(
          bytes: bytes,
          fileName: file.name,
          experienceKey: _photoKey,
        );
        if (!mounted) return;
        // Re-read: an upload that finished after another edit must not clobber
        // the rest of the wizard's local state.
        final current = ref.read(hostCreateExperienceProvider);
        ref
            .read(hostCreateExperienceProvider.notifier)
            .update(
              current.copyWith(photoAssets: [...current.photoAssets, path]),
            );
        setState(() => dirty = true);
      } catch (error) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              error is ArgumentError
                  ? '${file.name}: ${error.message}'
                  : 'Could not upload ${file.name}. Try again.',
            ),
          ),
        );
      } finally {
        if (mounted) setState(() => _photoUploads -= 1);
      }
    }
  }

  Future<void> _removePhoto(String path) async {
    final repo = ref.read(hostModeRepositoryProvider);
    final current = ref.read(hostCreateExperienceProvider);
    ref
        .read(hostCreateExperienceProvider.notifier)
        .update(
          current.copyWith(
            photoAssets: current.photoAssets
                .where((candidate) => candidate != path)
                .toList(),
          ),
        );
    setState(() => dirty = true);
    // Best effort; a stray object gets swept later (see H1_HOST_WRITE_PATH.md).
    try {
      await repo.deleteExperiencePhoto(path);
    } catch (_) {}
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

class _UploadedPhoto extends ConsumerStatefulWidget {
  const _UploadedPhoto({required this.path, required this.height});
  final String path;
  final double height;
  @override
  ConsumerState<_UploadedPhoto> createState() => _UploadedPhotoState();
}

class _UploadedPhotoState extends ConsumerState<_UploadedPhoto> {
  late final Future<String> _url;
  @override
  void initState() {
    super.initState();
    _url = ref
        .read(hostModeRepositoryProvider)
        .experiencePhotoSignedUrl(widget.path);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
    future: _url,
    builder: (context, snap) {
      final url = snap.data;
      if (url == null) {
        return Container(
          height: widget.height,
          width: double.infinity,
          color: AppColors.sage,
          alignment: Alignment.center,
          child: snap.hasError
              ? const Icon(Icons.broken_image_outlined)
              : const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
        );
      }
      return Image.network(
        url,
        height: widget.height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          height: widget.height,
          color: AppColors.sage,
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_outlined),
        ),
      );
    },
  );
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
