import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

const hostingTypes = {
  'adventure': ('Adventure', 'Treks, climbing, rafting and outdoor activities'),
  'experience': (
    'Experience',
    'Wellness, culture, workshops and local activities',
  ),
  'stay': ('Stay', 'Homestays, retreats and unique places to stay'),
  'tour_package': ('Tour / Package', 'Multi-day journeys and curated packages'),
  'community_activity': (
    'Community Activity',
    'Social and community-based activities',
  ),
  'other': ('Other', 'Another meaningful offering'),
};

const hostTypes = {
  'individual': 'Individual',
  'registered_business': 'Registered Business',
  'community_group': 'Community / Local Group',
  'hotel_homestay': 'Hotel / Homestay',
  'tour_operator': 'Tour / Adventure Operator',
  'experience_provider': 'Experience Provider',
  'other': 'Other',
};

final _hostEmailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
final _documentNumberPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9 ./-]{2,39}$');

bool isValidHostEmail(String value) =>
    value.length <= 320 && _hostEmailPattern.hasMatch(value);

bool isValidIdentityDocumentNumber(String value) =>
    _documentNumberPattern.hasMatch(value.trim());

class HostQuestionnaireScreen extends ConsumerStatefulWidget {
  final int initialStep;
  const HostQuestionnaireScreen({super.key, this.initialStep = 1});

  @override
  ConsumerState<HostQuestionnaireScreen> createState() =>
      _HostQuestionnaireScreenState();
}

