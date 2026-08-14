import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../theme/theme.dart';
import '../../../widgets/widgets.dart';
import '../domain/host_mode_models.dart';
import 'host_mode_providers.dart';
import 'widgets/host_mode_scaffold.dart';

class HostAvailabilityScreen extends ConsumerStatefulWidget {
  const HostAvailabilityScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<HostAvailabilityScreen> createState() =>
      _HostAvailabilityScreenState();
}

class _HostAvailabilityScreenState
    extends ConsumerState<HostAvailabilityScreen> {
  DateTime? start;
  DateTime? end;
  final capacity = TextEditingController();
  @override
  void dispose() {
    capacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Dates & Availability')),
    backgroundColor: const Color(0xFFF7F8F5),
    body: AsyncValueView<HostExperience?>(
      value: ref.watch(hostExperienceProvider(widget.id)),
      data: (item) {
        if (item == null) {
          return const EmptyStateView(title: 'Experience not found');
        }
        start ??= item.startDate;
        end ??= item.endDate;
        if (capacity.text.isEmpty) capacity.text = '${item.capacity}';
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppCard(
              child: Column(
                children: [
                  _DateRow(
                    label: 'Start date',
                    date: start!,
                    onTap: () => _pick(true),
                  ),
                  const Divider(),
                  _DateRow(
                    label: 'End date',
                    date: end!,
                    onTap: () => _pick(false),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: capacity,
                    label: 'Guest capacity',
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Update availability locally',
              isFullWidth: true,
              onPressed: _save,
            ),
            const SizedBox(height: 8),
            Text(
              'This update is in-memory only and resets when the app restarts.',
              style: AppTypography.caption.copyWith(
                color: AppColors.disabledText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    ),
  );
  Future<void> _pick(bool first) async {
    final value = await showDatePicker(
      context: context,
      initialDate: first ? start! : end!,
      firstDate: DateTime.now(),
      lastDate: DateTime(2032),
    );
    if (value != null) {
      setState(() {
        if (first) {
          start = value;
        } else {
          end = value;
        }
      });
    }
  }

  Future<void> _save() async {
    final count = int.tryParse(capacity.text.trim());
    if (start == null ||
        end == null ||
        end!.isBefore(start!) ||
        count == null ||
        count < 1 ||
        count > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter valid dates and a capacity from 1 to 100.'),
        ),
      );
      return;
    }
    await ref
        .read(hostModeRepositoryProvider)
        .updateAvailability(widget.id, start!, end!, count);
    ref.invalidate(hostExperienceProvider(widget.id));
    ref.invalidate(hostExperiencesProvider);
    if (mounted) Navigator.pop(context);
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.date,
    required this.onTap,
  });
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    subtitle: Text(DateFormat('d MMMM y').format(date)),
    trailing: const Icon(Icons.edit_calendar_outlined),
    onTap: onTap,
  );
}
