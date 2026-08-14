import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/theme.dart';
import '../../../widgets/widgets.dart';
import '../domain/host_mode_models.dart';
import 'host_mode_providers.dart';
import 'widgets/host_mode_scaffold.dart';

class EditHostProfileScreen extends ConsumerStatefulWidget {
  const EditHostProfileScreen({super.key});
  @override
  ConsumerState<EditHostProfileScreen> createState() =>
      _EditHostProfileScreenState();
}

class _EditHostProfileScreenState extends ConsumerState<EditHostProfileScreen> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final bio = TextEditingController();
  final location = TextEditingController();
  final languages = TextEditingController();
  bool seeded = false;
  bool dirty = false;
  @override
  void dispose() {
    name.dispose();
    bio.dispose();
    location.dispose();
    languages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !dirty,
    onPopInvokedWithResult: (didPop, result) async {
      if (!didPop && await _confirmLeave() && context.mounted) context.pop();
    },
    child: Scaffold(
      appBar: AppBar(title: const Text('Edit Host Profile')),
      backgroundColor: const Color(0xFFF7F8F5),
      body: AsyncValueView<HostProfileDraft>(
        value: ref.watch(hostProfileDraftProvider),
        data: (profile) {
          if (!seeded) {
            seeded = true;
            name.text = profile.displayName;
            bio.text = profile.bio;
            location.text = profile.location;
            languages.text = profile.languages;
          }
          return Form(
            key: formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AppTextField(
                  controller: name,
                  label: 'Display name',
                  validator: (value) => (value?.trim().length ?? 0) < 2
                      ? 'Enter a valid display name'
                      : null,
                  onChanged: (_) => dirty = true,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: bio,
                  label: 'Host bio',
                  maxLines: 5,
                  validator: (value) => (value?.trim().length ?? 0) < 20
                      ? 'Add at least 20 characters'
                      : null,
                  onChanged: (_) => dirty = true,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: location,
                  label: 'Location',
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? 'Location is required'
                      : null,
                  onChanged: (_) => dirty = true,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: languages,
                  label: 'Languages',
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? 'Add at least one language'
                      : null,
                  onChanged: (_) => dirty = true,
                ),
                const SizedBox(height: 18),
                AppButton(
                  label: 'Save profile locally',
                  icon: Icons.save_outlined,
                  isFullWidth: true,
                  onPressed: _save,
                ),
                const SizedBox(height: 8),
                Text(
                  'Changes exist only for this app session.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.disabledText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
  Future<void> _save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    await ref
        .read(hostModeRepositoryProvider)
        .updateHostProfile(
          HostProfileDraft(
            displayName: name.text,
            bio: bio.text,
            location: location.text,
            languages: languages.text,
          ),
        );
    ref.invalidate(hostProfileDraftProvider);
    ref.invalidate(hostBusinessPageProvider(HostBusinessPage.publicProfile));
    ref.invalidate(hostDashboardProvider);
    if (mounted) {
      dirty = false;
      context.pop();
    }
  }

  Future<bool> _confirmLeave() async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard profile changes?'),
          content: const Text('These unsaved edits will be lost.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep editing'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Discard'),
            ),
          ],
        ),
      ) ??
      false;
}