class _HostQuestionnaireScreenState
    extends ConsumerState<HostQuestionnaireScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _data = {
    'min_guests': 1,
    'max_guests': 8,
    'included_items': <String>[],
    'available_days': <String>[],
    'photo_paths': <String>[],
    'terms_accepted': false,
  };
  late int _step;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep.clamp(1, 8);
    _load();
  }

  Future<void> _load() async {
    try {
      final draft = await ref
          .read(hostRepositoryProvider)
          .getQuestionnaireDraft();
      final saved = draft?['application_data'];
      if (saved is Map) _data.addAll(Map<String, dynamic>.from(saved));
      _data['email'] ??= ref
          .read(supabaseClientProvider)
          .auth
          .currentUser
          ?.email;
      if (widget.initialStep == 1 && draft?['current_step'] is int) {
        _step = (draft!['current_step'] as int).clamp(1, 8);
      }
    } catch (_) {
      _error =
          'Something went wrong while loading your application. Try again.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _validateStep() {
    if (!(_formKey.currentState?.validate() ?? true)) {
      return 'Check the highlighted fields.';
    }
    switch (_step) {
      case 1:
        if (_data['hosting_type'] == null) {
          return 'Choose what you want to host.';
        }
        break;
      case 2:
        if (_data['host_type'] == null) return 'Choose your host type.';
        if (_data['host_type'] != 'individual' &&
            (_data['organization_name']?.toString().trim().isEmpty ?? true)) {
          return 'Enter your business or organisation name.';
        }
        break;
      case 3:
        final min = _data['min_guests'] as int;
        final max = _data['max_guests'] as int;
        if (max < min) return 'Maximum guests cannot be below minimum guests.';
        break;
      case 4:
        if (_data['availability_type'] == null) {
          return 'Choose your availability.';
        }
        if (_data['availability_type'] == 'regular' &&
            (_data['available_days'] as List).isEmpty) {
          return 'Choose at least one available day.';
        }
        if ([
              'specific_dates',
              'seasonal',
            ].contains(_data['availability_type']) &&
            (_data['start_date'] == null ||
                _data['end_date'] == null ||
                _data['end_date'].toString().compareTo(
                      _data['start_date'].toString(),
                    ) <
                    0)) {
          return 'Choose a valid availability date range.';
        }
        if (_data['pricing_model'] == null) {
          return 'Choose how you normally charge.';
        }
        if (_data['pricing_model'] != 'custom_quote' &&
            ((_data['price_paisa'] as int?) ?? 0) <= 0) {
          return 'Enter a valid positive price.';
        }
        break;
      case 5:
        if (_data['cancellation_policy'] == null) {
          return 'Choose a cancellation policy.';
        }
        break;
      case 6:
        if (_data['identity_type'] == null ||
            (_data['identity_number']?.toString().trim().isEmpty ?? true) ||
            (_data['identity_front_path']?.toString().isEmpty ?? true)) {
          return 'Upload the required identity document.';
        }
        break;
      case 7:
        if ((_data['description']?.toString().trim().length ?? 0) < 20) {
          return 'Describe what you want to host in at least 20 characters.';
        }
        break;
      case 8:
        final email = _data['email']?.toString().trim() ?? '';
        final accountEmail = ref
            .read(supabaseClientProvider)
            .auth
            .currentUser
            ?.email
            ?.toLowerCase();
        if (!isValidHostEmail(email) ||
            (_data['host_type'] == 'individual' &&
                email.toLowerCase() != accountEmail)) {
          return 'Review the contact email in step 2.';
        }
        if (!isValidIdentityDocumentNumber(
          _data['identity_number']?.toString() ?? '',
        )) {
          return 'Review the document number in step 6.';
        }
        if (_data['terms_accepted'] != true) {
          return 'Accept the host terms before submitting.';
        }
        break;
    }
    return null;
  }

  Future<void> _next() async {
    FocusScope.of(context).unfocus();
    final error = _validateStep();
    if (error != null) return setState(() => _error = error);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_step == 8) {
        await ref.read(hostRepositoryProvider).submitQuestionnaire(_data);
        ref.invalidate(myHostApplicationProvider);
        if (mounted) context.go('/host/submitted');
        return;
      }
      await ref
          .read(hostRepositoryProvider)
          .saveQuestionnaireDraft(currentStep: _step + 1, data: _data);
      if (mounted) {
        setState(() => _step++);
      }
    } catch (error) {
      if (mounted) {
        final detail = error is StateError
            ? error.message.toString()
            : 'Something went wrong while saving your application. Try again.';
        setState(() => _error = detail);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _upload(String field, {bool photo = false}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
    );
    final file = result?.files.single;
    if (file?.bytes == null) return;
    setState(() => _saving = true);
    try {
      final path = await ref
          .read(hostRepositoryProvider)
          .uploadHostDocument(
            bytes: Uint8List.fromList(file!.bytes!),
            fileName: file.name,
          );
      setState(() {
        if (photo) {
          _data[field] = [...(_data[field] as List? ?? const []), path];
        } else {
          _data[field] = path;
        }
      });
    } catch (_) {
      setState(() => _error = 'Upload failed. Check the file and try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate(String field) async {
    final initial =
        DateTime.tryParse(_data[field]?.toString() ?? '') ??
        DateTime.now().add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (date != null) {
      setState(() => _data[field] = date.toIso8601String().split('T').first);
    }
  }

  void _back() {
    if (_step == 1) return context.pop();
    setState(() {
      _step--;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: _back,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Host Application'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            Semantics(
              label: 'Step $_step of 8',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step $_step of 8',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.forest,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _step / 8,
                    color: AppColors.forest,
                    backgroundColor: AppColors.sage,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _stepContent(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _error!,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                  semanticsLabel: 'Error: $_error',
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppColors.ivory,
            border: Border(top: BorderSide(color: AppColors.borderSubtle)),
          ),
          child: AppButton(
            label: _step == 8 ? 'Submit Application' : 'Continue',
            isLoading: _saving,
            isFullWidth: true,
            onPressed: _next,
          ),
        ),
      ),
    );
  }

  Widget _stepContent() {
    switch (_step) {
      case 1:
        return _Step(
          title: 'What would you like to host?',
          subtitle:
              "Choose the type of offering you'd like to bring to Plan E.",
          child: _choices(
            hostingTypes.map(
              (key, value) => MapEntry(key, '${value.$1}\n${value.$2}'),
            ),
            'hosting_type',
          ),
        );
      case 2:
        return _Step(
          title: 'Tell us about yourself',
          subtitle: 'Help us understand who will welcome Plan E travellers.',
          child: Column(
            children: [
              _choices(hostTypes, 'host_type'),
              if (_data['host_type'] != null) ...[
                const SizedBox(height: 16),
                _field(
                  'Full name / representative name',
                  'full_name',
                  required: true,
                ),
                if (_data['host_type'] != 'individual')
                  _field(
                    'Business / organisation name',
                    'organization_name',
                    required: true,
                  ),
                _field(
                  'Email',
                  'email',
                  type: TextInputType.emailAddress,
                  required: true,
                ),
                _field(
                  'Phone',
                  'phone',
                  type: TextInputType.phone,
                  required: true,
                ),
              ],
            ],
          ),
        );
      case 3:
        return _Step(
          title: 'Where and how will you host?',
          subtitle:
              'Tell us your operating area and comfortable guest capacity.',
          child: Column(
            children: [
              _field('Province', 'province', required: true),
              _field('District / City', 'district', required: true),
              _field('Area / Locality', 'locality', required: true),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final counters = [
                    _Counter(
                      label: 'Minimum guests',
                      value: _data['min_guests'] as int,
                      onChanged: (v) => setState(() => _data['min_guests'] = v),
                    ),
                    _Counter(
                      label: 'Maximum guests',
                      value: _data['max_guests'] as int,
                      onChanged: (v) => setState(() => _data['max_guests'] = v),
                    ),
                  ];
                  if (constraints.maxWidth < 600) {
                    return Column(children: counters);
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: counters.first),
                      const SizedBox(width: 12),
                      Expanded(child: counters.last),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      case 4:
        return _Step(
          title: 'When can guests join?',
          subtitle: 'Set your usual availability and pricing approach.',
          child: Column(
            children: [
              _label('Availability'),
              _choices(const {
                'regular': 'Available regularly',
                'specific_dates': 'Specific dates',
                'seasonal': 'Seasonal',
                'flexible': 'On request / flexible',
              }, 'availability_type'),
              if (_data['availability_type'] == 'regular')
                Wrap(
                  spacing: 8,
                  children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                      .map(
                        (day) => FilterChip(
                          label: Text(day),
                          selected: (_data['available_days'] as List).contains(
                            day,
                          ),
                          onSelected: (selected) => setState(() {
                            final days = _data['available_days'] as List;
                            selected ? days.add(day) : days.remove(day);
                          }),
                        ),
                      )
                      .toList(),
                ),
              if (_data['availability_type'] == 'specific_dates' ||
                  _data['availability_type'] == 'seasonal')
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickDate('start_date'),
                        child: Text(
                          _data['start_date']?.toString() ?? 'Start date',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickDate('end_date'),
                        child: Text(
                          _data['end_date']?.toString() ?? 'End date',
                        ),
                      ),
                    ),
                  ],
                ),
              if (_data['availability_type'] == 'flexible')
                _field('Availability note', 'availability_note'),
              const SizedBox(height: 16),
              _label('How do you normally charge?'),
              _choices(const {
                'per_person': 'Per person',
                'per_group': 'Per group',
                'starting_price': 'Starting price',
                'custom_quote': 'Custom quote',
              }, 'pricing_model'),
              if (_data['pricing_model'] != null &&
                  _data['pricing_model'] != 'custom_quote')
                _field(
                  'Price (NPR)',
                  'price_npr',
                  type: TextInputType.number,
                  required: true,
                  onChanged: (v) =>
                      _data['price_paisa'] = (int.tryParse(v) ?? 0) * 100,
                ),
            ],
          ),
        );
      case 5:
        return _Step(
          title: 'What will guests receive?',
          subtitle: 'Choose typical inclusions and a cancellation approach.',
          child: Column(
            children: [
              ...[
                'Guide',
                'Meals',
                'Transportation',
                'Accommodation',
                'Equipment',
                'Entry fees / permits',
                'Pickup / drop-off',
                'Other',
              ].map(
                (item) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item),
                  value: (_data['included_items'] as List).contains(item),
                  onChanged: (v) => setState(() {
                    final list = _data['included_items'] as List;
                    v == true ? list.add(item) : list.remove(item);
                  }),
                ),
              ),
              _field('Optional inclusion details', 'inclusion_details'),
              _label('Cancellation policy'),
              _choices(const {
                'flexible': 'Flexible — adaptable for guests',
                'moderate': 'Moderate — balanced commitment',
                'strict': 'Strict — firm planning commitment',
                'custom': 'Custom — explain your policy',
              }, 'cancellation_policy'),
              if (_data['cancellation_policy'] == 'custom')
                _field(
                  'Custom policy details',
                  'cancellation_details',
                  required: true,
                ),
            ],
          ),
        );
      case 6:
        final needsSafety = [
          'adventure',
          'tour_package',
        ].contains(_data['hosting_type']);
        final needsBusiness = _data['host_type'] != 'individual';
        return _Step(
          title: 'Safety & verification',
          subtitle: 'We verify hosts to help keep Plan E safe and trustworthy.',
          child: Column(
            children: [
              _label('Identity type'),
              _choices(const {
                'citizenship': 'Citizenship Card',
                'passport': 'Passport',
                'driving_licence': 'Driving Licence',
                'other': 'Other approved ID',
              }, 'identity_type'),
              _field('Document number', 'identity_number', required: true),
              _Upload(
                label: 'Front of identity document',
                uploaded: _data['identity_front_path'] != null,
                busy: _saving,
                onTap: () => _upload('identity_front_path'),
              ),
              _Upload(
                label: 'Back of identity document (if applicable)',
                uploaded: _data['identity_back_path'] != null,
                busy: _saving,
                onTap: () => _upload('identity_back_path'),
              ),
              if (needsBusiness)
                _Upload(
                  label: 'Business registration or operating licence',
                  uploaded:
                      (_data['business_document_paths'] as List?)?.isNotEmpty ==
                      true,
                  busy: _saving,
                  onTap: () => _upload('business_document_paths', photo: true),
                ),
              if (needsSafety)
                _Upload(
                  label: 'Guide, safety or tourism certification',
                  uploaded:
                      (_data['safety_document_paths'] as List?)?.isNotEmpty ==
                      true,
                  busy: _saving,
                  onTap: () => _upload('safety_document_paths', photo: true),
                ),
            ],
          ),
        );
      case 7:
        return _Step(
          title: 'Show us what you offer',
          subtitle:
              'Add clear, authentic photos that help us understand your offering.',
          child: Column(
            children: [
              _field(
                'Tell us about what you want to host',
                'description',
                required: true,
                lines: 5,
              ),
              _Upload(
                label: 'Host / representative photo',
                uploaded: _data['host_photo_path'] != null,
                busy: _saving,
                onTap: () => _upload('host_photo_path'),
              ),
              _Upload(
                label: 'Add location or experience photo',
                uploaded: (_data['photo_paths'] as List).isNotEmpty,
                busy: _saving,
                onTap: () => _upload('photo_paths', photo: true),
              ),
              if (_data['host_type'] != 'individual')
                _Upload(
                  label: 'Business logo (optional)',
                  uploaded: _data['business_logo_path'] != null,
                  busy: _saving,
                  onTap: () => _upload('business_logo_path'),
                ),
            ],
          ),
        );
      default:
        return _Step(
          title: 'Review your application',
          subtitle: 'Check your answers before sending them to Plan E.',
          child: Column(
            children: [
              ...[
                (
                  'Host',
                  '${_data['full_name'] ?? ''}\n${hostTypes[_data['host_type']] ?? ''}',
                ),
                ('Hosting type', hostingTypes[_data['hosting_type']]?.$1 ?? ''),
                (
                  'Location',
                  '${_data['locality'] ?? ''}, ${_data['district'] ?? ''}, ${_data['province'] ?? ''}',
                ),
                (
                  'Capacity',
                  '${_data['min_guests']}–${_data['max_guests']} guests',
                ),
                ('Availability', '${_data['availability_type'] ?? ''}'),
                (
                  'Pricing',
                  _data['pricing_model'] == 'custom_quote'
                      ? 'Custom quote'
                      : 'NPR ${((_data['price_paisa'] ?? 0) as int) ~/ 100}',
                ),
                ('Cancellation', '${_data['cancellation_policy'] ?? ''}'),
                ('Document number', '${_data['identity_number'] ?? ''}'),
                (
                  'Verification',
                  _data['identity_front_path'] == null
                      ? 'Required'
                      : 'Document uploaded',
                ),
                ('Photos', '${(_data['photo_paths'] as List).length} added'),
              ].map(
                (item) => PlanECard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.$1,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.disabledText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(item.$2, style: AppTypography.bodyLarge),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _ReviewUploads(data: _data),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _data['terms_accepted'] == true,
                onChanged: (v) =>
                    setState(() => _data['terms_accepted'] = v == true),
                title: const Text(
                  "I agree to Plan E's Host Terms, Policies and Terms & Conditions.",
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _choices(Map<String, String> options, String field) => Column(
    children: options.entries
        .map(
          (option) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PlanECard(
              onTap: () => setState(() => _data[field] = option.key),
              backgroundColor: _data[field] == option.key
                  ? AppColors.sage
                  : AppColors.white,
              borderColor: _data[field] == option.key
                  ? AppColors.forest
                  : AppColors.borderSubtle,
              child: Row(
                children: [
                  Expanded(
                    child: Text(option.value, style: AppTypography.bodyLarge),
                  ),
                  Icon(
                    _data[field] == option.key
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: AppColors.forest,
                  ),
                ],
              ),
            ),
          ),
        )
        .toList(),
  );

  Widget _field(
    String label,
    String field, {
    bool required = false,
    TextInputType? type,
    int lines = 1,
    ValueChanged<String>? onChanged,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      initialValue: field == 'price_npr' && _data['price_paisa'] != null
          ? '${(_data['price_paisa'] as int) ~/ 100}'
          : _data[field]?.toString(),
      keyboardType: type,
      maxLines: lines,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        helperText: field == 'identity_number'
            ? '3–40 letters or numbers; spaces, /, . and - are allowed.'
            : field == 'email'
            ? 'Use your account email or, for an organisation, its business email.'
            : null,
      ),
      onChanged: onChanged ?? (v) => _data[field] = v,
      validator: (value) {
        final text = value?.trim() ?? '';
        if (required && text.isEmpty) return '$label is required.';
        if (field == 'identity_number' &&
            text.isNotEmpty &&
            !isValidIdentityDocumentNumber(text)) {
          return 'Enter a valid document number.';
        }
        if (field == 'email' && text.isNotEmpty) {
          if (!isValidHostEmail(text)) return 'Enter a valid email address.';
          final accountEmail = ref
              .read(supabaseClientProvider)
              .auth
              .currentUser
              ?.email
              ?.toLowerCase();
          if (_data['host_type'] == 'individual' &&
              text.toLowerCase() != accountEmail) {
            return 'Use the email registered to your Plan E account.';
          }
        }
        return null;
      },
    ),
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
  );
}

class _Step extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const _Step({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: AppTypography.displayMedium.copyWith(
          fontFamily: 'serif',
          color: AppColors.forest,
        ),
      ),
      const SizedBox(height: 8),
      Text(subtitle, style: AppTypography.bodyLarge),
      const SizedBox(height: 24),
      child,
    ],
  );
}

class _ReviewUploads extends StatelessWidget {
  const _ReviewUploads({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final files = <(String, String)>[];
    void add(String label, dynamic value) {
      if (value is String && value.isNotEmpty) files.add((label, value));
      if (value is List) {
        for (final path in value.whereType<String>()) {
          if (path.isNotEmpty) files.add((label, path));
        }
      }
    }

    add('Identity document — front', data['identity_front_path']);
    add('Identity document — back', data['identity_back_path']);
    add('Business document', data['business_document_paths']);
    add('Safety certificate', data['safety_document_paths']);
    add('Host photo', data['host_photo_path']);
    add('Offering photo', data['photo_paths']);
    add('Business logo', data['business_logo_path']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          'Pictures & documents',
          style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ...files.map((file) => _ReviewDocument(label: file.$1, path: file.$2)),
      ],
    );
  }
}

class _ReviewDocument extends ConsumerStatefulWidget {
  const _ReviewDocument({required this.label, required this.path});

  final String label;
  final String path;

  @override
  ConsumerState<_ReviewDocument> createState() => _ReviewDocumentState();
}

class _ReviewDocumentState extends ConsumerState<_ReviewDocument> {
  late Future<String> _signedUrl;

  bool get _isPdf => widget.path.toLowerCase().endsWith('.pdf');

  @override
  void initState() {
    super.initState();
    _signedUrl = ref
        .read(hostRepositoryProvider)
        .createHostDocumentSignedUrl(widget.path);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: FutureBuilder<String>(
      future: _signedUrl,
      builder: (context, snapshot) {
        final url = snapshot.data;
        return PlanECard(
          onTap: url == null
              ? null
              : () => launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (url != null && !_isPdf)
                ClipRRect(
                  borderRadius: AppRadii.borderSm8,
                  child: Image.network(
                    url,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox(
                      width: 72,
                      height: 72,
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  ),
                )
              else
                SizedBox(
                  width: 72,
                  height: 72,
                  child: Center(
                    child: snapshot.connectionState != ConnectionState.done
                        ? const CircularProgressIndicator(strokeWidth: 2)
                        : Icon(
                            _isPdf
                                ? Icons.picture_as_pdf_outlined
                                : Icons.insert_drive_file_outlined,
                            color: AppColors.forest,
                          ),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      url == null ? 'Loading preview…' : 'Tap to view',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              if (url != null) const Icon(Icons.open_in_new, size: 20),
            ],
          ),
        );
      },
    ),
  );
}

class _Counter extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  const _Counter({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: PlanECard(
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTypography.bodyLarge)),
          IconButton(
            tooltip: 'Decrease $label',
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove),
          ),
          Semantics(
            label: '$label: $value',
            child: SizedBox(
              width: 36,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: AppTypography.bodyLarge,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Increase $label',
            onPressed: value < 100 ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    ),
  );
}

class _Upload extends StatelessWidget {
  final String label;
  final bool uploaded;
  final bool busy;
  final VoidCallback onTap;
  const _Upload({
    required this.label,
    required this.uploaded,
    required this.busy,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: PlanECard(
      onTap: busy ? null : onTap,
      child: Row(
        children: [
          Icon(
            uploaded ? Icons.check_circle : Icons.upload_file_outlined,
            color: uploaded ? AppColors.success : AppColors.forest,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  uploaded ? 'Document uploaded' : 'Choose JPG, PNG or PDF',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          Text(
            uploaded ? 'Replace' : 'Upload',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.forest,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}
